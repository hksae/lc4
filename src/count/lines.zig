const std = @import("std");
const lang = @import("../lang/mod.zig");

pub const LineCount = struct {
    lines: u64 = 0,
    blanks: u64 = 0,
    comments: u64 = 0,
    code: u64 = 0,
};

pub fn countLines(content: []const u8, language: *const lang.Language) LineCount {
    var result = LineCount{};
    var in_block = false;
    var i: usize = 0;
    const len = content.len;

    while (i < len) {
        result.lines += 1;

        while (i < len and (content[i] == ' ' or content[i] == '\t' or content[i] == '\r')) : (i += 1) {}

        if (i >= len or content[i] == '\n') {
            result.blanks += 1;
            if (i < len) i += 1;
            continue;
        }

        if (in_block) {
            result.comments += 1;
            if (language.block_close) |bc| {
                if (len - i >= bc.len and std.mem.eql(u8, content[i .. i + bc.len], bc)) {
                    in_block = false;
                }
            }
            while (i < len and content[i] != '\n') : (i += 1) {}
            if (i < len) i += 1;
            continue;
        }

        if (language.block_open) |bo| {
            if (len - i >= bo.len and std.mem.eql(u8, content[i .. i + bo.len], bo)) {
                result.comments += 1;
                if (language.block_close) |bc| {
                    const line_end = std.mem.indexOfScalar(u8, content[i..], '\n') orelse len;
                    if (std.mem.indexOf(u8, content[i .. i + line_end], bc) == null) {
                        in_block = true;
                    }
                }
                while (i < len and content[i] != '\n') : (i += 1) {}
                if (i < len) i += 1;
                continue;
            }
        }

        if (language.line_comment) |lc| {
            if (len - i >= lc.len and std.mem.eql(u8, content[i .. i + lc.len], lc)) {
                result.comments += 1;
                while (i < len and content[i] != '\n') : (i += 1) {}
                if (i < len) i += 1;
                continue;
            }
        }

        result.code += 1;
        while (i < len and content[i] != '\n') : (i += 1) {}
        if (i < len) i += 1;
    }

    return result;
}

const zig_test_lang = lang.Language{
    .name = "Zig",
    .line_comment = "//",
    .block_open = "//!",
    .block_close = null,
    .color = "",
};

test "basic zig counting" {
    const source =
        "// header\n" ++
        "const x = 1;\n" ++
        "// comment\n" ++
        "const y = 2;\n" ++
        "\n" ++
        "fn main() void {\n" ++
        "    // inner\n" ++
        "    _ = x + y;\n" ++
        "}\n";
    const r = countLines(source, &zig_test_lang);
    try std.testing.expectEqual(@as(u64, 9), r.lines);
    try std.testing.expectEqual(@as(u64, 1), r.blanks);
    try std.testing.expectEqual(@as(u64, 3), r.comments);
    try std.testing.expectEqual(@as(u64, 5), r.code);
}

test "block comment handling" {
    const c_lang = lang.Language{
        .name = "C",
        .line_comment = "//",
        .block_open = "/*",
        .block_close = "*/",
        .color = "",
    };
    const source =
        "int a;\n" ++
        "/* block\n" ++
        "   continues\n" ++
        "*/\n" ++
        "int b;\n";
    const r = countLines(source, &c_lang);
    try std.testing.expectEqual(@as(u64, 5), r.lines);
    try std.testing.expectEqual(@as(u64, 0), r.blanks);
    try std.testing.expectEqual(@as(u64, 3), r.comments);
    try std.testing.expectEqual(@as(u64, 2), r.code);
}

test "no trailing newline" {
    const source = "a\nb\nc";
    const r = countLines(source, &zig_test_lang);
    try std.testing.expectEqual(@as(u64, 3), r.lines);
    try std.testing.expectEqual(@as(u64, 3), r.code);
}
