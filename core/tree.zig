//! Tree for storing stuff
const std = @import("std");
const Ref = @import("zutil").containers.Ref;
const testing = std.testing;
const expect = testing.expect;
const Allocator = std.mem.Allocator;

const Count = usize;
/// the type we are using (will be a parameter in the future)
const T = u8;
/// the maximum number of children an inner node can have
/// TODO: make this based on a size of node we want
const MAX_CHILDREN = 4;
/// the maximum number of T that can fit in a leaf node
/// TODO: make this based on a size of node we want
const MAX_DATA = 4;

/// Metadata for a node.
/// In the future this will be dependent on T and stuff
/// This data is owned by a node's parent
const NodeInfo = struct {
    /// number of graphemes in this subtree
    /// in ascii text it should be the same
    /// as the number of bytes
    graphemes: usize = 0,
    /// number of line endings in this subtree
    lines: usize = 0,
};

/// The kind of node this is and its contents
pub const NodeVal = union {
    /// a leaf just contains data
    Leaf: Leaf,
    /// an inner node is a slice of pointers
    /// to more metadata which can be either leaves
    /// or more nodes
    Inner: Inner,
};

/// A node in our tree
const Node = struct {
    /// depth this nodes subtree
    height: usize,
    /// number of children of this node
    len: usize,
    /// info about this implementation of node
    info: NodeInfo,
    /// values contained in this node
    val: NodeVal,

    const Self = @This();

    /// Creates a node from a leaf
    pub fn from_leaf(allocator: *Allocator, l: Leaf) !Ref(Self) {
        //const ptr = try allocator.create(Self);
        return Ref(Self).new(allocator, Self{
            // a leaf always has a height of 0
            .height = 0,
            .len = l.len,
            // TODO: create info from leaf type
            .info = .{},
            .val = .{ .Leaf = l },
        });
    }
};

/// 
pub const NodeError = error{
    InvalidSize,
    ExceedsCapacity,
};

/// A leaf contains the actual data of the trie
pub const Leaf = struct {
    /// data that the this leaf contains
    data: [MAX_DATA]T align(@alignOf(T)) = [_]u8{0} ** MAX_DATA,
    len: usize,
    const Self = @This();
};

/// and internal node contains subtrees
/// or leaves
pub const Inner = struct {
    children: [MAX_CHILDREN]*Node,
    const Self = @This();
};

test "init" {
    const allocator = testing.allocator;
    const l1: Leaf = .{ .len = 3 };

    var ln = try Node.from_leaf(allocator, l1);
    defer ln.deinit(allocator);

    try expect(ln.rawPtr().*.len == 3);
}
