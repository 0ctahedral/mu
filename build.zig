const std = @import("std");
const Builder = std.build.Builder;
const builtin = @import("builtin");
const addZutil = @import("zutil/build.zig").addZutil;

pub fn build(builder: *Builder) void {
    //const mode = builder.standardReleaseOptions();
    addTests(builder);
}

pub fn addTests(builder: *Builder) void {
    const mode = builder.standardReleaseOptions();
    const target = builder.standardTargetOptions(.{});

    // unit tests
    const internal_test_step = builder.addTest("core/test.zig");
    internal_test_step.setBuildMode(mode);
    addZutil(internal_test_step, "zutil/");

    // api integration tests
    const test_step = builder.addTest("test/test.zig");
    test_step.addPackagePath("mu", "core/core.zig");
    test_step.setBuildMode(mode);
    addZutil(test_step, "zutil/");

    // create test step (tests all)
    const test_cmd = builder.step("test", "Test the library");
    test_cmd.dependOn(&internal_test_step.step);
    test_cmd.dependOn(&test_step.step);

    // add build command for tui
    const exe = builder.addExecutable("tui", "tui/main.zig");
    exe.setTarget(target);
    exe.linkLibC();
    exe.addPackagePath("core", "core/core.zig");
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(builder.getInstallStep());
    const run_step = builder.step("run-tui", "Run the tui app");
    run_step.dependOn(&run_cmd.step);
}
