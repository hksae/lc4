pub const Config = struct {
    respect_gitignore: bool = true,
    verbose: bool = false,
    include_binaries: bool = false,
    json_output: bool = false,
    no_color: bool = false,
    extensions: ?[]const []const u8 = null,
    root_path: ?[]const u8 = null,
    sort_by: []const u8 = "lines",
    top_n: ?u32 = null,
};
