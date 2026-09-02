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

    const config = try cli.parse(gpa, io, init.minimal.args);

    const entries = try scan.collectFiles(gpa, io, config);
    defer {
        for (entries) |e| gpa.free(e.path);
        gpa.free(entries);
    }

    if (entries.len == 0) {
        try emit(io, "\n  No files found.\n\n");
        return;
    }

    const results = try count.countAll(gpa, io, entries);
    defer gpa.free(results);

    const agg = try count.aggregate(gpa, results);
    defer gpa.free(agg.stats);

    try display.show(gpa, io, results, agg, config);
}

pub fn emit(io: std.Io, data: []const u8) !void {
    try std.Io.File.stdout().writeStreamingAll(io, data);
}
