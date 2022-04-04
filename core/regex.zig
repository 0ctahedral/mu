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
};

const Instr = union(Op) {
    Char: u8,
    Match: struct {},
    Jmp: Index,
    Split: struct {
        lhs: Index,
        rhs: Index,
    },
};


/// Executes a regex on a string
const VM = struct {

    const Self = @This();

    const Thread = struct {
        /// Program counter of the current instruction
        pc: Index = 0,
    };

    thread: Thread = .{},

    /// Instructions from a compiled 
    instrs: std.ArrayList(Instr),

    pub fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .instrs = try std.ArrayList(Instr).initCapacity(allocator, 10),
        };
    }

    pub fn deinit(self: Self) void {
        self.instrs.deinit();
    }

    /// step through a string with the instructions
    fn step(self: *Self, thread: *Self.thread, char: u8) bool {
        if (self.instrs.items.len == thread.pc) {
            return false;
        }

        const inst = self.instrs.items[thread.pc];

        switch (inst) {
            .Char => |match| {
                std.debug.print("comparing {c} with {c}\n", .{match, char});
                if (char != match) {
                    return false;
                }

                thread.pc += 1;
            },
            .Match => {
                std.debug.print("Match\n", .{});
                return false;
            },
            .Jmp => |to| {
                std.debug.print("Jmp: {}\n", .{to});
                thread.pc = to;
            },
            .Split => |split| {
                std.debug.print("Split: {} {}\n", .{
                    split.lhs,
                    split.rhs,
                });

                thread.pc = split.rhs;
            },
        }

        return true;
    }
};

test "init" {
    var vm = try VM.init(testing.allocator);
    defer vm.deinit();
}

test "a+b+" {
    var vm = try VM.init(testing.allocator);
    try vm.instrs.insertSlice(0, &[_]Instr{
        .{ .Char = 'a' },
        .{ .Split = .{ .lhs = 0, .rhs = 2 } },
        .{ .Char = 'b' },
        .{ .Split = .{ .lhs = 2, .rhs = 4 } },
        .{ .Match = .{} },
    });
    defer vm.deinit();

    var str: []const u8 = "aaabb";

    //
    //
    // |<---------|  |---->|              |----->|
    // a => split(0, 2) => b => split (2, 4) => match
    //                     |<----------|
    //
    //

    var l1 = try std.ArrayList(VM.Thread).initCapacity(testing.allocator, 10);
    defer l1.deinit();
    var l2 = try std.ArrayList(VM.Thread).initCapacity(testing.allocator, 10);
    defer l2.deinit();

    var clist = &l1;
    var nlist = &l2;

    try clist.append(.{ .pc = 0 });

    for(str) |c| 
    {
        var i: usize = 0;
        while (i < clist.items.len) : (i+= 1) {
            const t = clist.items[i];
            if (vm.instrs.items.len == t.pc) {
                std.debug.print("out of instructions\n", .{});
                continue;
            }

            const inst = vm.instrs.items[t.pc];

            std.debug.print("inst: {}\n", .{t.pc});

            switch (inst) {
                .Char => |match| {
                    std.debug.print("t[{}] comparing {c} with {c}\n", .{i, match, c});
                    if (c != match) {
                        std.debug.print("t[{}] failed to match\n", .{i});
                        continue;
                    }

                    try nlist.append(.{ .pc = t.pc + 1 });
                },
                .Match => {
                    std.debug.print("t[{}] Match\n", .{i});
                    break;
                },
                .Jmp => |to| {
                    std.debug.print("t[{}] Jmp: {}\n", .{i, to});
                    try clist.append(.{ .pc = to });
                },
                .Split => |split| {
                    std.debug.print("t[{}] Split: {} {}\n", .{ i, 
                        split.lhs,
                        split.rhs,
                    });
                    try clist.append(.{ .pc = split.rhs });
                    try clist.append(.{ .pc = split.lhs });
                },
            }
        }

        std.debug.print("swapping...\n", .{});

        // swap lists
        var tmp = clist;
        clist = nlist;
        nlist = tmp;
    }
}
