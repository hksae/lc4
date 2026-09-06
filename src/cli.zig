const std = @import("std");
const Config = @import("config.zig").Config;
const build_options = @import("build_options");

pub fn parse(allocator: std.mem.Allocator, io: std.Io, args_value: std.process.Args) !Config {
    var config = Config{};
    errdefer config.deinit(allocator);

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
            const value = args.next() orelse return invalidValue(allocator, io, "--sort", "missing value");
            config.sort_by = std.meta.stringToEnum(@import("config.zig").SortBy, value) orelse
                return invalidValue(allocator, io, "--sort", value);
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--verbose")) {
            config.verbose = true;
        } else if (std.mem.eql(u8, arg, "--json")) {
            config.json_output = true;
        } else if (std.mem.eql(u8, arg, "-s") or std.mem.eql(u8, arg, "--short")) {
            config.short_output = true;
        } else if (std.mem.eql(u8, arg, "--top")) {
            const value = args.next() orelse return invalidValue(allocator, io, "--top", "missing value");
            config.top_n = std.fmt.parseInt(u32, value, 10) catch
                return invalidValue(allocator, io, "--top", value);
        } else if (std.mem.eql(u8, arg, "-e") or std.mem.eql(u8, arg, "--ext")) {
            const value = args.next() orelse return invalidValue(allocator, io, arg, "missing value");
            if (value.len > 0 and value[0] == '-') return invalidValue(allocator, io, arg, "missing value");
            const extensions = try parseExtensions(allocator, value);
            if (extensions.len == 0) {
                allocator.free(extensions);
                return invalidValue(allocator, io, arg, value);
            }
            freeExtensions(allocator, config.extensions);
            config.extensions = extensions;
        } else if (arg.len > 0 and arg[0] != '-') {
            const path = try allocator.dupe(u8, arg);
            if (config.root_path) |old_path| allocator.free(old_path);
            config.root_path = path;
        } else {
            return invalidValue(allocator, io, "option", arg);
        }
    }

    return config;
}

fn parseExtensions(allocator: std.mem.Allocator, value: []const u8) ![]const []const u8 {
    var extensions: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (extensions.items) |extension| allocator.free(extension);
        extensions.deinit(allocator);
    }

    var it = std.mem.splitScalar(u8, value, ',');
    while (it.next()) |extension| {
        const trimmed = std.mem.trim(u8, extension, " \t");
        if (trimmed.len == 0) continue;
        const owned = if (trimmed[0] == '.')
            try allocator.dupe(u8, trimmed)
        else
            try std.fmt.allocPrint(allocator, ".{s}", .{trimmed});
        extensions.append(allocator, owned) catch |err| {
            allocator.free(owned);
            return err;
        };
    }
    return extensions.toOwnedSlice(allocator);
}

fn freeExtensions(allocator: std.mem.Allocator, maybe_extensions: ?[]const []const u8) void {
    if (maybe_extensions) |extensions| {
        for (extensions) |extension| allocator.free(extension);
        allocator.free(extensions);
    }
}

fn invalidValue(allocator: std.mem.Allocator, io: std.Io, option: []const u8, value: []const u8) error{InvalidArguments} {
    const message = std.fmt.allocPrint(allocator, "Invalid {s}: {s}\n", .{ option, value }) catch return error.InvalidArguments;
    defer allocator.free(message);
    std.Io.File.stderr().writeStreamingAll(io, message) catch {};
    return error.InvalidArguments;
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
        \\  -s, --short          One-line summary output
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
