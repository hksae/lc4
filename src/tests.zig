const std = @import("std");

test {
    _ = @import("count/lines.zig");
    _ = @import("count/binary.zig");
    _ = @import("count/mod.zig");
    _ = @import("lang/mod.zig");
    _ = @import("scan/gitignore.zig");
}
