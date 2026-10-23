//! zig-roguelike, by Martin Lehner (@anotherlehner)
const std = @import("std");

const c = @import("c");

pub fn main() anyerror!void {
    // Note that info level log messages are by default printed only in Debug
    // and ReleaseSafe build modes.
    std.log.info("tcod green: {}", .{c.TCOD_green});
}

test "tcod green has lots of green in it" {
    try std.testing.expectEqual(0, c.TCOD_green.r);
    try std.testing.expectEqual(255, c.TCOD_green.g);
    try std.testing.expectEqual(0, c.TCOD_green.b);
}
