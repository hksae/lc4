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
    defer {
        if (config.root_path) |p| gpa.free(p);
        if (config.extensions) |exts| {
            for (exts) |e| gpa.free(e);
            gpa.free(exts);
        }
    }

    if (config.verbose) {
        const entries = try scan.collectFiles(gpa, io, config);
        defer {
            for (entries) |e| gpa.free(e.path);
            gpa.free(entries);
        }

        if (entries.len == 0) {
            try emit(io, "\n  No files found.\n\n");
            return;
        }

        const results = try count.countAll(gpa, io, entries, config.extensions != null);
        defer gpa.free(results);

        const agg = try count.aggregate(gpa, results, config.sort_by);
        defer gpa.free(agg.stats);

        var agg_mutable = agg;
        if (config.top_n) |n| {
            if (agg_mutable.stats.len > n) agg_mutable.stats.len = n;
        }
        try display.show(gpa, io, results, agg_mutable, config);
    } else {
        var atomic = try scan.collectAndCountAtomic(gpa, io, config);
        defer atomic.deinit();

        if (atomic.map.count() == 0) {
            try emit(io, "\n  No files found.\n\n");
            return;
        }

        const agg = try atomic.aggregate(gpa, config.sort_by);
        defer gpa.free(agg.stats);

        var agg_mutable = agg;
        if (config.top_n) |n| {
            if (agg_mutable.stats.len > n) agg_mutable.stats.len = n;
        }
        try display.show(gpa, io, &.{}, agg_mutable, config);
    }
}

pub fn emit(io: std.Io, data: []const u8) !void {
    try std.Io.File.stdout().writeStreamingAll(io, data);
}
