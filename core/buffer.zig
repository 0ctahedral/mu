const std = @import("std");
const String = @import("core.zig").String;

const PAGESIZE = 4096;

/// A buffer is a large collection of characters
/// this means it could be a mapping to a "real" file on disk
/// or data only inside a process
pub const Buffer = struct {
    
    const Self = @This();

    data: String,

    /// Creates a buffer
    pub fn init(allocator: *std.mem.Allocator) !Self {
        return Self{
            .data = try String.initSize(allocator, PAGESIZE),
        };
    }

    pub fn deinit(self: Self) void {
        self.data.deinit();
    }
};

/// A block represents a section of a buffer
/// This can be either in memory, in which case,
/// it contains a pointer
/// or simply a 
const Block = struct {
    /// the start of this block relative to the beginning
    /// of the buffer
    offset: usize,
    /// Size of this block in bytes
    size: usize
};

test "init" {
    var buf = try Buffer.init(std.testing.allocator);
    defer buf.deinit();
}
