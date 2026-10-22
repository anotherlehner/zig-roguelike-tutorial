//! zig-roguelike, by Martin Lehner (@anotherlehner)

const std = @import("std");
const tcod = @import("tcod.zig");
const engine = @import("engine.zig");
const constants = @import("constants.zig");
const procgen = @import("procgen.zig");
const ent = @import("entity.zig");
const expect = std.testing.expect;

test {
    // import tests from all modules
    _ = @import("tcod.zig");
    _ = @import("engine.zig");
    _ = @import("procgen.zig");
    _ = @import("map.zig");
    _ = @import("color.zig");
    _ = @import("messagelog.zig");
}

pub fn main() anyerror!void {
    var contextOwner = try tcod.init();
    defer tcod.quit();
    defer contextOwner.deinit();
    const console = tcod.consoleNew(constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT);
    defer tcod.consoleDelete(console);
    tcod.setFps(20);

    // Initialize the memory allocator for the whole program
    var gpa = std.heap.SafeAllocator.init(std.heap.page_allocator, .{});
    const allocator = gpa.allocator();
    defer {
        if (gpa.deinit() != 0) expect(false) catch @panic("FAIL");
    }

    // Create game structures and the engine
    const player = try ent.player(0, 0, allocator);
    var map = try procgen.generateDungeon(constants.MAX_ROOMS, constants.ROOM_MIN_SIZE, constants.ROOM_MAX_SIZE, constants.ROOM_MAX_MONSTERS, constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT, constants.SCREEN_HEIGHT - 5, player, allocator);
    defer {
        map.deinit(allocator);
    }
    var eng = engine.Engine.init(player, contextOwner.context, console, &map, allocator);
    defer eng.deinit();

    // Run the game
    try eng.run();
}
