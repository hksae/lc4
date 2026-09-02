const std = @import("std");
const Config = @import("../config.zig").Config;
const count = @import("../count/mod.zig");
const table = @import("table.zig");
const json = @import("json.zig");
const verbose = @import("verbose.zig");

pub fn show(allocator: std.mem.Allocator, results: []const count.FileResult, agg: count.AggregateResult, config: Config) !void {
    const stdout = std.io.getStdOut().writer();

    if (config.json_output) {
        try json.printJson(stdout, agg.stats, agg.total);
    } else {
        try table.printTable(stdout, agg.stats, agg.total);
        if (config.verbose) {
            try verbose.printVerbose(stdout, results, agg.stats);
        }
    }

    _ = allocator;
}
