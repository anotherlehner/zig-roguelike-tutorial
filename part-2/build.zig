const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const use_sdl3 = target.result.os.tag == .macos;

    const exe_module = createModule(b, target, optimize, use_sdl3);
    const exe = b.addExecutable(.{ .name = "zrl", .root_module = exe_module });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_module = createModule(b, target, optimize, use_sdl3);
    const tests = b.addTest(.{ .root_module = test_module });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}

fn createModule(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, use_sdl3: bool) *std.Build.Module {
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

    const module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    module.addImport("c", c_translation.createModule());

    if (use_sdl3) {
        module.linkSystemLibrary("tcod", .{});
        module.linkSystemLibrary("SDL3", .{});
        module.addSystemIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
        module.addSystemIncludePath(.{ .cwd_relative = "/usr/local/include" });
        module.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
        module.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });
    } else {
        module.linkSystemLibrary("libtcod", .{});
        module.linkSystemLibrary("SDL2", .{});
    }

    return module;
}
