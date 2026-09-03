const std = @import("std");
const Config = @import("../config.zig").Config;
const lang = @import("../lang/mod.zig");
const gitignore = @import("gitignore.zig");

pub const FileEntry = struct {
    path: []const u8,
    lang_ptr: *const lang.Language,
};

const skip_dirs = [_][]const u8{ ".git", ".svn", ".hg", "node_modules", "__pycache__", ".venv", "venv", ".idea", ".vscode", ".zig-cache", ".zig-out", "zig-out", "target" };

const ScanContext = struct {
    rwlock: std.Io.RwLock = .init,
    entries: std.ArrayList(FileEntry),
    allocator: std.mem.Allocator,
    respect_gitignore: bool,
    gitignore_patterns: ?[]const gitignore.Pattern,
    extensions: ?[]const []const u8,
};

pub fn collectFiles(allocator: std.mem.Allocator, io: std.Io, config: Config) ![]FileEntry {
    const cwd = std.Io.Dir.cwd();
    var root = try cwd.openDir(io, ".", .{ .iterate = true });
    defer root.close(io);

    var gitignore_patterns: ?std.ArrayList(gitignore.Pattern) = .empty;
    defer {
        if (gitignore_patterns) |*p| {
            for (p.items) |pat| allocator.free(pat.text);
            p.deinit(allocator);
        }
    }

    if (config.respect_gitignore) {
        const content = root.readFileAlloc(io, ".gitignore", allocator, .limited(10 * 1024 * 1024)) catch null;
        if (content) |c| {
            defer allocator.free(c);
            gitignore_patterns = try gitignore.parse(allocator, c);
        }
    }

    var subdirs: std.ArrayList([]const u8) = .empty;
    defer {
        for (subdirs.items) |d| allocator.free(d);
        subdirs.deinit(allocator);
    }

    var root_entries: std.ArrayList(FileEntry) = .empty;
    defer root_entries.deinit(allocator);

    var root_walker = try root.walk(allocator);
    defer root_walker.deinit();

    while (try root_walker.next(io)) |entry| {
        if (entry.kind == .directory) {
            var skip = false;
            for (skip_dirs) |sd| {
                if (std.mem.eql(u8, entry.basename, sd)) {
                    root_walker.leave(io);
                    skip = true;
                    break;
                }
            }
            if (skip) continue;

            const has_sep = for (entry.path) |c| {
                if (c == '/' or c == '\\') break true;
            } else false;
            if (has_sep) continue;

            const dir_copy = try allocator.dupe(u8, entry.path);
            try subdirs.append(allocator, dir_copy);
            continue;
        }

        if (entry.kind != .file) continue;

        const root_file = for (entry.path) |c| {
            if (c == '/' or c == '\\') break false;
        } else true;
        if (!root_file) continue;

        const path_copy = try allocator.dupe(u8, entry.path);

        if (config.respect_gitignore) {
            if (gitignore_patterns) |patterns| {
                if (gitignore.isIgnored(path_copy, patterns.items)) {
                    allocator.free(path_copy);
                    continue;
                }
            }
        }

        if (config.extensions) |exts| {
            const ext = std.fs.path.extension(path_copy);
            var found = false;
            for (exts) |e| {
                if (std.mem.eql(u8, ext, e)) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                allocator.free(path_copy);
                continue;
            }
        }

        const language = lang.detect(path_copy);
        try root_entries.append(allocator, .{ .path = path_copy, .lang_ptr = language });
    }

    var ctx = ScanContext{
        .entries = .empty,
        .allocator = allocator,
        .respect_gitignore = config.respect_gitignore,
        .gitignore_patterns = if (gitignore_patterns) |p| p.items else null,
        .extensions = config.extensions,
    };

    var group: std.Io.Group = .init;

    for (subdirs.items) |dir_path| {
        try group.concurrent(io, walkSubdir, .{ io, &ctx, dir_path });
    }
    try group.await(io);

    for (root_entries.items) |e| {
        try ctx.entries.append(allocator, e);
    }
    root_entries.clearRetainingCapacity();

    return try ctx.entries.toOwnedSlice(allocator);
}

fn walkSubdir(
    io: std.Io,
    ctx: *ScanContext,
    dir_path: []const u8,
) std.Io.Cancelable!void {
    const cwd = std.Io.Dir.cwd();
    var dir = cwd.openDir(io, dir_path, .{ .iterate = true }) catch return;
    defer dir.close(io);

    var walker = dir.walk(ctx.allocator) catch return;
    defer walker.deinit();

    while (walker.next(io) catch null) |entry| {
        if (entry.kind == .directory) {
            for (skip_dirs) |sd| {
                if (std.mem.eql(u8, entry.basename, sd)) {
                    walker.leave(io);
                    break;
                }
            }
            continue;
        }

        if (entry.kind != .file) continue;

        const full_path = std.fs.path.join(ctx.allocator, &.{ dir_path, entry.path }) catch continue;

        if (ctx.respect_gitignore) {
            if (ctx.gitignore_patterns) |patterns| {
                if (gitignore.isIgnored(full_path, patterns)) {
                    ctx.allocator.free(full_path);
                    continue;
                }
            }
        }

        if (ctx.extensions) |exts| {
            const ext = std.fs.path.extension(full_path);
            var found = false;
            for (exts) |e| {
                if (std.mem.eql(u8, ext, e)) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                ctx.allocator.free(full_path);
                continue;
            }
        }

        const language = lang.detect(full_path);

        ctx.rwlock.lockUncancelable(io);
        defer ctx.rwlock.unlock(io);
        ctx.entries.append(ctx.allocator, .{ .path = full_path, .lang_ptr = language }) catch {
            ctx.allocator.free(full_path);
        };
    }
}
