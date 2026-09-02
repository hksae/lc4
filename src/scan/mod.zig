const std = @import("std");
const Config = @import("../config.zig").Config;
const lang = @import("../lang/mod.zig");
const gitignore = @import("gitignore.zig");

pub const FileEntry = struct {
    path: []const u8,
    lang_ptr: *const lang.Language,
};

const skip_dirs = [_][]const u8{ ".git", ".svn", ".hg", "node_modules", "__pycache__", ".venv", "venv", ".idea", ".vscode" };

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

    var walker = try root.walk(allocator);
    defer walker.deinit();

    var entries: std.ArrayList(FileEntry) = .empty;
    errdefer {
        for (entries.items) |e| allocator.free(e.path);
        entries.deinit(allocator);
    }

    while (try walker.next(io)) |entry| {
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
        try entries.append(allocator, .{ .path = path_copy, .lang_ptr = language });
    }

    return try entries.toOwnedSlice(allocator);
}
