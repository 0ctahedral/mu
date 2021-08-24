const std = @import("std");
const os = std.os;
const Term = @import("term.zig").Term;

const stdout = std.io.getStdOut().writer();


// TODO: use string to create back buffer for viewing

pub fn main() anyerror!void {
    var t = try Term.init();

    while (true) {
        //try t.clear();
        if (t.readKey()) |b| {
            switch (b) {
                // quit on q
                27 => {
                    // escape sequence
                    // get next byte ']'
                    // get the actual code
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
                // now only quits on ^Q
                ctrlKey('q') => break,
                // clear the screen on ^L
                ctrlKey('l') => try t.clear(),
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
