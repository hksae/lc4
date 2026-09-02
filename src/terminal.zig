const std = @import("std");
const builtin = @import("builtin");

extern "kernel32" fn SetConsoleOutputCP(cp: u32) callconv(.c) i32;
extern "kernel32" fn SetConsoleCP(cp: u32) callconv(.c) i32;
extern "kernel32" fn GetStdHandle(nStdHandle: u32) callconv(.c) ?*anyopaque;
extern "kernel32" fn GetConsoleMode(hConsoleHandle: *anyopaque, lpMode: *u32) callconv(.c) i32;
extern "kernel32" fn SetConsoleMode(hConsoleHandle: *anyopaque, dwMode: u32) callconv(.c) i32;

const STD_OUTPUT_HANDLE: u32 = 0xfffffff5;
const ENABLE_VIRTUAL_TERMINAL_PROCESSING: u32 = 0x0004;

pub fn setup() void {
    if (builtin.os.tag != .windows) return;
    _ = SetConsoleOutputCP(65001);
    _ = SetConsoleCP(65001);
    _ = enableVt();
}

fn enableVt() i32 {
    const handle = GetStdHandle(STD_OUTPUT_HANDLE) orelse return 0;
    var mode: u32 = 0;
    if (GetConsoleMode(handle, &mode) == 0) return 0;
    return SetConsoleMode(handle, mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING);
}
