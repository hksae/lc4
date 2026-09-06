const std = @import("std");

pub const SortBy = enum {
    lines,
    files,
    code,
    name,
};

pub const Config = struct {
    respect_gitignore: bool = true,
    verbose: bool = false,
    include_binaries: bool = false,
    json_output: bool = false,
    no_color: bool = false,
    short_output: bool = false,
    extensions: ?[]const []const u8 = null,
    root_path: ?[]const u8 = null,
    sort_by: SortBy = .lines,
    top_n: ?u32 = null,

    pub fn deinit(self: *Config, allocator: std.mem.Allocator) void {
        if (self.root_path) |path| allocator.free(path);
        if (self.extensions) |extensions| {
            for (extensions) |extension| allocator.free(extension);
            allocator.free(extensions);
        }
        self.* = .{};
    }
};
