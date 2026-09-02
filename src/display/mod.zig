const std = @import("std");
const Config = @import("../config.zig").Config;
const count = @import("../count/mod.zig");
const table = @import("table.zig");
const json = @import("json.zig");
const verbose = @import("verbose.zig");

pub fn show(allocator: std.mem.Allocator, io: std.Io, results: []const count.FileResult, agg: count.AggregateResult, config: Config) !void {
    const stdout = std.Io.File.stdout();

    if (config.json_output) {
        const buf = try json.render(allocator, agg.stats, agg.total);
        defer allocator.free(buf);
        try stdout.writeStreamingAll(io, buf);
    } else {
        const buf = try table.render(allocator, agg.stats, agg.total);
        defer allocator.free(buf);
        try stdout.writeStreamingAll(io, buf);
        if (config.verbose) {
            const vb = try verbose.render(allocator, results, agg.stats);
            defer allocator.free(vb);
            try stdout.writeStreamingAll(io, vb);
        }
    }
}
