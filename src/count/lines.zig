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
    var remaining = content;

    while (remaining.len > 0) {
        const nl = std.mem.findScalar(u8, remaining, '\n');
        const line = if (nl) |pos| remaining[0..pos] else remaining;
        remaining = if (nl) |pos| remaining[pos + 1 ..] else &[0]u8{};

        result.lines += 1;
        const trimmed = std.mem.trimStart(u8, line, " \t\r");

        if (in_block) {
            result.comments += 1;
            if (language.block_close) |bc| {
                if (std.mem.find(u8, trimmed, bc) != null) {
                    in_block = false;
                }
            }
            continue;
        }

        if (trimmed.len == 0) {
            result.blanks += 1;
            continue;
        }

        if (language.block_open) |bo| {
            if (std.mem.startsWith(u8, trimmed, bo)) {
                result.comments += 1;
                if (language.block_close) |bc| {
                    if (std.mem.find(u8, trimmed[bo.len..], bc) == null) {
                        in_block = true;
                    }
                }
                continue;
            }
        }

        if (language.line_comment) |lc| {
            if (std.mem.startsWith(u8, trimmed, lc)) {
                result.comments += 1;
                continue;
            }
        }

        result.code += 1;
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
