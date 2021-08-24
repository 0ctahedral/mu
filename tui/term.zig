const std = @import("std");
const String = @import("core").String;
const os = std.os;
const STDIN = 0;
const stdout = std.io.getStdOut().writer();

/// Interaction with terminal using escape codes
pub const Term = struct {
    /// Original termios
    og: os.termios,
    w: u16 = 0,
    h: u16 = 0,
    cache: String = undefined,

    const Self = @This();
    const stdin = std.io.getStdIn();

    pub fn init() !Self {
        var t = Self{
            .og = try os.tcgetattr(STDIN),
        };

        // enable raw mode //
        // first get the original termios
        // set raw mode
        var raw = t.og;
        // local flags
        // turn off echo, get bytes one at a time, turn off signals (int and stp)
        // turn off ^V and ^O
        raw.lflag &= ~(@as(u16, os.ECHO | os.ICANON | os.ISIG | os.IEXTEN));
        // turn off software flow control (diables ^S and ^Q), and carriage returns
        raw.iflag &= ~(@as(u16, os.IXON | os.ICRNL | os.BRKINT | os.INPCK | os.ISTRIP));
        // set 8 bits per byte
        raw.cflag |= os.CS8;
        // turn off output processing
        raw.oflag &= ~(@as(u16, os.OPOST));

        // add a timout
        raw.cc[os.VMIN] = 0;
        raw.cc[os.VTIME] = 1;

        // flush changes
        try os.tcsetattr(STDIN, os.TCSA.FLUSH, raw);

        // update size
        try t.updateSize();

        try stdout.print("size: {}x{}\r\n", .{ t.w, t.h });

        return t;
    }

    pub fn deinit(self: Self) !void {
        try self.clear();
        // restore original settings
        try os.tcsetattr(STDIN, os.TCSA.FLUSH, self.og);
    }

    /// Attempt to read a key from stdin
    /// a key may be more than one byte
    pub fn readKey(self: Self) ?u8 {
        var b: u8 = 0;
        b = stdin.reader().readByte() catch |err| {
            return null;
        };

        return b;
    }

    /// get the size of the terminal
    pub fn updateSize(self: *Self) !void {
        //TODO: add the 'hard' way

        // for now, ioctl gang!
        var wsz: os.winsize = undefined;
        // test for failure
        if (std.c.ioctl(@bitCast(usize, @as(isize, 0)), os.TIOCGWINSZ, @ptrToInt(&wsz)) != 0) {
            return error.WinsizeSyscallFailure;
        }

        self.w = wsz.ws_col;
        self.h = wsz.ws_row;
    }

    /// Clear the screen
    pub fn clear(self: Self) !void {
        // esc sequence: 27[2J
        // erase screen arg ^
        // 0: clear from cursor to end
        // 1: clear from top to cursor
        // 2: clear whole screen
        _ = try stdout.write("\x1b[2J");
        // move cursor to top left corner
        _ = try stdout.write("\x1b[H");
    }
};
