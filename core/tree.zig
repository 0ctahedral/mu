//! Tree for storing stuff

const std = @import("std");
const expect = std.testing.expect;

const T = u8;
const B = 2;
const M = 1 << B;
const Bl = std.math.log(comptime_int, 2, @sizeOf(*T) * M / @sizeOf(T));
const Ml = 1 << Bl;

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

    pub fn init() Node {
        return Node{ .Leaf = .{
            .data = [_]T{0} ** M,
            .len = 0,
        } };
    }
};

/// and internal node contains subtrees
/// or leaves
pub const Inner = struct {
    /// pointers to this node's subtree
    children: [M]?*Node align(@alignOf(*Node)),
    /// number of valid children
    len: usize,
    /// array of cumulative sizes of all the children
    sizes: [M]u32,

    const Self = @This();

    pub fn init() Node {
        return Node{ .Inner = .{
            .children = [_]?*Node{null} ** M,
            .len = 0,
            .sizes = null,
        } };
    }
};

test "init" {
    std.debug.warn("node {}\n", .{@alignOf(Node)});
    std.debug.warn("inner {}\n", .{@alignOf(Inner)});
    std.debug.warn("leaf {}\n", .{@alignOf(Leaf)});
}
