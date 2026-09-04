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

fn readFile(io: std.Io, path: []const u8) ?[]u8 {
    const cwd = std.Io.Dir.cwd();
    const file = cwd.openFile(io, path, .{}) catch return null;
    defer file.close(io);

    var buf: [64 * 1024]u8 = undefined;
    var total: std.ArrayList(u8) = .empty;

    while (true) {
        const n = file.readStreaming(io, &.{&buf}) catch {
            total.deinit(std.heap.smp_allocator);
            return null;
        };
        if (n == 0) break;
        total.appendSlice(std.heap.smp_allocator, buf[0..n]) catch {
            total.deinit(std.heap.smp_allocator);
            return null;
        };
    }

    if (total.items.len > 100 * 1024 * 1024) {
        total.deinit(std.heap.smp_allocator);
        return null;
    }

    return total.toOwnedSlice(std.heap.smp_allocator) catch null;
}

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
