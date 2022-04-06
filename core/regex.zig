//! Regex engine implementation

const std = @import("std");
const testing = std.testing;


/// Strongly type the index of data
const Index = u32;

/// Instruction types
const Op = enum {
    Char,
    Match,
    Jmp,
    Split,
    Save,
};

const Instr = union(Op) {
    Char: u8,
    Match: struct {},
    Jmp: Index,
    Split: struct {
        lhs: Index,
        rhs: Index,
    },
    Save: usize,
};


/// Executes a regex on a string
const VM = struct {

    const Self = @This();

    const Thread = struct {
        /// Program counter of the current instruction
        pc: Index = 0,
        saved: [20]usize,
    };

    alloc: std.mem.Allocator,

    /// Instructions from a compiled 
    instrs: std.ArrayList(Instr),


    pub fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .instrs = try std.ArrayList(Instr).initCapacity(allocator, 10),
            .alloc = allocator,
        };
    }

    pub fn deinit(self: Self) void {
        self.instrs.deinit();
    }

    pub fn match(self: Self, str: []const u8) !?[20]usize {
        // TOOD: add allocator
        var clist = try std.ArrayList(Thread).initCapacity(self.alloc, 10);
        defer clist.deinit();
        var nlist = try std.ArrayList(Thread).initCapacity(self.alloc, 10);
        defer nlist.deinit();
        
        var saved_match: [20]usize = [_]usize{0} ** 20;

        try clist.append(.{
            .pc = 0,
            .saved = [_]usize{0} ** 20,
        });

        for(str) |c, str_idx| {
            var i: usize = 0;
            //if (clist.items.len == 0) {
            //    return null;
            //}
            while (i < clist.items.len) : (i+= 1) {
                var t = clist.items[i];
                if (self.instrs.items.len == t.pc) {
                    return null;
                }

                const inst = self.instrs.items[t.pc];

                switch (inst) {
                    .Char => |match| {
                        if (c != match) {
                            continue;
                        }
                        try nlist.append(.{ .pc = t.pc + 1, .saved = t.saved });
                    },
                    .Match => {
                        std.debug.print("match\n", .{});
                        saved_match = t.saved;
                    },
                    .Jmp => |to| {
                        std.debug.print("jmp\n", .{});
                        try clist.append(.{ .pc = to, .saved = t.saved });
                    },
                    .Split => |split| {
                        std.debug.print("split\n", .{});
                        try clist.append(.{ .pc = split.rhs, .saved = t.saved });
                        try clist.append(.{ .pc = split.lhs, .saved = t.saved });
                    },
                    .Save => |idx| {
                        t.saved[idx] = str_idx;
                        std.debug.print("save[{}] {any}\n", .{idx, t.saved});
                        try nlist.append(.{ .pc = t.pc + 1, .saved = t.saved });
                    },
                }
            }

            // swap lists
            var tmp = clist;
            clist = nlist;
            nlist = tmp;
            nlist.clearRetainingCapacity();
        }

        return saved_match;
    }
};

// e1e2	    codes for e1 codes for e2
//
// e1|e2    split L1, L2
//          L1: codes for e1
//             jmp L3
//          L2: codes for e2
//          L3:
// 
// e?	    split L1, L2
//          L1: codes for e
//          L2:
// 
// e*	    L1: split L2, L3
//          L2: codes for e
//              jmp L1
//          L3:
// 
// e+	    L1: codes for e
//          split L1, L3
//          L3:

test "init" {
    var vm = try VM.init(testing.allocator);
    defer vm.deinit();
}

test "a+b+" {
    var vm = try VM.init(testing.allocator);
    try vm.instrs.insertSlice(0, &[_]Instr{
        .{ .Save = 0 },
        .{ .Char = 'a' },
        .{ .Split = .{ .lhs = 1, .rhs = 3 } },
        .{ .Char = 'b' },
        .{ .Split = .{ .lhs = 3, .rhs = 5 } },
        .{ .Save = 1 },
        .{ .Match = .{} },
    });
    defer vm.deinit();

    //
    //
    // |<---------|  |---->|              |----->|
    // a => split(0, 2) => b => split (2, 4) => match
    //                     |<----------|
    //
    //

    //std.debug.print("mwith axaabb: {any}\n", .{try vm.match("axaabb")});
    //std.debug.print("mwith aabb: {any}\n", .{try vm.match("aabb")});

    //try testing.expect((try vm.match("axaabb")) == null);
    //try testing.expect((try vm.match("aaabb")).?[1] == @as(usize, 4));
}

test "a*" {
    var vm = try VM.init(testing.allocator);
    try vm.instrs.insertSlice(0, &[_]Instr{
        .{ .Save = 0 },
        .{ .Split = .{ .lhs = 2, .rhs = 4 } },
        .{ .Char = 'a' },
        .{ .Jmp = 0 },
        .{ .Save = 1 },
        .{ .Match = .{} },
    });
    defer vm.deinit();

    //try testing.expect((try vm.match("aaaa")).?[1] == @as(usize, 3));
    try testing.expect((try vm.match("aaab")).?[1] == @as(usize, 1));
}
