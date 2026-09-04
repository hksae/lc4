const std = @import("std");
const Config = @import("config.zig").Config;
const build_options = @import("build_options");

pub fn parse(allocator: std.mem.Allocator, io: std.Io, args_value: std.process.Args) !Config {
    var config = Config{};
    var args = try args_value.iterateAllocator(allocator);
    defer args.deinit();
    _ = args.next();

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            const buf = try buildHelp(allocator);
            defer allocator.free(buf);
            try std.Io.File.stdout().writeStreamingAll(io, buf);
            std.process.exit(0);
        } else if (std.mem.eql(u8, arg, "-V") or std.mem.eql(u8, arg, "--version")) {
            try std.Io.File.stdout().writeStreamingAll(io, "lc4 " ++ build_options.version ++ "\n");
            std.process.exit(0);
        } else if (std.mem.eql(u8, arg, "-a") or std.mem.eql(u8, arg, "--all")) {
            config.respect_gitignore = false;
        } else if (std.mem.eql(u8, arg, "-b") or std.mem.eql(u8, arg, "--binaries")) {
            config.include_binaries = true;
        } else if (std.mem.eql(u8, arg, "-n") or std.mem.eql(u8, arg, "--no-color")) {
            config.no_color = true;
        } else if (std.mem.eql(u8, arg, "--sort")) {
            if (args.next()) |s| {
                config.sort_by = s;
            }
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--verbose")) {
            config.verbose = true;
        } else if (std.mem.eql(u8, arg, "--json")) {
            config.json_output = true;
        } else if (std.mem.eql(u8, arg, "--top")) {
            if (args.next()) |n_str| {
                config.top_n = std.fmt.parseInt(u32, n_str, 10) catch null;
            }
        } else if (std.mem.eql(u8, arg, "-e") or std.mem.eql(u8, arg, "--ext")) {
            if (args.next()) |ext_str| {
                var exts: std.ArrayList([]const u8) = .empty;
                errdefer exts.deinit(allocator);
                var it = std.mem.splitScalar(u8, ext_str, ',');
                while (it.next()) |ext| {
                    const trimmed = std.mem.trim(u8, ext, " \t");
                    if (trimmed.len > 0) {
                        if (trimmed[0] != '.') {
                            const with_dot = try std.fmt.allocPrint(allocator, ".{s}", .{trimmed});
                            try exts.append(allocator, with_dot);
                        } else {
                            try exts.append(allocator, trimmed);
                        }
                    }
                }
                config.extensions = try exts.toOwnedSlice(allocator);
            }
        } else if (arg[0] != '-') {
            config.root_path = try allocator.dupe(u8, arg);
        } else {
            const err_buf = try std.fmt.allocPrint(allocator, "Unknown option: {s}\n", .{arg});
            defer allocator.free(err_buf);
            try std.Io.File.stderr().writeStreamingAll(io, err_buf);
            const help_buf = try buildHelp(allocator);
            defer allocator.free(help_buf);
            try std.Io.File.stderr().writeStreamingAll(io, help_buf);
            std.process.exit(1);
        }
    }

    return config;
}

fn buildHelp(allocator: std.mem.Allocator) ![]u8 {
    var aw = std.Io.Writer.Allocating.init(allocator);
    const w = &aw.writer;
    try w.print(
        \\lc4 - fast line counter
        \\
        \\Usage: lc4 [options] [path]
        \\
        \\Options:
        \\  -a, --all            Ignore .gitignore, scan all files
        \\  -b, --binaries       Include binary files in count
        \\  -n, --no-color       Disable colored output
        \\  -v, --verbose        Show per-file breakdown
        \\      --json           Output as JSON
        \\      --sort FIELD     Sort by: lines (default), files, code, name
        \\      --top N          Show only top N languages
        \\  -e, --ext .ext,...   Filter by extensions (comma-separated)
        \\  -V, --version        Show version
        \\  -h, --help           Show this help
        \\
    , .{});
    return aw.toOwnedSlice();
}
