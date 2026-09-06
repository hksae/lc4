const std = @import("std");
const lang = @import("../lang/mod.zig");

pub const LineCount = struct {
    lines: u64 = 0,
    blanks: u64 = 0,
    comments: u64 = 0,
    code: u64 = 0,
};

const QuotedString = enum { none, single, double, triple_single, triple_double };
const JsFrame = union(enum) { template, expression: usize };

fn startsWithAt(content: []const u8, index: usize, token: []const u8) bool {
    return token.len != 0 and content.len - index >= token.len and std.mem.eql(u8, content[index .. index + token.len], token);
}

fn escapedAt(content: []const u8, start: usize, index: usize) bool {
    var count: usize = 0;
    var cursor = index;
    while (cursor > start and content[cursor - 1] == '\\') : (cursor -= 1) count += 1;
    return count % 2 == 1;
}

fn tripleDelimiter(state: QuotedString) []const u8 {
    return switch (state) {
        .triple_single => "'''",
        .triple_double => "\"\"\"",
        else => unreachable,
    };
}

/// Counts each physical line exactly once, so `lines == code + comments + blanks`.
/// A line containing any code is code, including code before or after a comment.
/// Python triple-quoted literals, including docstrings, are intentionally code:
/// this lexical counter performs no AST/contextual docstring inference.
/// JavaScript regex literals and JSX, and Python f-string expressions, are outside
/// this focused scanner's grammar.
pub fn countLines(allocator: std.mem.Allocator, content: []const u8, language: *const lang.Language) !LineCount {
    var result = LineCount{};
    var block_depth: u32 = 0;
    var quoted_string: QuotedString = .none;
    var js_frames: std.ArrayList(JsFrame) = .empty;
    defer js_frames.deinit(allocator);
    var line_start: usize = 0;

    while (line_start < content.len) {
        const newline = std.mem.indexOfScalarPos(u8, content, line_start, '\n');
        const line_end = newline orelse content.len;
        const scan_end = if (line_end > line_start and content[line_end - 1] == '\r') line_end - 1 else line_end;
        var i = line_start;
        var has_code = quoted_string != .none or
            (js_frames.items.len != 0 and js_frames.items[js_frames.items.len - 1] == .template);
        var has_comment = false;

        while (i < scan_end) {
            if (quoted_string == .triple_single or quoted_string == .triple_double) {
                has_code = true;
                const delimiter = tripleDelimiter(quoted_string);
                if (startsWithAt(content, i, delimiter) and !escapedAt(content, line_start, i)) {
                    quoted_string = .none;
                    i += delimiter.len;
                } else i += 1;
                continue;
            }

            if (quoted_string == .single or quoted_string == .double) {
                has_code = true;
                const quote: u8 = if (quoted_string == .single) '\'' else '"';
                if (content[i] == '\\') {
                    if (i + 1 < scan_end) i += 2 else i += 1;
                } else if (content[i] == quote) {
                    quoted_string = .none;
                    i += 1;
                } else i += 1;
                continue;
            }

            if (language.string_syntax == .javascript and js_frames.items.len != 0 and js_frames.items[js_frames.items.len - 1] == .template) {
                has_code = true;
                if (content[i] == '\\' and i + 1 < scan_end) {
                    i += 2;
                } else if (startsWithAt(content, i, "${")) {
                    try js_frames.append(allocator, .{ .expression = 0 });
                    i += 2;
                } else if (content[i] == '`') {
                    _ = js_frames.pop();
                    i += 1;
                } else i += 1;
                continue;
            }

            if (block_depth > 0) {
                has_comment = true;
                if (language.block_close) |close| if (startsWithAt(content, i, close)) {
                    block_depth -= 1;
                    i += close.len;
                    continue;
                };
                if (language.block_nesting) if (language.block_open) |open| if (startsWithAt(content, i, open)) {
                    block_depth += 1;
                    i += open.len;
                    continue;
                };
                i += 1;
                continue;
            }

            if (content[i] == ' ' or content[i] == '\t') {
                i += 1;
                continue;
            }
            if (language.line_comment) |token| if (startsWithAt(content, i, token)) {
                has_comment = true;
                break;
            };
            if (language.block_open) |open| if (language.block_close != null and startsWithAt(content, i, open)) {
                has_comment = true;
                block_depth = 1;
                i += open.len;
                continue;
            };

            if (language.string_syntax == .javascript and js_frames.items.len != 0) switch (js_frames.items[js_frames.items.len - 1]) {
                .expression => |depth| {
                    if (content[i] == '{') {
                        js_frames.items[js_frames.items.len - 1].expression = depth + 1;
                        has_code = true;
                        i += 1;
                        continue;
                    }
                    if (content[i] == '}') {
                        has_code = true;
                        if (depth == 0) _ = js_frames.pop() else js_frames.items[js_frames.items.len - 1].expression = depth - 1;
                        i += 1;
                        continue;
                    }
                },
                .template => unreachable,
            };

            if ((language.string_syntax == .python or language.string_syntax == .javascript) and
                (content[i] == '\'' or content[i] == '"'))
            {
                has_code = true;
                const quote = content[i];
                if (language.string_syntax == .python and i + 2 < scan_end and content[i + 1] == quote and content[i + 2] == quote) {
                    quoted_string = if (quote == '\'') .triple_single else .triple_double;
                    i += 3;
                } else {
                    quoted_string = if (quote == '\'') .single else .double;
                    i += 1;
                }
                continue;
            }
            if (language.string_syntax == .javascript and content[i] == '`') {
                has_code = true;
                try js_frames.append(allocator, .template);
                i += 1;
                continue;
            }

            if (std.mem.indexOfScalar(u8, language.quotes, content[i]) != null) {
                const quote = content[i];
                has_code = true;
                i += 1;
                while (i < scan_end) {
                    if (content[i] == '\\' and i + 1 < scan_end) i += 2 else if (content[i] == quote) {
                        if (i + 1 < scan_end and content[i + 1] == quote) i += 2 else {
                            i += 1;
                            break;
                        }
                    } else i += 1;
                }
                continue;
            }
            has_code = true;
            i += 1;
        }

        if ((quoted_string == .single or quoted_string == .double) and
            (scan_end == line_start or content[scan_end - 1] != '\\' or !escapedAt(content, line_start, scan_end))) quoted_string = .none;

        result.lines += 1;
        if (has_code) result.code += 1 else if (has_comment or block_depth > 0) result.comments += 1 else result.blanks += 1;
        line_start = if (newline) |index| index + 1 else content.len;
    }
    return result;
}

const zig_test_lang = lang.Language{ .name = "Zig", .line_comment = "//", .block_open = "//!", .color = "" };
fn countTest(source: []const u8, language: *const lang.Language) !LineCount {
    return countLines(std.testing.allocator, source, language);
}
fn expectInvariant(r: LineCount) !void {
    try std.testing.expectEqual(r.lines, r.code + r.comments + r.blanks);
}

test "basic zig counting" {
    const r = try countTest("// header\nconst x = 1;\n// comment\nconst y = 2;\n\nfn main() void {\n    // inner\n    _ = x + y;\n}\n", &zig_test_lang);
    try std.testing.expectEqual(@as(u64, 9), r.lines);
    try std.testing.expectEqual(@as(u64, 1), r.blanks);
    try std.testing.expectEqual(@as(u64, 3), r.comments);
    try std.testing.expectEqual(@as(u64, 5), r.code);
}

test "C block comments and Rust nesting remain unchanged" {
    const c = lang.Language{ .name = "C", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "" };
    const rust = lang.Language{ .name = "Rust", .line_comment = "//", .block_open = "/*", .block_close = "*/", .block_nesting = true, .color = "" };
    const source = "/* outer /* inner */\nstill outer\n*/\nint x;\n";
    const cr = try countTest(source, &c);
    const rr = try countTest(source, &rust);
    try std.testing.expectEqual(@as(u64, 1), cr.comments);
    try std.testing.expectEqual(@as(u64, 3), cr.code);
    try std.testing.expectEqual(@as(u64, 3), rr.comments);
    try std.testing.expectEqual(@as(u64, 1), rr.code);
    try expectInvariant(cr);
    try expectInvariant(rr);
}

test "ordinary quoted strings hide comment markers" {
    const c = lang.Language{ .name = "C", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "" };
    const r = try countTest("const a = \"/* text */\";\nconst b = '// text';\n", &c);
    try std.testing.expectEqual(@as(u64, 2), r.code);
    try std.testing.expectEqual(@as(u64, 0), r.comments);
    try expectInvariant(r);
}

test "Python triple strings prefixes CRLF empty bodies and comments" {
    const source = "# before\r\nx = fr\"\"\"first # text\r\n\r\nlast \\\"\"\" still body\r\ndone\"\"\" # after\r\ny = rb'''\r\nbody\r\n''' + suffix\r\n";
    const r = try countTest(source, lang.detect("sample.py"));
    try std.testing.expectEqual(@as(u64, 8), r.lines);
    try std.testing.expectEqual(@as(u64, 7), r.code);
    try std.testing.expectEqual(@as(u64, 1), r.comments);
    try std.testing.expectEqual(@as(u64, 0), r.blanks);
    try expectInvariant(r);
}

test "Python docstrings are code and closing delimiter exposes following comment" {
    const r = try countTest("\"\"\"docs\n\nbody\n\"\"\" # real\n# only\n", lang.detect("sample.py"));
    try std.testing.expectEqual(@as(u64, 4), r.code);
    try std.testing.expectEqual(@as(u64, 1), r.comments);
    try std.testing.expectEqual(@as(u64, 0), r.blanks);
    try expectInvariant(r);
}

test "Python escape parity closing groups and escaped newline continuation" {
    const source = "a = \"one \\\n# still string\" # comment\nb = '''odd \\''' body\neven \\\\''' # closes\n# isolated\n";
    const r = try countTest(source, lang.detect("sample.py"));
    try std.testing.expectEqual(@as(u64, 4), r.code);
    try std.testing.expectEqual(@as(u64, 1), r.comments);
    try expectInvariant(r);
}

test "JavaScript templates persist and escaped template markers stay raw" {
    const source = "// before\nconst x = `first\n\nescaped \\` and \\${raw}\nlast`; // after\n// isolated\n";
    const r = try countTest(source, lang.detect("sample.js"));
    try std.testing.expectEqual(@as(u64, 4), r.code);
    try std.testing.expectEqual(@as(u64, 2), r.comments);
    try std.testing.expectEqual(@as(u64, 0), r.blanks);
    try expectInvariant(r);
}

test "JavaScript nested template expressions track braces quotes and comments" {
    const source = "const x = `outer ${fn({ key: \"}\", nested: `in ${value}` })\n/* expression comment } */ + more}\ntail`; // done\n// separate\n";
    const r = try countTest(source, lang.detect("sample.tsx"));
    try std.testing.expectEqual(@as(u64, 3), r.code);
    try std.testing.expectEqual(@as(u64, 1), r.comments);
    try expectInvariant(r);
}

test "lexer state is isolated between files" {
    const open = try countTest("x = '''open\n", lang.detect("sample.py"));
    const separate = try countTest("# comment\n", lang.detect("sample.py"));
    try std.testing.expectEqual(@as(u64, 1), open.code);
    try std.testing.expectEqual(@as(u64, 1), separate.comments);
    try std.testing.expectEqual(@as(u64, 0), separate.code);
}

test "block comment handling and whitespace body lines" {
    const c = lang.Language{ .name = "C", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "" };
    const r = try countTest("int a;\n/* block\n   \n*/\nint b;\n", &c);
    try std.testing.expectEqual(@as(u64, 5), r.lines);
    try std.testing.expectEqual(@as(u64, 3), r.comments);
    try std.testing.expectEqual(@as(u64, 2), r.code);
    try std.testing.expectEqual(@as(u64, 0), r.blanks);
    try expectInvariant(r);
}

test "no trailing newline" {
    const r = try countTest("a\nb\nc", &zig_test_lang);
    try std.testing.expectEqual(@as(u64, 3), r.lines);
    try std.testing.expectEqual(@as(u64, 3), r.code);
    try expectInvariant(r);
}

test "inline block close with code is one physical code line" {
    const c = lang.Language{ .name = "C", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "" };
    const r = try countTest("/* doc */ int x;\n", &c);
    try std.testing.expectEqual(@as(u64, 1), r.lines);
    try std.testing.expectEqual(@as(u64, 1), r.code);
    try expectInvariant(r);
}

test "code around inline block comment counts once" {
    const c = lang.Language{ .name = "C", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "" };
    const r = try countTest("int a; /* note */ int b;\n", &c);
    try std.testing.expectEqual(@as(u64, 1), r.lines);
    try std.testing.expectEqual(@as(u64, 1), r.code);
    try expectInvariant(r);
}

test "JavaScript interpolation comment-only and blank lines are not string body" {
    const source = "const s = `raw ${\n/* comment\n\nend */\n\nvalue\n} raw`;\n// outside\n";
    const r = try countTest(source, lang.detect("sample.js"));
    try std.testing.expectEqual(@as(u64, 8), r.lines);
    try std.testing.expectEqual(@as(u64, 3), r.code);
    try std.testing.expectEqual(@as(u64, 4), r.comments);
    try std.testing.expectEqual(@as(u64, 1), r.blanks);
    try expectInvariant(r);
}

test "JavaScript escaped-newline quoted strings retain interpolation context" {
    const source = "const s = `raw ${\"continued\\\r\n// } string text\"\r\n} tail`;\r\n// outside\r\n";
    const r = try countTest(source, lang.detect("sample.ts"));
    try std.testing.expectEqual(@as(u64, 4), r.lines);
    try std.testing.expectEqual(@as(u64, 3), r.code);
    try std.testing.expectEqual(@as(u64, 1), r.comments);
    try expectInvariant(r);
}

fn nestedTemplatesAllocationTest(allocator: std.mem.Allocator) !void {
    const prefix = "const s = `";
    const depth = 80;
    var source: [prefix.len + depth * 5 + 7]u8 = undefined;
    @memcpy(source[0..prefix.len], prefix);
    var offset: usize = prefix.len;
    for (0..depth) |_| {
        @memcpy(source[offset..][0..3], "${`");
        offset += 3;
    }
    @memcpy(source[offset..][0..4], "body");
    offset += 4;
    for (0..depth) |_| {
        @memcpy(source[offset..][0..2], "`}");
        offset += 2;
    }
    @memcpy(source[offset..][0..3], "`;\n");
    const r = try countLines(allocator, &source, lang.detect("sample.js"));
    try std.testing.expectEqual(@as(u64, 1), r.lines);
    try std.testing.expectEqual(@as(u64, 1), r.code);
}

test "nested templates exceed small fixed stacks and clean up allocation failures" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, nestedTemplatesAllocationTest, .{});
}

test "empty content has no physical lines" {
    const r = try countTest("", &zig_test_lang);
    try std.testing.expectEqual(@as(u64, 0), r.lines);
    try expectInvariant(r);
}
