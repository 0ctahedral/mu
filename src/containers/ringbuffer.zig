const std = @import("std");
const testing = std.testing;

pub fn Ringbuffer(
    comptime T: type,
    comptime capacity: usize,
) type {
    return struct {

        /// The maximum number of items this ringbuffer can hold
        capacity: usize = capacity,
        /// How many items are currently in the buffer
        len: usize = 0,

        /// index of the first item in the ringbuffer
        head: usize = 0,
        /// index of the last item in the ringbuffer
        tail: usize = 0,

        /// The items in this ring buffer
        /// dot not access directly
        buffer: [capacity]T = undefined,

        const Self = @This();

        /// creates a new ringbuffer
        pub fn init() Self {
            return .{};
        }

        /// destroys the ringbuffer (not needed at the moment)
        pub fn deinit(self: Self) void {

        }

        /// add a new item to the ringbuffer
        pub fn push(self: *Self, item: T) !void {
            if (self.len == self.capacity)
                return error.BufferFull;
            // add the item at the correct index
            self.buffer[self.head] = item;
            // increase the index and wrap
            self.head += 1;
            if (self.head >= self.capacity)
                self.head = 0;
            // increase the len
            self.len += 1;
        }

        /// remove an item from the ringbuffer
        pub fn pop(self: *Self) ?T {
            if (self.len == 0)
                return null;

            const ret = self.buffer[self.tail];

            self.tail += 1;
            if (self.tail >= self.capacity)
                self.tail = 0;
            self.len -= 1;

            return ret;
        }

        /// empties the buffer
        pub fn clear(self: *Self) void {
            self.head = 0;
            self.tail = 0;
            self.len = 0;
        }

        /// returns if the buffer is empty
        pub fn empty(self: Self) bool {
            return self.len == 0;
        }

        /// returns if the buffer is full
        pub fn full(self: Self) bool {
            return self.len == self.capacity;
        }

    };
}

test "ringbuffer init" {
    var rb = Ringbuffer(u8, 10).init();
    defer rb.deinit();

    // check that data is the same size
    try testing.expect(rb.buffer.len == rb.capacity);
    
    // check that 
    try testing.expect(rb.len == 0);
}

test "push pop" {
    var rb = Ringbuffer(u8, 10).init();
    defer rb.deinit();

    // cannot pop an empty buffer
    try testing.expect(rb.len == 0);
    try testing.expect(rb.head == rb.tail);
    try testing.expect(rb.empty());
    try testing.expect(rb.pop() == null);

    try rb.push(5);
    try testing.expect(rb.len == 1);
    try testing.expect(rb.pop().? == 5);
    try testing.expect(rb.len == 0);

    var i: u8 = 0;
    while (i < rb.capacity) : (i += 1) {
        try rb.push(i);
    }

    try testing.expect(rb.head == rb.tail);
    try testing.expect(rb.full());
    try testing.expectError(error.BufferFull, rb.push(10));

    i = 0;
    while (i < rb.capacity) : (i += 1) {
        try testing.expect(rb.pop() != null);
    }
    try testing.expect(rb.pop() == null);


    while (i < rb.capacity) : (i += 1) {
        try rb.push(i);
    }
    rb.clear();
    try testing.expect(rb.empty());
}

test "different types" {
    const vec = struct { x: f32 = 0, y: f32 = 0};

    var rb = Ringbuffer(vec, 10).init();

    try rb.push(.{});
    try rb.push(.{.x = 10});

    try testing.expect(rb.pop().?.x == 0);
    try testing.expect(rb.pop().?.x == 10);
}
