const std = @import("std");
const Config = @import("../config.zig").Config;
const count = @import("../count/mod.zig");
const lang = @import("../lang/mod.zig");
const table = @import("table.zig");
const json = @import("json.zig");
const verbose = @import("verbose.zig");

pub fn show(allocator: std.mem.Allocator, io: std.Io, results: []const count.FileResult, agg: count.AggregateResult, config: Config) !void {
    const stdout = std.Io.File.stdout();

    if (config.short_output) {
        const buf = try renderShort(allocator, agg.total);
        defer allocator.free(buf);
        try stdout.writeStreamingAll(io, buf);
    } else if (config.json_output) {
        const buf = try json.render(allocator, agg.stats, agg.total);
        defer allocator.free(buf);
        try stdout.writeStreamingAll(io, buf);
    } else {
        const buf = try table.render(allocator, agg.stats, agg.total, config.no_color);
        defer allocator.free(buf);
        try stdout.writeStreamingAll(io, buf);
        if (config.verbose) {
            const vb = try verbose.render(allocator, results, agg.stats, config.no_color);
            defer allocator.free(vb);
            try stdout.writeStreamingAll(io, vb);
        }
    }
}

fn renderShort(allocator: std.mem.Allocator, total: lang.LanguageStat) ![]u8 {
    var aw = std.Io.Writer.Allocating.init(allocator);
    const w = &aw.writer;
    try w.print("{d} files, {d} lines, {d} code, {d} blanks, {d} comments\n", .{
        total.files,
        total.lines,
        total.code,
        total.blanks,
        total.comments,
    });
    return aw.toOwnedSlice();
}
