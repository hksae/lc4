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
        const nl = std.mem.indexOfScalar(u8, remaining, '\n');
        const line = if (nl) |pos| remaining[0..pos] else remaining;
        remaining = if (nl) |pos| remaining[pos + 1 ..] else &[0]u8{};

        result.lines += 1;
        const trimmed = std.mem.trimLeft(u8, line, " \t\r");

        if (in_block) {
            result.comments += 1;
            if (language.block_close) |bc| {
                if (std.mem.indexOf(u8, trimmed, bc) != null) {
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
                    if (std.mem.indexOf(u8, trimmed[bo.len..], bc) == null) {
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
