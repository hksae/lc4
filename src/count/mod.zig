const std = @import("std");
const lang = @import("../lang/mod.zig");
const lines_mod = @import("lines.zig");
const binary = @import("binary.zig");
const FileEntry = @import("../scan/mod.zig").FileEntry;

pub const FileResult = struct {
    path: []const u8,
    lang_ptr: *const lang.Language,
    line_count: lines_mod.LineCount = .{},
    is_binary: bool = false,
};

pub const AggregateResult = struct {
    stats: []lang.LanguageStat,
    total: lang.LanguageStat,
};

pub fn countAll(allocator: std.mem.Allocator, io: std.Io, entries: []const FileEntry, extensions_only: bool) ![]FileResult {
    var results = try allocator.alloc(FileResult, entries.len);
    for (entries, 0..) |entry, i| {
        results[i] = .{
            .path = entry.path,
            .lang_ptr = entry.lang_ptr,
        };
    }

    var group: std.Io.Group = .init;
    for (entries, 0..) |entry, i| {
        try group.concurrent(io, countSingle, .{ io, entry, &results[i], extensions_only });
    }
    try group.await(io);

    return results;
}

fn countSingle(io: std.Io, entry: FileEntry, result: *FileResult, extensions_only: bool) std.Io.Cancelable!void {
    const content = readFile(io, entry.path) orelse return;
    defer std.heap.smp_allocator.free(content);

    if (!extensions_only) {
        result.is_binary = binary.isBinary(content);
        if (result.is_binary) return;
    }

    result.line_count = lines_mod.countLines(content, entry.lang_ptr);
}

pub fn readFile(io: std.Io, path: []const u8) ?[]u8 {
    const cwd = std.Io.Dir.cwd();
    const file = cwd.openFile(io, path, .{}) catch return null;
    defer file.close(io);
    const stats = file.stat(io) catch return null;
    const size: usize = @intCast(stats.size);
    if (size == 0) {
        return std.heap.smp_allocator.dupe(u8, "") catch null;
    }
    if (size > 100 * 1024 * 1024) return null;
    const buf = std.heap.smp_allocator.alloc(u8, size) catch return null;
    var total: usize = 0;
    while (total < size) {
        const remaining = buf[total..];
        const n = file.readPositional(io, &.{remaining}, total) catch {
            std.heap.smp_allocator.free(buf);
            return null;
        };
        if (n == 0) {
            std.heap.smp_allocator.free(buf);
            return null;
        }
        total += n;
    }
    return buf;
}

const AtomicLangCounters = struct {
    files: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    lines: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    blanks: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    comments: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    code: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    color: []const u8,
};

pub const AtomicCounters = struct {
    map: std.StringHashMap(AtomicLangCounters),

    pub fn init(allocator: std.mem.Allocator) AtomicCounters {
        var map = std.StringHashMap(AtomicLangCounters).init(allocator);
        for (&lang.table) |*entry| {
            map.put(entry.lang.name, .{ .color = entry.lang.color }) catch {};
        }
        return .{ .map = map };
    }

    pub fn deinit(self: *AtomicCounters) void {
        self.map.deinit();
    }

    pub fn countFile(self: *AtomicCounters, content: []const u8, language: *const lang.Language, is_binary_file: bool) void {
        if (is_binary_file) return;
        if (self.map.getPtr(language.name)) |entry| {
            _ = entry.files.fetchAdd(1, .monotonic);
            const lc = lines_mod.countLines(content, language);
            _ = entry.lines.fetchAdd(lc.lines, .monotonic);
            _ = entry.blanks.fetchAdd(lc.blanks, .monotonic);
            _ = entry.comments.fetchAdd(lc.comments, .monotonic);
            _ = entry.code.fetchAdd(lc.code, .monotonic);
        }
    }

    pub fn aggregate(self: *AtomicCounters, allocator: std.mem.Allocator, sort_by: []const u8) !AggregateResult {
        var stats = std.ArrayList(lang.LanguageStat).empty;
        var total = lang.LanguageStat{ .name = "Total", .color = "\x1b[1m" };

        var it = self.map.iterator();
        while (it.next()) |entry| {
            const files = entry.value_ptr.files.load(.monotonic);
            if (files == 0) continue;
            try stats.append(allocator, .{
                .name = entry.key_ptr.*,
                .color = entry.value_ptr.color,
                .files = files,
                .lines = entry.value_ptr.lines.load(.monotonic),
                .blanks = entry.value_ptr.blanks.load(.monotonic),
                .comments = entry.value_ptr.comments.load(.monotonic),
                .code = entry.value_ptr.code.load(.monotonic),
            });
            total.files += files;
            total.lines += entry.value_ptr.lines.load(.monotonic);
            total.blanks += entry.value_ptr.blanks.load(.monotonic);
            total.comments += entry.value_ptr.comments.load(.monotonic);
            total.code += entry.value_ptr.code.load(.monotonic);
        }

        const result = try stats.toOwnedSlice(allocator);
        std.mem.sort(lang.LanguageStat, result, sort_by, struct {
            fn cmp(ctx: []const u8, a: lang.LanguageStat, b: lang.LanguageStat) bool {
                if (std.mem.eql(u8, ctx, "files")) return a.files > b.files;
                if (std.mem.eql(u8, ctx, "code")) return a.code > b.code;
                if (std.mem.eql(u8, ctx, "name")) return std.mem.lessThan(u8, a.name, b.name);
                return a.lines > b.lines;
            }
        }.cmp);

        return .{ .stats = result, .total = total };
    }
};

pub fn aggregate(allocator: std.mem.Allocator, results: []const FileResult, sort_by: []const u8) !AggregateResult {
    var map: std.StringHashMap(lang.LanguageStat) = .init(allocator);
    defer map.deinit();
    var total = lang.LanguageStat{ .name = "Total", .color = "\x1b[1m" };

    for (results) |r| {
        if (r.is_binary) continue;
        const gop = try map.getOrPut(r.lang_ptr.name);
        if (!gop.found_existing) {
            gop.value_ptr.* = .{
                .name = r.lang_ptr.name,
                .color = r.lang_ptr.color,
            };
        }
        gop.value_ptr.*.files += 1;
        gop.value_ptr.*.lines += r.line_count.lines;
        gop.value_ptr.*.blanks += r.line_count.blanks;
        gop.value_ptr.*.comments += r.line_count.comments;
        gop.value_ptr.*.code += r.line_count.code;

        total.files += 1;
        total.lines += r.line_count.lines;
        total.blanks += r.line_count.blanks;
        total.comments += r.line_count.comments;
        total.code += r.line_count.code;
    }

    var stats = try allocator.alloc(lang.LanguageStat, map.count());
    var i: usize = 0;
    var it = map.valueIterator();
    while (it.next()) |val| : (i += 1) {
        stats[i] = val.*;
    }

    std.mem.sort(lang.LanguageStat, stats, sort_by, struct {
        fn cmp(ctx: []const u8, a: lang.LanguageStat, b: lang.LanguageStat) bool {
            if (std.mem.eql(u8, ctx, "files")) return a.files > b.files;
            if (std.mem.eql(u8, ctx, "code")) return a.code > b.code;
            if (std.mem.eql(u8, ctx, "name")) return std.mem.lessThan(u8, a.name, b.name);
            return a.lines > b.lines;
        }
    }.cmp);

    return .{ .stats = stats, .total = total };
}
