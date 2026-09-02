const std = @import("std");
const cli = @import("cli.zig");
const scan = @import("scan/mod.zig");
const count = @import("count/mod.zig");
const display = @import("display/mod.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const config = try cli.parse(allocator);

    const entries = try scan.collectFiles(allocator, config);
    defer {
        for (entries) |e| allocator.free(e.path);
        allocator.free(entries);
    }

    if (entries.len == 0) {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("\n  No files found.\n\n", .{});
        return;
    }

    const results = try count.countAll(allocator, entries);
    defer allocator.free(results);

    const agg = try count.aggregate(allocator, results);
    defer allocator.free(agg.stats);

    try display.show(allocator, results, agg, config);
}
