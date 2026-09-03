const std = @import("std");
const lang = @import("../lang/mod.zig");
const colors = @import("colors.zig");

pub fn render(allocator: std.mem.Allocator, stats: []const lang.LanguageStat, total: lang.LanguageStat) ![]u8 {
    var aw = std.Io.Writer.Allocating.init(allocator);
    const w = &aw.writer;

    var name_width: usize = 8;
    for (stats) |s| {
        if (s.name.len > name_width) name_width = s.name.len;
    }
    if (total.name.len > name_width) name_width = total.name.len;

    const col_w = [_]usize{ 6, 8, 8, 10, 8 };

    try w.writeAll("\n");
    try w.writeAll("│ ");
    try writePadded(w, "Language", name_width);
    try w.writeAll(" │");
    try w.writeAll(" Files │");
    try w.writeAll(" Lines  │");
    try w.writeAll(" Blanks  │");
    try w.writeAll(" Comments │");
    try w.writeAll(" Code  │");
    try w.writeAll("\n");

    try printSep(w, name_width, col_w, "├", "┼", "┤");

    for (stats) |s| {
        try printRow(w, s.color, s.name, name_width, .{ s.files, s.lines, s.blanks, s.comments, s.code }, col_w);
    }

    try printSep(w, name_width, col_w, "├", "┼", "┤");
    try printRow(w, colors.bold, total.name, name_width, .{ total.files, total.lines, total.blanks, total.comments, total.code }, col_w);
    try printSep(w, name_width, col_w, "└", "┴", "┘");
    try w.writeAll("\n");

    return aw.toOwnedSlice();
}

fn printSep(w: *std.Io.Writer, name_width: usize, col_w: [5]usize, left: []const u8, mid: []const u8, right: []const u8) !void {
    try w.writeAll(left);
    var i: usize = 0;
    while (i < name_width + 2) : (i += 1) try w.writeAll("─");
    inline for (col_w) |cw| {
        try w.writeAll(mid);
        i = 0;
        while (i < cw + 2) : (i += 1) try w.writeAll("─");
    }
    try w.writeAll(right);
    try w.writeAll("\n");
}

fn printRow(w: *std.Io.Writer, color: []const u8, name: []const u8, name_width: usize, vals: [5]u64, col_w: [5]usize) !void {
    try w.writeAll("│ ");
    try w.writeAll(color);
    try writePadded(w, name, name_width);
    try w.writeAll(colors.reset);
    try w.writeAll(" │");
    inline for (0..5) |i| {
        try w.writeAll(" ");
        try printNumRight(w, vals[i], col_w[i]);
        try w.writeAll(" │");
    }
    try w.writeAll("\n");
}

fn printNumRight(w: *std.Io.Writer, num: u64, width: usize) !void {
    var buf: [32]u8 = undefined;
    const str = std.fmt.bufPrint(&buf, "{d}", .{num}) catch return;
    var i: usize = str.len;
    while (i < width) : (i += 1) {
        try w.writeAll(" ");
    }
    try w.writeAll(str);
}

fn writePadded(w: *std.Io.Writer, text: []const u8, width: usize) !void {
    try w.writeAll(text);
    var i: usize = text.len;
    while (i < width) : (i += 1) {
        try w.writeAll(" ");
    }
}
