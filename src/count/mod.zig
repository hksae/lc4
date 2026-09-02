const std = @import("std");
const lang = @import("../lang/mod.zig");
const lines = @import("lines.zig");
const binary = @import("binary.zig");
const FileEntry = @import("../scan/mod.zig").FileEntry;

pub const FileResult = struct {
    path: []const u8,
    lang_ptr: *const lang.Language,
    line_count: lines.LineCount = .{},
    is_binary: bool = false,
};

pub const AggregateResult = struct {
    stats: []lang.LanguageStat,
    total: lang.LanguageStat,
};

pub fn countAll(allocator: std.mem.Allocator, entries: []const FileEntry) ![]FileResult {
    var results = try allocator.alloc(FileResult, entries.len);
    for (entries, 0..) |entry, i| {
        results[i] = .{
            .path = entry.path,
            .lang_ptr = entry.lang_ptr,
        };
    }

    var pool: std.Thread.Pool = undefined;
    try pool.init(.{ .allocator = allocator });
    defer pool.deinit();

    var wg: std.Thread.WaitGroup = .{};
    for (entries, 0..) |entry, i| {
        pool.spawnWg(&wg, countSingle, .{ entry, &results[i] });
    }
    pool.waitAndWork(&wg);

    return results;
}

fn countSingle(entry: FileEntry, result: *FileResult) void {
    const content = readFile(entry.path) orelse return;
    defer std.heap.page_allocator.free(content);

    result.is_binary = binary.isBinary(content);
    if (result.is_binary) return;

    result.line_count = lines.countLines(content, entry.lang_ptr);
}

fn readFile(path: []const u8) ?[]u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch return null;
    defer file.close();
    const stat = file.stat() catch return null;
    const size: usize = @intCast(stat.size);
    if (size == 0) return &[_]u8{};
    if (size > 100 * 1024 * 1024) return null;
    const buf = std.heap.page_allocator.alloc(u8, size) catch return null;
    var total: usize = 0;
    while (total < size) {
        const n = file.read(buf[total..size]) catch {
            std.heap.page_allocator.free(buf);
            return null;
        };
        if (n == 0) {
            std.heap.page_allocator.free(buf);
            return null;
        }
        total += n;
    }
    return buf;
}

pub fn aggregate(allocator: std.mem.Allocator, results: []const FileResult) !AggregateResult {
    var map = std.StringHashMap(lang.LanguageStat).init(allocator);
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

    std.mem.sort(lang.LanguageStat, stats, {}, struct {
        fn cmp(_: void, a: lang.LanguageStat, b: lang.LanguageStat) bool {
            return a.lines > b.lines;
        }
    }.cmp);

    return .{ .stats = stats, .total = total };
}
