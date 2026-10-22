const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const use_sdl3 = target.result.os.tag == .macos;

    const c_translation = b.addTranslateC(.{
        .root_source_file = b.path("src/c.h"),
        .target = target,
        .optimize = optimize,
    });

    if (use_sdl3) {
        c_translation.defineCMacro("TCOD_SDL3", "1");
        c_translation.addSystemIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
        c_translation.addSystemIncludePath(.{ .cwd_relative = "/usr/local/include" });
    }

    const c_module = c_translation.createModule();

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    root_module.addImport("c", c_module);
    configureLibtcod(root_module, use_sdl3);

    const exe = b.addExecutable(.{
        .name = "zrl",
        .root_module = root_module,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_module.addImport("c", c_module);
    configureLibtcod(test_module, use_sdl3);

    const exe_tests = b.addTest(.{ .root_module = test_module });
    const run_tests = b.addRunArtifact(exe_tests);
    const run_tests_step = b.step("test", "Run unit tests");
    run_tests_step.dependOn(&run_tests.step);
}

fn configureLibtcod(module: *std.Build.Module, use_sdl3: bool) void {
    module.link_libc = true;
    if (use_sdl3) {
        module.linkSystemLibrary("tcod", .{});
        module.linkSystemLibrary("SDL3", .{});
        module.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
        module.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });
    } else {
        module.linkSystemLibrary("libtcod", .{});
        module.linkSystemLibrary("SDL2", .{});
    }
}
