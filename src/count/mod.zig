const std = @import("std");
const lang = @import("../lang/mod.zig");
const lines_mod = @import("lines.zig");
const binary = @import("binary.zig");
const FileEntry = @import("../scan/mod.zig").FileEntry;
const SortBy = @import("../config.zig").SortBy;

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

const max_count_jobs = 8;
const small_file_threshold = 64 * 1024;

pub fn countAll(allocator: std.mem.Allocator, io: std.Io, entries: []const FileEntry, include_binaries: bool) ![]FileResult {
    const results = try allocator.alloc(FileResult, entries.len);
    errdefer allocator.free(results);
    for (entries, 0..) |entry, i| results[i] = .{ .path = entry.path };

    var failed = std.atomic.Value(bool).init(false);
    var group: std.Io.Group = .init;
    errdefer group.cancel(io);

    const job_count = @min(entries.len, max_count_jobs);
    if (job_count != 0) {
        const entries_per_job = entries.len / job_count;
        const jobs_with_extra_entry = entries.len % job_count;
        var start: usize = 0;
        for (0..job_count) |job_index| {
            const job_len = entries_per_job + @intFromBool(job_index < jobs_with_extra_entry);
            const end = start + job_len;
            try group.concurrent(io, countBatch, .{ io, entries[start..end], results[start..end], include_binaries, &failed });
            start = end;
        }
    }

    try group.await(io);
    if (failed.load(.acquire)) return error.CountFailed;
    return results;
}

fn countBatch(io: std.Io, entries: []const FileEntry, results: []FileResult, include_binaries: bool, failed: *std.atomic.Value(bool)) std.Io.Cancelable!void {
    for (entries, 0..) |entry, i| {
        countSingle(io, entry.path, &results[i], include_binaries) catch |err| switch (err) {
            error.Canceled => return error.Canceled,
            else => {
                failed.store(true, .release);
                var buffer: [1024]u8 = undefined;
                const message = std.fmt.bufPrint(&buffer, "Failed to count '{s}': {}\n", .{ entry.path, err }) catch
                    "Failed to count file (path too long to display)\n";
                std.Io.File.stderr().writeStreamingAll(io, message) catch {};
                continue;
            },
        };
    }
}

fn countSingle(io: std.Io, path: []const u8, result: *FileResult, include_binaries: bool) !void {
    const file = try std.Io.Dir.cwd().openFile(io, path, .{});
    defer file.close(io);

    const file_stats = try file.stat(io);
    const size = std.math.cast(usize, file_stats.size) orelse return error.FileTooBig;
    const language = lang.detect(path);
    result.lang_ptr = language;
    if (size == 0) return;

    if (size < small_file_threshold) {
        var buffer: [small_file_threshold]u8 = undefined;
        const read = try file.readPositionalAll(io, &buffer, 0);
        if (read != size) return error.UnexpectedEndOfFile;
        const content = buffer[0..size];
        result.is_binary = !include_binaries and binary.isBinary(content);
        if (!result.is_binary) result.line_count = lines_mod.countLines(content, language);
    } else {
        var memory_map = try file.createMemoryMap(io, .{
            .len = size,
            .protection = .{ .read = true },
        });
        defer memory_map.destroy(io);
        result.is_binary = !include_binaries and binary.isBinary(memory_map.memory);
        if (!result.is_binary) result.line_count = lines_mod.countLines(memory_map.memory, language);
    }
}

pub fn aggregate(allocator: std.mem.Allocator, results: []const FileResult, sort_by: SortBy, top_n: ?u32) !AggregateResult {
    var map: std.StringHashMap(lang.LanguageStat) = .init(allocator);
    defer map.deinit();
    var total = lang.LanguageStat{ .name = "Total", .color = "\x1b[1m" };

    for (results) |result| {
        if (result.is_binary) continue;
        const entry = try map.getOrPut(result.lang_ptr.name);
        if (!entry.found_existing) {
            entry.value_ptr.* = .{ .name = result.lang_ptr.name, .color = result.lang_ptr.color };
        }
        entry.value_ptr.files += 1;
        entry.value_ptr.lines += result.line_count.lines;
        entry.value_ptr.blanks += result.line_count.blanks;
        entry.value_ptr.comments += result.line_count.comments;
        entry.value_ptr.code += result.line_count.code;

        total.files += 1;
        total.lines += result.line_count.lines;
        total.blanks += result.line_count.blanks;
        total.comments += result.line_count.comments;
        total.code += result.line_count.code;
    }

    var stats = try allocator.alloc(lang.LanguageStat, map.count());
    defer allocator.free(stats);
    var iterator = map.valueIterator();
    var i: usize = 0;
    while (iterator.next()) |stat| : (i += 1) stats[i] = stat.*;
    return finishAggregate(allocator, stats, total, sort_by, top_n);
}

fn finishAggregate(allocator: std.mem.Allocator, stats: []lang.LanguageStat, total: lang.LanguageStat, sort_by: SortBy, top_n: ?u32) !AggregateResult {
    sortStats(stats, sort_by);
    const requested: usize = if (top_n) |n| @intCast(n) else stats.len;
    const len = @min(requested, stats.len);
    const trimmed = try allocator.dupe(lang.LanguageStat, stats[0..len]);
    return .{ .stats = trimmed, .total = total };
}

fn sortStats(stats: []lang.LanguageStat, sort_by: SortBy) void {
    std.mem.sort(lang.LanguageStat, stats, sort_by, struct {
        fn lessThan(context: SortBy, a: lang.LanguageStat, b: lang.LanguageStat) bool {
            const numeric_order = switch (context) {
                .files => std.math.order(a.files, b.files),
                .code => std.math.order(a.code, b.code),
                .name => return std.mem.lessThan(u8, a.name, b.name),
                .lines => std.math.order(a.lines, b.lines),
            };
            return switch (numeric_order) {
                .gt => true,
                .lt => false,
                .eq => std.mem.lessThan(u8, a.name, b.name),
            };
        }
    }.lessThan);
}

test "top N sorts the full set before slicing and accepts zero" {
    const allocator = std.testing.allocator;
    var stats = [_]lang.LanguageStat{
        .{ .name = "low", .color = "", .lines = 1 },
        .{ .name = "high", .color = "", .lines = 100 },
        .{ .name = "middle", .color = "", .lines = 50 },
    };

    const top = try finishAggregate(allocator, &stats, .{ .name = "Total", .color = "" }, .lines, 2);
    defer allocator.free(top.stats);
    try std.testing.expectEqual(@as(usize, 2), top.stats.len);
    try std.testing.expectEqualStrings("high", top.stats[0].name);
    try std.testing.expectEqualStrings("middle", top.stats[1].name);

    const empty = try finishAggregate(allocator, &stats, .{ .name = "Total", .color = "" }, .lines, 0);
    defer allocator.free(empty.stats);
    try std.testing.expectEqual(@as(usize, 0), empty.stats.len);
}

test "numeric sorts use alphabetical names to break ties" {
    const sort_fields = [_]SortBy{ .files, .lines, .code };
    for (sort_fields) |sort_by| {
        var stats = [_]lang.LanguageStat{
            .{ .name = "Zulu", .color = "", .files = 1, .lines = 2, .code = 3 },
            .{ .name = "Alpha", .color = "", .files = 1, .lines = 2, .code = 3 },
            .{ .name = "Middle", .color = "" },
        };

        sortStats(&stats, sort_by);
        try std.testing.expectEqualStrings("Alpha", stats[0].name);
        try std.testing.expectEqualStrings("Zulu", stats[1].name);
        try std.testing.expectEqualStrings("Middle", stats[2].name);
    }
}

test "name sort is alphabetical" {
    var stats = [_]lang.LanguageStat{
        .{ .name = "Zulu", .color = "" },
        .{ .name = "Alpha", .color = "" },
        .{ .name = "Middle", .color = "" },
    };

    sortStats(&stats, .name);
    try std.testing.expectEqualStrings("Alpha", stats[0].name);
    try std.testing.expectEqualStrings("Middle", stats[1].name);
    try std.testing.expectEqualStrings("Zulu", stats[2].name);
}

test "aggregate includes unknown and empty files while excluding binaries" {
    const allocator = std.testing.allocator;
    const zig_language = lang.detect("example.zig");
    const results = [_]FileResult{
        .{ .path = "empty.unknown", .lang_ptr = &lang.unknown },
        .{ .path = "code.zig", .lang_ptr = zig_language, .line_count = .{ .lines = 3, .blanks = 1, .comments = 1, .code = 1 } },
        .{ .path = "binary.zig", .lang_ptr = zig_language, .is_binary = true },
    };

    const aggregated = try aggregate(allocator, &results, .name, null);
    defer allocator.free(aggregated.stats);
    try std.testing.expectEqual(@as(u64, 2), aggregated.total.files);
    try std.testing.expectEqual(@as(u64, 3), aggregated.total.lines);
    try std.testing.expectEqual(@as(usize, 2), aggregated.stats.len);
    try std.testing.expectEqualStrings("Unknown", aggregated.stats[0].name);
    try std.testing.expectEqual(@as(u64, 1), aggregated.stats[0].files);
    try std.testing.expectEqualStrings("Zig", aggregated.stats[1].name);
}
