const Builder = @import("std").build.Builder;
const debug   = @import("std").debug.warn;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const zjo = b.addExecutable("zjo", "src/main.zig");
    
    zjo.setTarget(target);
    zjo.setBuildMode(mode);
    zjo.addPackagePath("args", "./zig-args/args.zig");
    zjo.install();

    const run_cmd = zjo.run();
    run_cmd.step.dependOn(b.getInstallStep());

    // you can now call run with the following command line
    // $zig build run -- arg1 arg2 arg3
    if (b.args) |args| run_cmd.addArgs(args);


    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
