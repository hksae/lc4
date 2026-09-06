const std = @import("std");
const gitignore = @import("gitignore.zig");

/// Compatibility wrapper: scans must never create caches in the target tree.
/// The scanner now uses scoped in-memory patterns directly.
pub fn loadOrParse(allocator: std.mem.Allocator, io: std.Io, root_dir: std.Io.Dir, content: []const u8) !std.ArrayList(gitignore.Pattern) {
    _ = io;
    _ = root_dir;
    return gitignore.parse(allocator, content);
}
