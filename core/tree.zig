//! Tree for storing stuff

const std = @import("std");
const expect = std.testing.expect;

const B = 2;
const M = 1 << B;

pub const Node = union {
    Leaf: Leaf,
    Inner: Inner,
};

/// A leaf contains the actual data of the trie
pub const Leaf = struct {
    /// data that the this leaf contains
    data: [M]u8,
    /// number of items in the leaf
    len: u8,
};

/// keeps track of the cumulative sizes
/// of the subtrees of an inner node
const sizeTable = [M]u8;

/// and internal node contains subtrees
/// or leaves
pub const Inner = struct {
    /// pointers to this node's subtree
    children: [M]?*Node,
    /// number of valid children
    len: u8,
    /// array of cumulative sizes of all the children
    sizes: ?*sizeTable,
};

test "init" {
    try expect(M == 4);

    var l = Node{ .Leaf = .{
        .data = [_]u8{'a', 'b', 'c', 0},
        .len = 3
    }};

    var st = [_]u8{3, 0, 0, 0};

    var i = Node{ .Inner = .{
        .children = [_]?*Node{&l, null, null, null},
        .len = 1,
        .sizes = &st,
    }};
}
