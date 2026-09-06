const std = @import("std");
const Config = @import("../config.zig").Config;
const gitignore = @import("gitignore.zig");

pub const FileEntry = struct { path: []const u8 };

const skip_dirs = [_][]const u8{ ".git", ".svn", ".hg", "node_modules", "__pycache__", ".venv", "venv", ".idea", ".vscode", ".zig-cache", ".zig-out", "zig-out", "target" };

const Frame = struct {
    relative: []const u8,
    patterns: std.ArrayList(gitignore.Pattern),

    fn deinit(self: *Frame, allocator: std.mem.Allocator) void {
        allocator.free(self.relative);
        self.patterns.deinit(allocator);
    }
};

pub fn collectFiles(allocator: std.mem.Allocator, io: std.Io, config: Config) ![]FileEntry {
    const root_path = config.root_path orelse ".";
    var root = std.Io.Dir.cwd().openDir(io, root_path, .{ .iterate = true }) catch |err| {
        const msg = try std.fmt.allocPrint(allocator, "Cannot open '{s}': {}\n", .{ root_path, err });
        defer allocator.free(msg);
        try std.Io.File.stderr().writeStreamingAll(io, msg);
        return error.CannotOpenDir;
    };
    defer root.close(io);

    var owned_patterns: std.ArrayList(gitignore.Pattern) = .empty;
    defer {
        for (owned_patterns.items) |pat| pat.deinit(allocator);
        owned_patterns.deinit(allocator);
    }
    var stack: std.ArrayList(Frame) = .empty;
    defer {
        for (stack.items) |*frame| frame.deinit(allocator);
        stack.deinit(allocator);
    }
    const initial_patterns: std.ArrayList(gitignore.Pattern) = .empty;
    const initial_relative = try allocator.dupe(u8, "");
    stack.append(allocator, .{ .relative = initial_relative, .patterns = initial_patterns }) catch |err| {
        allocator.free(initial_relative);
        return err;
    };

    var result: std.ArrayList(FileEntry) = .empty;
    errdefer {
        for (result.items) |entry| allocator.free(entry.path);
        result.deinit(allocator);
    }

    while (stack.pop()) |frame_value| {
        var frame = frame_value;
        defer frame.deinit(allocator);

        var dir = if (frame.relative.len == 0)
            root
        else
            try root.openDir(io, frame.relative, .{ .iterate = true });
        const close_dir = frame.relative.len != 0;
        defer if (close_dir) dir.close(io);

        if (config.respect_gitignore) {
            const content = dir.readFileAlloc(io, ".gitignore", allocator, .limited(10 * 1024 * 1024)) catch |err| switch (err) {
                error.FileNotFound => null,
                else => return err,
            };
            if (content) |bytes| {
                defer allocator.free(bytes);
                var local = try gitignore.parseScoped(allocator, bytes, frame.relative);
                defer {
                    for (local.items) |pat| pat.deinit(allocator);
                    local.deinit(allocator);
                }
                // The frame only borrows patterns. Transfer ownership only after both
                // append operations succeed so allocation failures cannot leak them.
                try frame.patterns.appendSlice(allocator, local.items);
                try owned_patterns.appendSlice(allocator, local.items);
                local.clearRetainingCapacity();
            }
        }

        var iterator = dir.iterateAssumeFirstIteration();
        while (try iterator.next(io)) |entry| {
            if (entry.kind != .file and entry.kind != .directory) continue;
            const relative = try joinRelative(allocator, frame.relative, entry.name);
            errdefer allocator.free(relative);

            if (entry.kind == .directory) {
                if (config.respect_gitignore and (isBuiltInSkipped(entry.name) or gitignore.isIgnoredPath(relative, true, frame.patterns.items))) {
                    allocator.free(relative);
                    continue;
                }
                var child_patterns: std.ArrayList(gitignore.Pattern) = .empty;
                errdefer child_patterns.deinit(allocator);
                try child_patterns.appendSlice(allocator, frame.patterns.items);
                try stack.append(allocator, .{ .relative = relative, .patterns = child_patterns });
                continue;
            }

            if (config.respect_gitignore and gitignore.isIgnoredPath(relative, false, frame.patterns.items)) {
                allocator.free(relative);
                continue;
            }
            if (!extensionAllowed(relative, config.extensions)) {
                allocator.free(relative);
                continue;
            }
            const output_path = if (config.root_path != null and !std.mem.eql(u8, root_path, "."))
                try std.fs.path.join(allocator, &.{ root_path, relative })
            else
                try allocator.dupe(u8, relative);
            errdefer allocator.free(output_path);
            try result.append(allocator, .{ .path = output_path });
            allocator.free(relative);
        }
    }
    return try result.toOwnedSlice(allocator);
}

fn joinRelative(allocator: std.mem.Allocator, parent: []const u8, name: []const u8) ![]u8 {
    if (parent.len == 0) return allocator.dupe(u8, name);
    const relative = try allocator.alloc(u8, parent.len + 1 + name.len);
    @memcpy(relative[0..parent.len], parent);
    relative[parent.len] = '/';
    @memcpy(relative[parent.len + 1 ..], name);
    return relative;
}

fn isBuiltInSkipped(name: []const u8) bool {
    for (skip_dirs) |skip| if (std.mem.eql(u8, name, skip)) return true;
    return false;
}

fn extensionAllowed(path: []const u8, extensions: ?[]const []const u8) bool {
    const exts = extensions orelse return true;
    const ext = std.fs.path.extension(path);
    for (exts) |wanted| if (std.mem.eql(u8, ext, wanted)) return true;
    return false;
}
