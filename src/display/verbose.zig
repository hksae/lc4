const std = @import("std");
const lang = @import("../lang/mod.zig");
const count = @import("../count/mod.zig");
const colors = @import("colors.zig");

pub fn printVerbose(writer: anytype, results: []const count.FileResult, stats: []const lang.LanguageStat) !void {
    for (stats) |s| {
        try writer.print("\n {s}{s}{s}\n", .{ s.color, s.name, colors.reset });

        for (results) |r| {
            if (r.is_binary) continue;
            if (!std.mem.eql(u8, r.lang_ptr.name, s.name)) continue;

            const base = std.fs.path.basename(r.path);
            try writer.print("   {s}{s}{s}", .{ colors.dim, r.path, colors.reset });
            var buf: [16]u8 = undefined;
            const num_str = std.fmt.bufPrint(&buf, "{d}", .{r.line_count.lines}) catch continue;
            var pad: usize = 0;
            while (pad + num_str.len < 8) : (pad += 1) {
                try writer.writeAll(" ");
            }
            try writer.print("{s}{s}{s}\n", .{ colors.dim, num_str, colors.reset });
            _ = base;
        }
    }
}
