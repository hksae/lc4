pub fn isBinary(content: []const u8) bool {
    const check_len: usize = @intCast(@min(content.len, 512));
    var i: usize = 0;
    while (i < check_len) : (i += 1) {
        if (content[i] == 0) return true;
    }
    return false;
}

test "empty is not binary" {
    const std = @import("std");
    try std.testing.expect(!isBinary(""));
}

test "ascii text is not binary" {
    const std = @import("std");
    try std.testing.expect(!isBinary("hello world\nline two\n"));
}

test "null byte is binary" {
    const std = @import("std");
    try std.testing.expect(isBinary("abc\x00def"));
}

test "other control bytes are not detected as binary" {
    const std = @import("std");
    try std.testing.expect(!isBinary("a\x01b\x02c"));
}
