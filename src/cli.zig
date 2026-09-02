const std = @import("std");
const Config = @import("config.zig").Config;

pub fn parse(allocator: std.mem.Allocator) !Config {
    var config = Config{};
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next();

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            printHelp();
            std.process.exit(0);
        } else if (std.mem.eql(u8, arg, "-a") or std.mem.eql(u8, arg, "--all")) {
            config.respect_gitignore = false;
        } else if (std.mem.eql(u8, arg, "-b") or std.mem.eql(u8, arg, "--binaries")) {
            config.include_binaries = true;
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--verbose")) {
            config.verbose = true;
        } else if (std.mem.eql(u8, arg, "--json")) {
            config.json_output = true;
        } else if (std.mem.eql(u8, arg, "-e") or std.mem.eql(u8, arg, "--ext")) {
            if (args.next()) |ext_str| {
                var exts = std.ArrayList([]const u8).init(allocator);
                var it = std.mem.splitScalar(u8, ext_str, ',');
                while (it.next()) |ext| {
                    const trimmed = std.mem.trim(u8, ext, " \t");
                    if (trimmed.len > 0) {
                        if (trimmed[0] != '.') {
                            const with_dot = try std.fmt.allocPrint(allocator, ".{s}", .{trimmed});
                            try exts.append(with_dot);
                        } else {
                            try exts.append(trimmed);
                        }
                    }
                }
                config.extensions = try exts.toOwnedSlice();
            }
        } else {
            std.debug.print("Unknown option: {s}\n", .{arg});
            printHelp();
            std.process.exit(1);
        }
    }

    return config;
}

fn printHelp() void {
    const stdout = std.io.getStdOut().writer();
    stdout.print(
        \\linecounter4 - fast line counter
        \\
        \\Usage: linecounter4 [options]
        \\
        \\Options:
        \\  -a, --all            Ignore .gitignore, scan all files
        \\  -b, --binaries       Include binary files in count
        \\  -v, --verbose        Show per-file breakdown
        \\      --json           Output as JSON
        \\  -e, --ext .ext,...   Filter by extensions (comma-separated)
        \\  -h, --help           Show this help
        \\
    , .{}) catch {};
}
