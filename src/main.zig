const std = @import("std");
const cli = @import("cli.zig");
const scan = @import("scan/mod.zig");
const count = @import("count/mod.zig");
const display = @import("display/mod.zig");
const terminal = @import("terminal.zig");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;

    var threaded: std.Io.Threaded = .init(gpa, .{});
    defer threaded.deinit();
    const io = threaded.io();

    terminal.setup();

    var config = cli.parse(gpa, io, init.minimal.args) catch |err| {
        if (err == error.InvalidArguments) std.process.exit(2);
        return err;
    };
    defer config.deinit(gpa);

    const entries = try scan.collectFiles(gpa, io, config);
    defer {
        for (entries) |entry| gpa.free(entry.path);
        gpa.free(entries);
    }

    const results = try count.countAll(gpa, io, entries, config.include_binaries);
    defer gpa.free(results);

    const agg = try count.aggregate(gpa, results, config.sort_by, config.top_n);
    defer gpa.free(agg.stats);

    try display.show(gpa, io, results, agg, config);
}

pub fn emit(io: std.Io, data: []const u8) !void {
    try std.Io.File.stdout().writeStreamingAll(io, data);
}
