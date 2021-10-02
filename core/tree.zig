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

/// errors that can be thrown from creating or operating on nodes
pub const NodeError = error{
    InvalidSize,
    ExceedsCapacity,
};

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
    inner: [MAX_CHILDREN]Ref(Node),
    /// an inner node is a slice of pointers
    /// to more metadata which can be either leaves
    /// or more nodes
    //jInner: [MAX_DATA]T align(@alignOf(T)),
    leaf: [MAX_DATA]T,
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

    /// Creates a leaf node from a slice of type T
    pub fn from_slice(allocator: *Allocator, slice: []T) !Ref(Self) {
        if (slice.len > MAX_DATA) {
            return NodeError.ExceedsCapacity;
        }

        var l = NodeVal{.leaf = undefined};

        var i: usize = 0;
        while (i < slice.len) : (i += 1) {
            l.leaf[i] = slice[i];
        }

        return Ref(Self).new(allocator, Self{
            // a leaf always has a height of 0
            .height = 0,
            .len = slice.len,
            // TODO: create info from leaf type
            .info = .{},
            .val = l,
        });
    }

    /// Creates a node from a slice of node references
    pub fn from_nodes(allocator: *Allocator, nodes: []Ref(Self)) !Ref(Self) {
        if (nodes.len > MAX_CHILDREN) {
            return NodeError.ExceedsCapacity;
        }

        var in = NodeVal{.inner = undefined};

        var i: usize = 0;
        while (i < nodes.len) : (i += 1) {
            in.inner[i] = nodes[i];
        }

        return Ref(Self).new(allocator, Self{
            // a leaf always has a height of 0
            .height = 0,
            .len = 0,
            // TODO: create info from leaf type
            .info = .{},
            .val = in,
        });
    }
};

pub const Tree = struct {
    /// the root of this tree
    root: Ref(Node),
    /// allocator for adding new nodes and stuff
    allocator: *Allocator,

    const Self = @This();

    pub fn init(allocator: *Allocator) Self {
        return .{
            .allocator = allocator,
            .root = null,
        };
    }
    // pub fn push_back(self: Self, t: T)
    // pub fn push_slice(self: Self, s: []T)
    // pub fn insert(self: Self, s: []T)
    // pub fn slice_left(self: Self, s: []T) Self
    // pub fn slice_right(s: []T) Self
};


test "init" {
    const allocator = testing.allocator;

    var slice = [_]T{0, 1, 2};
    const n1 = try Node.from_slice(allocator, &slice);
    defer n1.deinit(allocator);

    const in = try Node.from_nodes(allocator, &[_]Ref(Node){ n1, n1, n1 });
    defer in.deinit(allocator);

    try expect(n1.ptr().*.len == 3);

    try testing.expectError(
        error.ExceedsCapacity,
        Node.from_nodes(allocator, &[_]Ref(Node){ n1, n1, n1, n1, n1 })
    );
}
