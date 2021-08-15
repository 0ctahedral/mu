//! A variable length array of characters

const std = @import("std");
const testing = std.testing;

/// A variable length array of characters
pub const String = struct {

    /// Allocator for managing the buffer
    allocator: *std.mem.Allocator,

    /// contents of the string
    buf: []u8,

    /// length of the string in utf8 codepoints
    len: usize,

    const Self = @This();

    /// Creates an empty string
    pub fn init(allocator: *std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .buf = &[_]u8{},
            .len = 0,
        };
    }

    /// Deletes a string
    pub fn deinit(self: Self) void {
        self.allocator.free(self.buf);
    }

    /// Insert a string literal at an offset in the string
    pub fn insert(self: *Self, at: usize, data: []const u8) !void {

    }

    /// Deletes a string literal at an offset in the string
    pub fn delete(self: *Self, at: usize, data: []const u8) !void {

    }
};

test "init" {
    var str = String.init(testing.allocator);
    defer str.deinit();
    try testing.expect(str.len == 0);
    try testing.expect(str.buf.len == 0);
}
