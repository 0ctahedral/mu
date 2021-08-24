const std = @import("std");
const String = @import("core.zig").String;

/// Buffers are the contents of a file
/// A buffer contains blocks of a file and caches
/// the most recently accessed in a string
pub const Buffer = struct {
    
    /// cache of recently accessed block
    cache: struct {
        /// string that stores a block in memory
        data: String,

        /// offset in bytes of the block stored in the cache
        offset: usize,
    },

    const Self = @This();

    /// Creates a buffer
    pub fn init(allocator: *std.mem.Allocator) !Self {
        return Self{
            .cache=.{
                .data = try String.init(allocator),
                .offset = 0,
            },
        };
    }

    pub fn deinit(self: Self) void {
        self.cache.data.deinit();
    }

    // TODO: blocks
};

test "init" {
    var buf = try Buffer.init(std.testing.allocator);
    defer buf.deinit();
}
