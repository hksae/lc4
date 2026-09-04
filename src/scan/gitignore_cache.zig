const std = @import("std");
const gitignore = @import("gitignore.zig");

pub fn loadOrParse(allocator: std.mem.Allocator, io: std.Io, root_dir: std.Io.Dir, content: []const u8) !std.ArrayList(gitignore.Pattern) {
    const mtime = getFileMtime(io, root_dir, ".gitignore") orelse return gitignore.parse(allocator, content);

    root_dir.createDirPath(io, ".zig-cache") catch {};

    const meta_path = ".zig-cache/gitignore_mtime";
    const cache_path = ".zig-cache/gitignore_cache";

    const meta_bytes = root_dir.readFileAlloc(io, meta_path, allocator, .limited(256)) catch null;
    if (meta_bytes) |bytes| {
        defer allocator.free(bytes);
        if (bytes.len >= mtime_size) {
            const cached_mtime = readMtime(bytes[0..12]);
            if (cached_mtime == mtime) {
                const cache_bytes = root_dir.readFileAlloc(io, cache_path, allocator, .limited(16 * 1024 * 1024)) catch null;
                if (cache_bytes) |cb| {
                    defer allocator.free(cb);
                    if (deserializePatterns(allocator, cb)) |patterns| {
                        return patterns;
                    }
                }
            }
        }
    }

    const patterns = try gitignore.parse(allocator, content);

    const serialized = serializePatterns(allocator, patterns.items) catch return patterns;
    defer allocator.free(serialized);

    root_dir.writeFile(io, .{ .sub_path = cache_path, .data = serialized }) catch {};
    var mtime_buf: [mtime_size]u8 = undefined;
    writeMtime(&mtime_buf, mtime);
    root_dir.writeFile(io, .{ .sub_path = meta_path, .data = &mtime_buf }) catch {};

    return patterns;
}

fn getFileMtime(io: std.Io, dir: std.Io.Dir, path: []const u8) ?i96 {
    const file = dir.openFile(io, path, .{}) catch return null;
    defer file.close(io);
    const stat = file.stat(io) catch return null;
    return stat.mtime.nanoseconds;
}

const mtime_size = 12;

fn readMtime(bytes: []const u8) i96 {
    const lo: u64 = @bitCast(bytes[0..8].*);
    const hi: u32 = @bitCast(bytes[8..12].*);
    const unsigned = @as(u96, lo) | (@as(u96, hi) << 64);
    return @bitCast(unsigned);
}

fn writeMtime(buf: *[mtime_size]u8, ts: i96) void {
    const unsigned: u96 = @bitCast(ts);
    buf[0..8].* = @bitCast(@as(u64, @truncate(unsigned)));
    buf[8..12].* = @bitCast(@as(u32, @truncate(unsigned >> 64)));
}

fn serializePatterns(allocator: std.mem.Allocator, patterns: []const gitignore.Pattern) ![]u8 {
    var aw = std.Io.Writer.Allocating.init(allocator);
    const w = &aw.writer;

    const count_val: u64 = patterns.len;
    try w.writeAll(std.mem.asBytes(&count_val));

    for (patterns) |pat| {
        const len_val: u32 = @intCast(pat.text.len);
        try w.writeAll(std.mem.asBytes(&len_val));
        try w.writeAll(pat.text);
        try w.writeByte(if (pat.negated) 1 else 0);
        try w.writeByte(if (pat.anchored) 1 else 0);
    }

    return aw.toOwnedSlice();
}

fn deserializePatterns(allocator: std.mem.Allocator, data: []const u8) ?std.ArrayList(gitignore.Pattern) {
    if (data.len < @sizeOf(u64)) return null;

    const count_val: u64 = @bitCast(data[0..@sizeOf(u64)].*);
    var pos: usize = @sizeOf(u64);

    var patterns: std.ArrayList(gitignore.Pattern) = .empty;
    errdefer {
        for (patterns.items) |pat| allocator.free(pat.text);
        patterns.deinit(allocator);
    }

    for (0..count_val) |_| {
        if (pos + @sizeOf(u32) > data.len) return null;
        const text_len: u32 = @bitCast(data[pos..][0..@sizeOf(u32)].*);
        pos += @sizeOf(u32);

        if (pos + text_len + 2 > data.len) return null;
        const text = allocator.dupe(u8, data[pos..][0..text_len]) catch return null;
        pos += text_len;

        const negated = data[pos] != 0;
        pos += 1;
        const anchored = data[pos] != 0;
        pos += 1;

        patterns.append(allocator, .{
            .text = text,
            .negated = negated,
            .anchored = anchored,
        }) catch return null;
    }

    return patterns;
}
