const std = @import("std");
const lang = @import("../lang/mod.zig");
const count = @import("../count/mod.zig");
const colors = @import("colors.zig");

pub fn render(allocator: std.mem.Allocator, results: []const count.FileResult, stats: []const lang.LanguageStat) ![]u8 {
    var aw = std.Io.Writer.Allocating.init(allocator);
    const w = &aw.writer;

    for (stats) |s| {
        try w.print("\n {s}{s}{s}\n", .{ s.color, s.name, colors.reset });

        for (results) |r| {
            if (r.is_binary) continue;
            if (!std.mem.eql(u8, r.lang_ptr.name, s.name)) continue;

            try w.print("   {s}{s}{s}", .{ colors.dim, r.path, colors.reset });
            var buf: [16]u8 = undefined;
            const num_str = std.fmt.bufPrint(&buf, "{d}", .{r.line_count.lines}) catch continue;
            var pad_count: usize = 0;
            while (pad_count + num_str.len < 8) : (pad_count += 1) {
                try w.writeAll(" ");
            }
            try w.print("{s}{s}{s}\n", .{ colors.dim, num_str, colors.reset });
        }
    }

    return aw.toOwnedSlice();
}
