const std = @import("std");
const Builder = std.build.Builder;
const builtin = @import("builtin");

pub fn build(builder: *Builder) void {
    const mode = builder.standardReleaseOptions();
    addTests(builder);
}

pub fn addTests(builder: *Builder) void {
    const mode = builder.standardReleaseOptions();
    // unit tests
    const internal_test_step = builder.addTest("src/test.zig");
    internal_test_step.setBuildMode(mode);

    // api integration tests
    const test_step = builder.addTest("test/test.zig");
    test_step.addPackagePath("mu", "src/main.zig");
    test_step.setBuildMode(mode);

    // create test step
    const test_cmd = builder.step("test", "Test the library");
    test_cmd.dependOn(&internal_test_step.step);
    test_cmd.dependOn(&test_step.step);
}
