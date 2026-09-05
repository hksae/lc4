const std = @import("std");
const lang = @import("../lang/mod.zig");
const lines_mod = @import("lines.zig");
const binary = @import("binary.zig");
const FileEntry = @import("../scan/mod.zig").FileEntry;

pub const FileResult = struct {
    path: []const u8,
    lang_ptr: *const lang.Language = &lang.unknown,
    line_count: lines_mod.LineCount = .{},
    is_binary: bool = false,
};

pub const AggregateResult = struct {
    stats: []lang.LanguageStat,
    total: lang.LanguageStat,
};

const batch_size = 64;

pub fn countAll(allocator: std.mem.Allocator, io: std.Io, entries: []const FileEntry, extensions_only: bool) ![]FileResult {
    var results = try allocator.alloc(FileResult, entries.len);
    for (entries, 0..) |entry, i| {
        results[i] = .{ .path = entry.path };
    }

    var group: std.Io.Group = .init;
    var i: usize = 0;
    while (i < entries.len) : (i += batch_size) {
        const end = @min(i + batch_size, entries.len);
        try group.concurrent(io, countBatch, .{ io, entries[i..end], results[i..end], extensions_only });
    }
    try group.await(io);

    return results;
}

fn countBatch(io: std.Io, entries: []const FileEntry, results: []FileResult, extensions_only: bool) std.Io.Cancelable!void {
    for (entries, 0..) |entry, j| {
        countSingle(io, entry.path, &results[j], extensions_only);
    }
}

const small_file_threshold = 64 * 1024;

fn countSingle(io: std.Io, path: []const u8, result: *FileResult, extensions_only: bool) void {
    const cwd = std.Io.Dir.cwd();
    const file = cwd.openFile(io, path, .{}) catch return;
    defer file.close(io);

    const file_stats = file.stat(io) catch return;
    const size: usize = @intCast(file_stats.size);
    if (size == 0 or size > 100 * 1024 * 1024) return;

    const language = lang.detect(path);
    result.lang_ptr = language;

    if (size < small_file_threshold) {
        const buf = std.heap.page_allocator.alloc(u8, size) catch return;
        defer std.heap.page_allocator.free(buf);
        const n = file.readPositionalAll(io, buf, 0) catch return;
        if (n < size) return;
        if (!extensions_only) {
            result.is_binary = binary.isBinary(buf);
            if (result.is_binary) return;
        }
        result.line_count = lines_mod.countLines(buf, language);
    } else {
        var mm = file.createMemoryMap(io, .{
            .len = size,
            .protection = .{ .read = true },
        }) catch return;
        defer mm.destroy(io);
        if (!extensions_only) {
            result.is_binary = binary.isBinary(mm.memory);
            if (result.is_binary) return;
        }
        result.line_count = lines_mod.countLines(mm.memory, language);
    }
}

pub fn countFileMmap(io: std.Io, path: []const u8, counters: *AtomicCounters) void {
    const cwd = std.Io.Dir.cwd();
    const file = cwd.openFile(io, path, .{}) catch return;
    defer file.close(io);

    const file_stats = file.stat(io) catch return;
    const size: usize = @intCast(file_stats.size);
    if (size == 0 or size > 100 * 1024 * 1024) return;

    const language = lang.detect(path);

    if (size < small_file_threshold) {
        const buf = std.heap.page_allocator.alloc(u8, size) catch return;
        defer std.heap.page_allocator.free(buf);
        const n = file.readPositionalAll(io, buf, 0) catch return;
        if (n < size) return;
        const is_bin = binary.isBinary(buf);
        counters.countFile(buf, language, is_bin);
    } else {
        var mm = file.createMemoryMap(io, .{
            .len = size,
            .protection = .{ .read = true },
        }) catch return;
        defer mm.destroy(io);
        const is_bin = binary.isBinary(mm.memory);
        counters.countFile(mm.memory, language, is_bin);
    }
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

    pub fn aggregate(self: *AtomicCounters, allocator: std.mem.Allocator, sort_by: []const u8, top_n: ?u32) !AggregateResult {
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
        const len = topNOrSort(result, sort_by, top_n);
        const trimmed = try allocator.alloc(lang.LanguageStat, len);
        @memcpy(trimmed, result[0..len]);
        allocator.free(result);

        return .{ .stats = trimmed, .total = total };
    }
};

fn topNOrSort(stats: []lang.LanguageStat, sort_by: []const u8, top_n: ?u32) usize {
    const n = top_n orelse @as(usize, stats.len);
    if (n >= stats.len) {
        sortStats(stats, sort_by);
        return stats.len;
    }

    for (0..n) |i| {
        siftUp(stats, i, sort_by);
    }

    for (n..stats.len) |i| {
        if (isGreater(stats[i], stats[0], sort_by)) {
            stats[0] = stats[i];
            siftDown(stats, 0, n, sort_by);
        }
    }

    sortStats(stats[0..n], sort_by);
    return n;
}

fn isGreater(a: lang.LanguageStat, b: lang.LanguageStat, sort_by: []const u8) bool {
    if (std.mem.eql(u8, sort_by, "files")) return a.files > b.files;
    if (std.mem.eql(u8, sort_by, "code")) return a.code > b.code;
    if (std.mem.eql(u8, sort_by, "name")) return std.mem.lessThan(u8, a.name, b.name);
    return a.lines > b.lines;
}

fn siftUp(stats: []lang.LanguageStat, start: usize, sort_by: []const u8) void {
    var i = start;
    while (i > 0) {
        const parent = (i - 1) / 2;
        if (!isGreater(stats[i], stats[parent], sort_by)) break;
        std.mem.swap(lang.LanguageStat, &stats[i], &stats[parent]);
        i = parent;
    }
}

fn siftDown(stats: []lang.LanguageStat, root: usize, len: usize, sort_by: []const u8) void {
    var r = root;
    while (true) {
        var smallest = r;
        const left = 2 * r + 1;
        const right = 2 * r + 2;
        if (left < len and isGreater(stats[left], stats[smallest], sort_by)) smallest = left;
        if (right < len and isGreater(stats[right], stats[smallest], sort_by)) smallest = right;
        if (smallest == r) break;
        std.mem.swap(lang.LanguageStat, &stats[r], &stats[smallest]);
        r = smallest;
    }
}

fn sortStats(stats: []lang.LanguageStat, sort_by: []const u8) void {
    std.mem.sort(lang.LanguageStat, stats, sort_by, struct {
        fn cmp(ctx: []const u8, a: lang.LanguageStat, b: lang.LanguageStat) bool {
            if (std.mem.eql(u8, ctx, "files")) return a.files > b.files;
            if (std.mem.eql(u8, ctx, "code")) return a.code > b.code;
            if (std.mem.eql(u8, ctx, "name")) return std.mem.lessThan(u8, a.name, b.name);
            return a.lines > b.lines;
        }
    }.cmp);
}

pub fn aggregate(allocator: std.mem.Allocator, results: []const FileResult, sort_by: []const u8, top_n: ?u32) !AggregateResult {
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

    const len = topNOrSort(stats, sort_by, top_n);
    const trimmed = try allocator.alloc(lang.LanguageStat, len);
    @memcpy(trimmed, stats[0..len]);
    allocator.free(stats);

    return .{ .stats = trimmed, .total = total };
}
