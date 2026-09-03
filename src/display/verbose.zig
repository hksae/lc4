const std = @import("std");
const lang = @import("../lang/mod.zig");
const count = @import("../count/mod.zig");
const colors = @import("colors.zig");

pub fn render(allocator: std.mem.Allocator, results: []const count.FileResult, stats: []const lang.LanguageStat) ![]u8 {
    var aw = std.Io.Writer.Allocating.init(allocator);
    const w = &aw.writer;

    for (stats) |s| {
        try w.print("\n {s}{s}{s}\n", .{ s.color, s.name, colors.reset });

        var max_path_len: usize = 0;
        for (results) |r| {
            if (r.is_binary) continue;
            if (!std.mem.eql(u8, r.lang_ptr.name, s.name)) continue;
            if (r.path.len > max_path_len) max_path_len = r.path.len;
        }

        for (results) |r| {
            if (r.is_binary) continue;
            if (!std.mem.eql(u8, r.lang_ptr.name, s.name)) continue;

            try w.writeAll("   ");
            try w.writeAll(colors.dim);
            try writePadded(w, r.path, max_path_len);
            try w.writeAll(colors.reset);

            var buf: [16]u8 = undefined;
            const num_str = std.fmt.bufPrint(&buf, "{d}", .{r.line_count.lines}) catch continue;
            try w.writeAll("  ");
            var i: usize = num_str.len;
            while (i < 6) : (i += 1) {
                try w.writeAll(" ");
            }
            try w.writeAll(num_str);
            try w.writeAll(colors.reset);
            try w.writeAll("\n");
        }
    }

    return aw.toOwnedSlice();
}

fn writePadded(w: *std.Io.Writer, text: []const u8, width: usize) !void {
    try w.writeAll(text);
    var i: usize = text.len;
    while (i < width) : (i += 1) {
        try w.writeAll(" ");
    }
}
