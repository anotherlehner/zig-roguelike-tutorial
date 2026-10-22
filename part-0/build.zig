const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 1. Point to your header file in src/c.h
    const translate = b.addTranslateC(.{
        .root_source_file = b.path("src/c.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    if (target.result.os.tag == .macos) {
        translate.linkSystemLibrary("tcod", .{});
        translate.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
        // translate.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
        translate.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
        // translate.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });
    } else {
        translate.linkSystemLibrary("libtcod", .{});
    }

    // 2. Create the module and import the translated C bindings as "c"
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{
            .{ .name = "c", .module = translate.createModule() },
        },
    });

    if (target.result.os.tag == .macos) {
        exe_mod.linkSystemLibrary("tcod", .{});
        exe_mod.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
        exe_mod.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
        exe_mod.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
        exe_mod.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });
    } else {
        exe_mod.linkSystemLibrary("libtcod", .{});
    }

    const exe = b.addExecutable(.{
        .name = "zrl",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.addPassthruArgs();
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
