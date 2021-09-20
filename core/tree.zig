//! Tree for storing stuff
const std = @import("std");
const testing = std.testing;
const expect = testing.expect;
const Allocator = std.mem.Allocator;

const T = u8;
const B = 2;
const M = 1 << B;
const Bl = std.math.log(comptime_int, 2, @sizeOf(*T) * M / @sizeOf(T));
const Ml = 1 << Bl;

pub const NodeError = error {
    InvalidSize,
    ExceedsCapacity,
};

pub const Node = union {
    Leaf: Leaf,
    Inner: Inner,
};



/// A leaf contains the actual data of the trie
pub const Leaf = struct {
    /// data that the this leaf contains
    data: [Ml]T align(@alignOf(T)),
    len: usize,

    const Self = @This();

    /// Create a leaf node with size s
    pub fn create(allocator: *Allocator, s: usize) !*Node {
        if (s > Ml) {
            return NodeError.InvalidSize;
        }
        var ptr = try allocator.create(Node);
        ptr.* = Node{
            .Leaf = .{
                .data = [_]T{0} ** Ml,
                .len = s,
            }
        };

        return ptr;
    }

    /// is this node full?
    inline fn isFull(self: Self) bool {
        return self.len == Ml;
    }

    /// Creates a copy of this node with additional element
    /// e added to the end.
    /// Fails if the push would exceed the capacity of this node
    pub fn pushBack(self: *Self, allocator: *Allocator, e: T) !*Node {
        if (self.isFull() or self.len+1 == Ml) {
            return NodeError.ExceedsCapacity;
        }

        // allocate new node that is a copy of this one
        var ptr = try allocator.create(Node);
        ptr.* = Node{
            .Leaf = .{
                .data = self.data,
                .len = self.len,
            }
        };
        ptr.*.Leaf.data[self.len] = e;

        return ptr;
    }

    /// Adds an element to this node if possible.
    /// Fails if the push would exceed the capacity of this node
    pub fn pushBackMut(self: Self, e: T) !void {

    }

    /// extend
    pub fn extend(self: Self, e: anytype) !*Node {
        
    }
};

/// and internal node contains subtrees
/// or leaves
pub const Inner = struct {
    /// pointers to this node's subtree
    children: [M]*Node align(@alignOf(*Node)),
    /// number of valid children
    len: usize,
    /// array of cumulative sizes of all the children
    sizes: [M]u32,

    const Self = @This();

    /// create an inner tree node with size z
    pub fn create(allocator: *Allocator, s: usize) !*Node {
        if (s > M) {
            return NodeError.InvalidSize;
        }
        var ptr = try allocator.create(Node);
        ptr.* = Node{
            .Inner = .{
                .children = undefined,
                .len = s,
                .sizes = undefined,
            }
        };

        return ptr;
    }
};

test "init" {
    const allocator = testing.allocator;

    // this is fine because it is less than 4
    var l = try Leaf.create(allocator, 2);
    defer allocator.destroy(l);
    try expect(l.Leaf.len == 2);

    // this should fail because Ml is 32
    try testing.expectError(NodeError.InvalidSize, Leaf.create(allocator, 34));

    var i = try Inner.create(allocator, 2);
    defer allocator.destroy(i);
    try expect(i.Inner.len == 2);

    // this should fail because Ml is 4
    try testing.expectError(NodeError.InvalidSize, Inner.create(allocator, 5));
}

test "full" {
    const allocator = testing.allocator;

    var lf = try Leaf.create(allocator, 32);
    defer allocator.destroy(lf);
    try expect(lf.Leaf.len == 32);
    try expect(lf.Leaf.isFull());

    var l = try Leaf.create(allocator, 10);
    defer allocator.destroy(l);
    try expect(!l.Leaf.isFull());
}

test "push back" {
    const allocator = testing.allocator;

    var l1 = try Leaf.create(allocator, 1);
    defer allocator.destroy(l1);
    l1.*.Leaf.data[0] = 1;

    var l2 = try l1.Leaf.pushBack(allocator, 3);
    defer allocator.destroy(l2);
    try expect(l2.*.Leaf.data[0] == l1.*.Leaf.data[0]);
    try expect(l2.*.Leaf.data[1] == 3);
}
