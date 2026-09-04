const std = @import("std");
const Config = @import("../config.zig").Config;
const lang = @import("../lang/mod.zig");
const gitignore = @import("gitignore.zig");
const count = @import("../count/mod.zig");

pub const FileEntry = struct {
    path: []const u8,
    lang_ptr: *const lang.Language,
};

const skip_dirs = [_][]const u8{ ".git", ".svn", ".hg", "node_modules", "__pycache__", ".venv", "venv", ".idea", ".vscode", ".zig-cache", ".zig-out", "zig-out", "target" };

const SubdirTask = struct {
    entries: std.ArrayList(FileEntry),
    allocator: std.mem.Allocator,
    respect_gitignore: bool,
    gitignore_patterns: ?[]const gitignore.Pattern,
    extensions: ?[]const []const u8,
    scan_all: bool,
};

pub fn collectFiles(allocator: std.mem.Allocator, io: std.Io, config: Config) ![]FileEntry {
    const cwd = std.Io.Dir.cwd();
    const root_path = config.root_path orelse ".";
    var root = cwd.openDir(io, root_path, .{ .iterate = true }) catch |err| {
        const msg = try std.fmt.allocPrint(allocator, "Cannot open '{s}': {}\n", .{ root_path, err });
        defer allocator.free(msg);
        try std.Io.File.stderr().writeStreamingAll(io, msg);
        return error.CannotOpenDir;
    };
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
            if (config.respect_gitignore) {
                for (skip_dirs) |sd| {
                    if (std.mem.eql(u8, entry.basename, sd)) {
                        root_walker.leave(io);
                        skip = true;
                        break;
                    }
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

    const patterns_ptr: ?[]const gitignore.Pattern = if (gitignore_patterns) |p| p.items else null;

    var tasks: std.ArrayList(SubdirTask) = .empty;
    try tasks.ensureTotalCapacity(allocator, subdirs.items.len);
    defer {
        for (tasks.items) |*t| t.entries.deinit(allocator);
        tasks.deinit(allocator);
    }

    var group: std.Io.Group = .init;

    for (subdirs.items) |dir_path| {
        const idx = tasks.items.len;
        tasks.appendAssumeCapacity(.{
            .entries = .empty,
            .allocator = allocator,
            .respect_gitignore = config.respect_gitignore,
            .gitignore_patterns = patterns_ptr,
            .extensions = config.extensions,
            .scan_all = !config.respect_gitignore,
        });
        try group.concurrent(io, walkSubdir, .{ io, &tasks.items[idx], dir_path });
    }
    try group.await(io);

    var result: std.ArrayList(FileEntry) = .empty;
    errdefer {
        for (result.items) |e| allocator.free(e.path);
        result.deinit(allocator);
    }

    for (root_entries.items) |e| {
        try result.append(allocator, e);
    }
    root_entries.clearRetainingCapacity();

    for (tasks.items) |*t| {
        for (t.entries.items) |e| {
            try result.append(allocator, e);
        }
        t.entries.clearRetainingCapacity();
    }

    if (config.root_path) |rp| {
        if (!std.mem.eql(u8, rp, ".")) {
            for (result.items) |*e| {
                const new_path = try std.fmt.allocPrint(allocator, "{s}{c}{s}", .{ rp, std.fs.path.sep, e.path });
                allocator.free(e.path);
                e.path = new_path;
            }
        }
    }

    return try result.toOwnedSlice(allocator);
}

fn walkSubdir(
    io: std.Io,
    task: *SubdirTask,
    dir_path: []const u8,
) std.Io.Cancelable!void {
    const cwd = std.Io.Dir.cwd();
    var dir = cwd.openDir(io, dir_path, .{ .iterate = true }) catch return;
    defer dir.close(io);

    var walker = dir.walk(task.allocator) catch return;
    defer walker.deinit();

    while (walker.next(io) catch null) |entry| {
        if (entry.kind == .directory) {
            if (!task.scan_all) {
                for (skip_dirs) |sd| {
                    if (std.mem.eql(u8, entry.basename, sd)) {
                        walker.leave(io);
                        break;
                    }
                }
            }
            continue;
        }

        if (entry.kind != .file) continue;

        const full_path = std.fs.path.join(task.allocator, &.{ dir_path, entry.path }) catch continue;

        if (task.respect_gitignore) {
            if (task.gitignore_patterns) |patterns| {
                if (gitignore.isIgnored(full_path, patterns)) {
                    task.allocator.free(full_path);
                    continue;
                }
            }
        }

        if (task.extensions) |exts| {
            const ext = std.fs.path.extension(full_path);
            var found = false;
            for (exts) |e| {
                if (std.mem.eql(u8, ext, e)) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                task.allocator.free(full_path);
                continue;
            }
        }

        const language = lang.detect(full_path);
        task.entries.append(task.allocator, .{ .path = full_path, .lang_ptr = language }) catch {
            task.allocator.free(full_path);
        };
    }
}

const AtomicSubdirTask = struct {
    counters: *count.AtomicCounters,
    root_path: []const u8,
    respect_gitignore: bool,
    gitignore_patterns: ?[]const gitignore.Pattern,
    extensions: ?[]const []const u8,
    scan_all: bool,
};

fn walkSubdirAtomic(
    io: std.Io,
    task: *AtomicSubdirTask,
    dir_path: []const u8,
) std.Io.Cancelable!void {
    const cwd = std.Io.Dir.cwd();
    var dir = cwd.openDir(io, dir_path, .{ .iterate = true }) catch return;
    defer dir.close(io);

    var walker = dir.walk(std.heap.smp_allocator) catch return;
    defer walker.deinit();

    while (walker.next(io) catch null) |entry| {
        if (entry.kind == .directory) {
            if (!task.scan_all) {
                for (skip_dirs) |sd| {
                    if (std.mem.eql(u8, entry.basename, sd)) {
                        walker.leave(io);
                        break;
                    }
                }
            }
            continue;
        }

        if (entry.kind != .file) continue;

        const full_path = std.fs.path.join(std.heap.smp_allocator, &.{ task.root_path, dir_path, entry.path }) catch continue;

        if (task.respect_gitignore) {
            if (task.gitignore_patterns) |patterns| {
                if (gitignore.isIgnored(full_path, patterns)) {
                    std.heap.smp_allocator.free(full_path);
                    continue;
                }
            }
        }

        if (task.extensions) |exts| {
            const ext = std.fs.path.extension(full_path);
            var found = false;
            for (exts) |e| {
                if (std.mem.eql(u8, ext, e)) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                std.heap.smp_allocator.free(full_path);
                continue;
            }
        }

        const language = lang.detect(full_path);
        count.countFileMmap(io, full_path, language, task.counters);
        std.heap.smp_allocator.free(full_path);
    }
}

pub fn collectAndCountAtomic(allocator: std.mem.Allocator, io: std.Io, config: Config) !count.AtomicCounters {
    var counters = count.AtomicCounters.init(allocator);

    const cwd = std.Io.Dir.cwd();
    const root_path = config.root_path orelse ".";
    var root = cwd.openDir(io, root_path, .{ .iterate = true }) catch |err| {
        const msg = try std.fmt.allocPrint(allocator, "Cannot open '{s}': {}\n", .{ root_path, err });
        defer allocator.free(msg);
        try std.Io.File.stderr().writeStreamingAll(io, msg);
        counters.deinit();
        return error.CannotOpenDir;
    };
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

    var root_walker = try root.walk(allocator);
    defer root_walker.deinit();

    while (try root_walker.next(io)) |entry| {
        if (entry.kind == .directory) {
            var skip = false;
            if (config.respect_gitignore) {
                for (skip_dirs) |sd| {
                    if (std.mem.eql(u8, entry.basename, sd)) {
                        root_walker.leave(io);
                        skip = true;
                        break;
                    }
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
        const full_path = std.fs.path.join(allocator, &.{ root_path, entry.path }) catch {
            allocator.free(path_copy);
            continue;
        };
        defer allocator.free(full_path);

        count.countFileMmap(io, full_path, language, &counters);
        allocator.free(path_copy);
    }

    const patterns_ptr: ?[]const gitignore.Pattern = if (gitignore_patterns) |p| p.items else null;

    var tasks: std.ArrayList(AtomicSubdirTask) = .empty;
    try tasks.ensureTotalCapacity(allocator, subdirs.items.len);
    defer tasks.deinit(allocator);

    var group: std.Io.Group = .init;

    for (subdirs.items) |dir_path| {
        const idx = tasks.items.len;
        tasks.appendAssumeCapacity(.{
            .counters = &counters,
            .root_path = root_path,
            .respect_gitignore = config.respect_gitignore,
            .gitignore_patterns = patterns_ptr,
            .extensions = config.extensions,
            .scan_all = !config.respect_gitignore,
        });
        try group.concurrent(io, walkSubdirAtomic, .{ io, &tasks.items[idx], dir_path });
    }
    try group.await(io);

    return counters;
}
