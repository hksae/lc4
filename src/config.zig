pub const Config = struct {
    respect_gitignore: bool = true,
    verbose: bool = false,
    include_binaries: bool = false,
    json_output: bool = false,
    extensions: ?[]const []const u8 = null,
};
