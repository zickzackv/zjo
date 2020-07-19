const Builder = @import("std").build.Builder;
const debug = @import("std").debug.print;

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

    const command_args = .{
        [_][]const u8{ "-a", "zero", "one", "two", "three" },
        [_][]const u8{ "-a", "null", "eins", "zwei", "drei", "vier" },
        [_][]const u8{ "null:zero", "eins:oone", "zwei:2", "drei:4", "vier:9" },
    };

    const test_step = b.step("test", "rung zjo with different parameters");

    inline for (command_args) |args| {
        const command = zjo.run();
        command.addArgs(&args);
        command.step.dependOn(b.getInstallStep());
        const log = b.addLog("\nRun zjo with args '{s}'\n", .{args});
        test_step.dependOn(&command.step);
        test_step.dependOn(&log.step);
    }
}
