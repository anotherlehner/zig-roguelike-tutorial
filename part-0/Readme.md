# Part 0: Setting Up

By Martin Lehner ([@anotherlehner](https://github.com/anotherlehner))

## Install Zig

Download Zig from the ziglang homepage: https://ziglang.org/download/

This tutorial uses Zig 0.17's build system and standard-library APIs.

## Create the project

Zig makes it easy to initialize a simple project:

```
mkdir part-0
cd part-0/
zig init-exe
```

This generates a `build.zig` file and `src` folder containing a single `main.zig`. The `build.zig` file is part of Zig's build system and provides a code-based configuration of how the project should be compiled, built, tested, installed, etc. I will describe basic usage of this below and get into details in later parts of how to configure this.

## System-based configuration

### Linux 

Since I wanted to make this as easy on myself as possible I decided to see if I could use libtcod from zig installed as a system dev package. I'm on PopOS so I did a quick apt search and found that indeed a slightly older version of libtcod is available!

```
libtcod-dev - development files for the libtcod roguelike library
libtcod1 - graphics and utility library for roguelike developers
```

For me this installed libtcod (and headers) for version 1.18.1. About a year old, not too bad. I will go with that for now.

I'm going to be using the libtcod C API and use some previous years roguelike tutorial attempts in C and the `samples_c.c` that comes with the libtcod source for guidance, among other things. I'll try to note links in each part to websites I used to gain information.

### Mac OS

The easiest way to get libtcod working on OSX is to use brew to install it:

```
brew install libtcod
```

This puts the includes in `/opt/homebrew/include/libtcod`.

NOTE: The name of the library on OSX is `tcod`, not `libtcod`, which confused me at first. I tried a build and saw it failed looking for `liblibtcod`. Once I updated my `build.zig` with an alternate name when being built on macos things worked as expected.

## Configuring Zig to build using libtcod

The build script translates `src/c.h` into a C module and imports it into the
root Zig module. The root module also links libc and libtcod (named `tcod` on
macOS):

```zig
const c_translation = b.addTranslateC(.{
    .root_source_file = b.path("src/c.h"),
    .target = target,
    .optimize = optimize,
});
const c_module = c_translation.createModule();

const root_module = b.createModule(.{
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
    .link_libc = true,
});
root_module.addImport("c", c_module);

if (target.result.os.tag == .macos) {
    root_module.linkSystemLibrary("tcod", .{});
    root_module.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
    root_module.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
} else {
    root_module.linkSystemLibrary("libtcod", .{});
}
```

In Zig source, import the declarations provided by that build module:

```zig
const c = @import("c");
```

The `c` module is generated from the header by `addTranslateC`, making the
translated declarations available to the executable and test modules.

To make sure things were working right I also grabbed a constant from inside the libtcod C header and tried printing it out in the Zig log statement:

```zig
std.log.info("tcod red: {}", .{c.TCOD_red});
```

`{}` means print the value as a string.

## Building and running

To build and run the project Zig provides several commands but for now let's stay basic and just use `zig build run`.

We get the following output:

```
info: tcod red: .{ .r = 255, .g = 0, .b = 0 }
```

Hello libtcod world?

## Tests

I like tests. Zig gives us tests embedded in the code, which we can easily run with `zig build test`. Tests also need a root module that imports the translated C module and links
the same libraries as the executable:

```zig
const test_module = b.createModule(.{
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
    .link_libc = true,
});
test_module.addImport("c", c_module);
test_module.linkSystemLibrary("libtcod", .{});

const exe_tests = b.addTest(.{ .root_module = test_module });

const run_tests = b.addRunArtifact(exe_tests);
const run_tests_step = b.step("test", "Run unit tests");
run_tests_step.dependOn(&run_tests.step);
```

Use the same platform-specific library and include-path configuration for
`test_module` as for `root_module`.

Running `zig build test` will result in no output by default (no news is good news) but if you want to see all the details do:

```
zig build test --summary all
```

Which results in the output:

```
Build Summary: 3/3 steps succeeded; 1/1 tests passed
test success
└─ run test 1 passed 4ms MaxRSS:8M
   └─ compile test Debug native cached 45ms MaxRSS:34M
```

Lovely!

_Not sure how this translates to windows at the moment._

## Notes

Just opened this up today after working on it last night and ran `zig build run` but got an error that `cimport.zig` couldn't be found?
- deleted the `zig-cache` and `zig-out` folder and ran again and things worked as expected
