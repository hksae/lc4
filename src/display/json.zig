const std = @import("std");
const lang = @import("../lang/mod.zig");

pub fn render(allocator: std.mem.Allocator, stats: []const lang.LanguageStat, total: lang.LanguageStat) ![]u8 {
    var aw = std.Io.Writer.Allocating.init(allocator);
    const w = &aw.writer;

    try w.writeAll("{\n  \"languages\": [\n");

    for (stats, 0..) |s, i| {
        try w.writeAll("    {\"name\":\"");
        try w.writeAll(s.name);
        try w.writeAll("\",\"files\":");
        try printNum(w, s.files);
        try w.writeAll(",\"lines\":");
        try printNum(w, s.lines);
        try w.writeAll(",\"blanks\":");
        try printNum(w, s.blanks);
        try w.writeAll(",\"comments\":");
        try printNum(w, s.comments);
        try w.writeAll(",\"code\":");
        try printNum(w, s.code);
        try w.writeAll("}");
        if (i < stats.len - 1) try w.writeAll(",");
        try w.writeAll("\n");
    }

    try w.writeAll("  ],\n");
    try w.writeAll("  \"total\": {\"files\":");
    try printNum(w, total.files);
    try w.writeAll(",\"lines\":");
    try printNum(w, total.lines);
    try w.writeAll(",\"blanks\":");
    try printNum(w, total.blanks);
    try w.writeAll(",\"comments\":");
    try printNum(w, total.comments);
    try w.writeAll(",\"code\":");
    try printNum(w, total.code);
    try w.writeAll("}\n}\n");

    return aw.toOwnedSlice();
}

fn printNum(w: *std.Io.Writer, num: u64) !void {
    var buf: [32]u8 = undefined;
    const str = std.fmt.bufPrint(&buf, "{d}", .{num}) catch return;
    try w.writeAll(str);
}
