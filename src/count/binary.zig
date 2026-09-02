pub fn isBinary(content: []const u8) bool {
    const check_len: usize = @intCast(@min(content.len, 512));
    var i: usize = 0;
    while (i < check_len) : (i += 1) {
        if (content[i] == 0) return true;
    }
    return false;
}
