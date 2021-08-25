const std = @import("std");
const String = @import("core").String;
const os = std.os;
const Term = @import("term.zig").Term;

const stdout = std.io.getStdOut().writer();

// TODO: use string to create back buffer for viewing

// create frame
pub fn drawFrame(allocator: *std.mem.Allocator, t: Term) !void {
    var str: String = try String.init(allocator);
    defer str.deinit();
    // draw border
    // top line
    //
    //╭─╮
    //│ │
    //╰─╯
    var i: usize = 0;
    try str.append("╭");
    while (i < (t.w - 2)) : (i += 1) {
        try str.append("─");
    }
    try str.append("╮");

    try str.append("\n\r");

    i = 0;
    // middle
    while (i < (t.h - 2)) : (i += 1) {
        try str.append("│");
        var j: usize = 0;
        while (j < (t.w - 2)) : (j += 1) {
            try str.append(" ");
        }
        try str.append("│");
        try str.append("\n\r");
    }

    // bottom
    i = 0;
    try str.append("╰");
    while (i < (t.w - 2)) : (i += 1) {
        try str.append("─");
    }
    try str.append("╯");

    // print it out
    _ = try stdout.write(str.buf);
}

pub fn main() anyerror!void {
    var t = try Term.init();

    //try drawFrame(std.heap.c_allocator, t);
    while (true) {
        //try t.clear();

        if (t.readKey()) |b| {
            switch (b) {
                27 => {
                    // escape sequence
                    // get next byte ']'
                    _ = t.readKey();
                    // get the actual code
                    try stdout.print("c: {c}\r\n", .{t.readKey().?});
                },
                else => {
                    if (b < 32) {
                        // ctrl, print number
                        try stdout.print("ctrl: {}\r\n", .{b});
                    } else {
                        // just a letter
                        try stdout.print("{c}", .{b});
                    }
                },
                // quit on ^Q
                ctrlKey('q') => break,
            }
        }
    }

    try t.deinit();
}

// helpers
/// util for key code
inline fn ctrlKey(comptime c: comptime_int) u8 {
    return c & 0x1f;
}
