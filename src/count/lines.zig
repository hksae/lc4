const std = @import("std");
const lang = @import("../lang/mod.zig");

pub const LineCount = struct {
    lines: u64 = 0,
    blanks: u64 = 0,
    comments: u64 = 0,
    code: u64 = 0,
};

fn startsWithAt(content: []const u8, index: usize, token: []const u8) bool {
    return token.len != 0 and content.len - index >= token.len and
        std.mem.eql(u8, content[index .. index + token.len], token);
}

/// Counts each physical line exactly once, so `lines == code + comments + blanks`.
/// A line containing any code is code, including code before or after a comment.
/// A whitespace-only line inside an open block comment is a comment, not a blank.
pub fn countLines(content: []const u8, language: *const lang.Language) LineCount {
    var result = LineCount{};
    var block_depth: u32 = 0;
    var line_start: usize = 0;

    while (line_start < content.len) {
        const newline = std.mem.indexOfScalarPos(u8, content, line_start, '\n');
        const line_end = newline orelse content.len;
        var i = line_start;
        var has_code = false;
        var has_comment = false;

        while (i < line_end) {
            if (block_depth > 0) {
                has_comment = true;
                if (language.block_close) |close| {
                    if (startsWithAt(content, i, close)) {
                        block_depth -= 1;
                        i += close.len;
                        continue;
                    }
                }
                if (language.block_nesting) {
                    if (language.block_open) |open| {
                        if (startsWithAt(content, i, open)) {
                            block_depth += 1;
                            i += open.len;
                            continue;
                        }
                    }
                }
                i += 1;
                continue;
            }

            if (content[i] == ' ' or content[i] == '\t' or content[i] == '\r') {
                i += 1;
                continue;
            }

            if (language.line_comment) |line_comment| {
                if (startsWithAt(content, i, line_comment)) {
                    has_comment = true;
                    break;
                }
            }

            if (language.block_open) |open| {
                if (language.block_close != null and startsWithAt(content, i, open)) {
                    has_comment = true;
                    block_depth = 1;
                    i += open.len;
                    continue;
                }
            }

            if (std.mem.indexOfScalar(u8, language.quotes, content[i]) != null) {
                const quote = content[i];
                has_code = true;
                i += 1;
                while (i < line_end) {
                    if (content[i] == '\\' and i + 1 < line_end) {
                        i += 2;
                    } else if (content[i] == quote) {
                        if (i + 1 < line_end and content[i + 1] == quote) {
                            i += 2;
                        } else {
                            i += 1;
                            break;
                        }
                    } else {
                        i += 1;
                    }
                }
                continue;
            }

            has_code = true;
            i += 1;
        }

        result.lines += 1;
        if (has_code) {
            result.code += 1;
        } else if (has_comment or block_depth > 0) {
            result.comments += 1;
        } else {
            result.blanks += 1;
        }

        line_start = if (newline) |index| index + 1 else content.len;
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

test "inline block close with code is one physical code line" {
    const c_lang = lang.Language{
        .name = "C",
        .line_comment = "//",
        .block_open = "/*",
        .block_close = "*/",
        .color = "",
    };
    const r = countLines("/* doc */ int x;\n", &c_lang);
    try std.testing.expectEqual(@as(u64, 1), r.lines);
    try std.testing.expectEqual(@as(u64, 1), r.code);
    try std.testing.expectEqual(r.lines, r.code + r.comments + r.blanks);
}

test "code around inline block comment counts once" {
    const c_lang = lang.Language{
        .name = "C",
        .line_comment = "//",
        .block_open = "/*",
        .block_close = "*/",
        .color = "",
    };
    const r = countLines("int a; /* note */ int b;\n", &c_lang);
    try std.testing.expectEqual(@as(u64, 1), r.lines);
    try std.testing.expectEqual(@as(u64, 1), r.code);
    try std.testing.expectEqual(r.lines, r.code + r.comments + r.blanks);
}

test "C block comments do not nest but Rust block comments do" {
    const c_lang = lang.Language{
        .name = "C",
        .line_comment = "//",
        .block_open = "/*",
        .block_close = "*/",
        .color = "",
    };
    const rust_lang = lang.Language{
        .name = "Rust",
        .line_comment = "//",
        .block_open = "/*",
        .block_close = "*/",
        .block_nesting = true,
        .color = "",
    };
    const source = "/* outer /* inner */\nstill outer\n*/\nint x;\n";

    const c = countLines(source, &c_lang);
    try std.testing.expectEqual(@as(u64, 1), c.comments);
    try std.testing.expectEqual(@as(u64, 3), c.code);
    try std.testing.expectEqual(c.lines, c.code + c.comments + c.blanks);

    const rust = countLines(source, &rust_lang);
    try std.testing.expectEqual(@as(u64, 3), rust.comments);
    try std.testing.expectEqual(@as(u64, 1), rust.code);
    try std.testing.expectEqual(rust.lines, rust.code + rust.comments + rust.blanks);
}

test "whitespace-only lines inside blocks are comments" {
    const c_lang = lang.Language{
        .name = "C",
        .line_comment = "//",
        .block_open = "/*",
        .block_close = "*/",
        .color = "",
    };
    const r = countLines("/*\n   \n*/\n", &c_lang);
    try std.testing.expectEqual(@as(u64, 3), r.comments);
    try std.testing.expectEqual(@as(u64, 0), r.blanks);
    try std.testing.expectEqual(r.lines, r.code + r.comments + r.blanks);
}

test "ordinary quoted strings hide comment markers" {
    const c_lang = lang.Language{
        .name = "C",
        .line_comment = "//",
        .block_open = "/*",
        .block_close = "*/",
        .color = "",
    };
    const r = countLines("const a = \"/* text */\";\nconst b = '// text';\n", &c_lang);
    try std.testing.expectEqual(@as(u64, 2), r.code);
    try std.testing.expectEqual(@as(u64, 0), r.comments);
    try std.testing.expectEqual(r.lines, r.code + r.comments + r.blanks);
}

test "empty content has no physical lines" {
    const r = countLines("", &zig_test_lang);
    try std.testing.expectEqual(@as(u64, 0), r.lines);
    try std.testing.expectEqual(r.lines, r.code + r.comments + r.blanks);
}
