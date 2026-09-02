const std = @import("std");
const lang = @import("../lang/mod.zig");

pub fn printJson(writer: anytype, stats: []const lang.LanguageStat, total: lang.LanguageStat) !void {
    try writer.writeAll("{\n  \"languages\": [\n");

    for (stats, 0..) |s, i| {
        try writer.print(
            \\    {{"name":"{s}","files":{d},"lines":{d},"blanks":{d},"comments":{d},"code":{d}}}
        , .{ s.name, s.files, s.lines, s.blanks, s.comments, s.code });
        if (i < stats.len - 1) try writer.writeAll(",\n");
    }

    try writer.print(
        \\
        \\  ],
        \\  "total": {{"files":{d},"lines":{d},"blanks":{d},"comments":{d},"code":{d}}}
        \\
        \\
    , .{ total.files, total.lines, total.blanks, total.comments, total.code });
}
