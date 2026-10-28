//! zig-roguelike, by Martin Lehner (@anotherlehner)

const std = @import("std");
const color = @import("color.zig");
const constants = @import("constants.zig");
const map = @import("map.zig");
const expect = std.testing.expect;

const c = @import("c");

pub const TcodConsole = *c.TCOD_Console;
pub const TcodColorRGBA = c.TCOD_ColorRGBA;
pub const TcodColorRGB = c.TCOD_ColorRGB;
pub const TcodKey = c.TCOD_key_t;
pub const TcodMouse = c.TCOD_mouse_t;
pub const TcodEvent = c.TCOD_event_t;
pub const TcodMap = c.TCOD_map_t;
pub const TcodPath = c.TCOD_path_t;
pub const TcodCallback = c.TCOD_path_func_t;
pub const TcodTileset = [*c]c.TCOD_Tileset;
pub const TcodContext = [*c]c.TCOD_Context;
pub const TcodContextParams = c.TCOD_ContextParams;

pub const TcodEventKeyPress = c.TCOD_EVENT_KEY_PRESS;
pub const TcodEventMouseMove = c.TCOD_EVENT_MOUSE_MOVE;
pub const TcodEventMousePress = c.TCOD_EVENT_MOUSE_PRESS;
pub const TcodEventMouseRelease = c.TCOD_EVENT_MOUSE_RELEASE;

pub const KeyEscape = c.TCODK_ESCAPE;
pub const KeyUp = c.TCODK_UP;
pub const KeyDown = c.TCODK_DOWN;
pub const KeyLeft = c.TCODK_LEFT;
pub const KeyRight = c.TCODK_RIGHT;
pub const KeyNone = c.TCODK_NONE;
pub const KeyJ = c.TCODK_J;

pub const ContextOwner = struct {
    context: TcodContext,
    tileset: TcodTileset,

    pub fn deinit(self: *ContextOwner) void {
        c.TCOD_context_delete(self.context);
        c.TCOD_tileset_delete(self.tileset);
    }
};

pub fn init() !ContextOwner {
    if (constants.WINDOW_MAGNIFICATION <= 0) return error.InvalidWindowMagnification;

    const tileset = c.TCOD_tileset_load(constants.TILESET, 32, 8, 256, &c.TCOD_CHARMAP_TCOD);
    if (tileset == null) {
        std.log.err("Failed to load tileset: {s}", .{std.mem.span(c.TCOD_get_error())});
        return error.TilesetLoadFailed;
    }

    var params: TcodContextParams = std.mem.zeroes(TcodContextParams);
    params.tcod_version = c.TCOD_COMPILEDVERSION;
    const magnification: f64 = constants.WINDOW_MAGNIFICATION;
    const tile_width = tileset[0].tile_width;
    const tile_height = tileset[0].tile_height;
    params.pixel_width = @intFromFloat(@as(f64, @floatFromInt(constants.SCREEN_WIDTH * tile_width)) * magnification);
    params.pixel_height = @intFromFloat(@as(f64, @floatFromInt(constants.SCREEN_HEIGHT * tile_height)) * magnification);
    params.columns = constants.SCREEN_WIDTH;
    params.rows = constants.SCREEN_HEIGHT;
    params.renderer_type = c.TCOD_RENDERER_SDL2;
    params.tileset = tileset;
    params.vsync = 1;
    params.window_title = constants.TITLE;

    var context: TcodContext = null;
    const tcodErr = c.TCOD_context_new(&params, &context);
    if (tcodErr < 0 or context == null) {
        std.log.err("Failed to create libtcod context: {s}", .{std.mem.span(c.TCOD_get_error())});
        c.TCOD_tileset_delete(tileset);
        return error.ContextCreationFailed;
    }

    return .{ .context = context, .tileset = tileset };
}

pub fn initKeyWithVk(initialVk: c_uint) TcodKey {
    var k = initEmptyKey();
    k.vk = initialVk;
    return k;
}

pub fn initEmptyMouse() TcodMouse {
    return TcodMouse{ .x = undefined, .y = undefined, .dx = undefined, .dy = undefined, .cx = -1, .cy = -1, .dcx = undefined, .dcy = undefined, .lbutton = undefined, .rbutton = undefined, .mbutton = undefined, .lbutton_pressed = undefined, .rbutton_pressed = undefined, .mbutton_pressed = undefined, .wheel_up = undefined, .wheel_down = undefined };
}

pub fn initEmptyKey() TcodKey {
    return TcodKey{ .vk = KeyNone, .c = 0, .text = undefined, .pressed = undefined, .lalt = undefined, .lctrl = undefined, .lmeta = undefined, .ralt = undefined, .rctrl = undefined, .rmeta = undefined, .shift = undefined };
}

pub fn quit() void {
    c.TCOD_quit();
}

pub fn consoleNew(width: i32, height: i32) TcodConsole {
    return c.TCOD_console_new(width, height);
}

pub fn consoleDelete(console: TcodConsole) void {
    c.TCOD_console_delete(console);
}

pub fn consoleIsWindowClosed() bool {
    return c.TCOD_console_is_window_closed();
}

pub fn contextPresent(context: TcodContext, console: TcodConsole) !void {
    const tcodErr = c.TCOD_context_present(context, console, null);
    if (tcodErr < 0) {
        std.log.err("Failed to present console: {s}", .{std.mem.span(c.TCOD_get_error())});
        return error.ConsolePresentationFailed;
    }
}

pub fn contextScreenPixelToTile(context: TcodContext, x: *i32, y: *i32) bool {
    const tcodErr = c.TCOD_context_screen_pixel_to_tile_i(context, x, y);
    if (tcodErr < 0) {
        std.log.err("Failed to convert mouse position to console coordinates: {s}", .{std.mem.span(c.TCOD_get_error())});
        return false;
    }
    return true;
}

pub fn consolePutCharEx(con: TcodConsole, x: i32, y: i32, character: u8, fore: TcodColorRGB, back: TcodColorRGB) void {
    c.TCOD_console_put_char_ex(con, x, y, character, fore, back);
}

pub fn consoleClear(con: TcodConsole) void {
    c.TCOD_console_clear(con);
}

pub fn sysCheckForEvent(key: *TcodKey, mouse: *TcodMouse) TcodEvent {
    return c.TCOD_sys_check_for_event(c.TCOD_EVENT_ANY, key, mouse);
}

pub fn lineInit(xFrom: i32, yFrom: i32, xTo: i32, yTo: i32) void {
    c.TCOD_line_init(xFrom, yFrom, xTo, yTo);
}

pub fn lineStep(x: *i32, y: *i32) bool {
    return c.TCOD_line_step(x, y);
}

pub fn mapNew(width: i32, height: i32) TcodMap {
    return c.TCOD_map_new(width, height);
}

pub fn mapSetProperties(m: TcodMap, x: i32, y: i32, isTransparent: bool, isWalkable: bool) void {
    c.TCOD_map_set_properties(m, x, y, isTransparent, isWalkable);
}

pub fn mapClear(m: TcodMap, isTransparent: bool, isWalkable: bool) void {
    c.TCOD_map_clear(m, isTransparent, isWalkable);
}

pub fn mapIsInFov(m: TcodMap, x: i32, y: i32) bool {
    return c.TCOD_map_is_in_fov(m, x, y);
}

pub fn mapIsWalkable(m: TcodMap, x: i32, y: i32) bool {
    return c.TCOD_map_is_walkable(m, x, y);
}

pub fn computeFov(m: TcodMap, povX: i32, povY: i32) void {
    _ = c.TCOD_map_compute_fov(m, povX, povY, 8, true, c.FOV_BASIC);
}

test "initKeyWithVk should set given key on returned structure" {
    const key = initKeyWithVk(KeyUp);
    try expect(key.vk == KeyUp);
}

test "empty input structures initialize neutral coordinates and key values" {
    const key = initEmptyKey();
    const mouse = initEmptyMouse();

    try expect(key.vk == KeyNone);
    try expect(key.c == 0);
    try expect(mouse.cx == -1);
    try expect(mouse.cy == -1);
}

test "console character writes and clear use libtcod console" {
    const console = consoleNew(2, 2);
    defer consoleDelete(console);

    const foreground = TcodColorRGB{ .r = 10, .g = 20, .b = 30 };
    const background = TcodColorRGB{ .r = 40, .g = 50, .b = 60 };
    consolePutCharEx(console, 1, 1, 'x', foreground, background);

    const tile_index: usize = 3;
    try expect(console.tiles[tile_index].ch == 'x');
    try expect(console.tiles[tile_index].fg.r == foreground.r);
    try expect(console.tiles[tile_index].bg.b == background.b);

    consoleClear(console);
    try expect(console.tiles[tile_index].ch == ' ');
}

test "map interop sets walkability and computes field of view" {
    const m = mapNew(3, 3);
    defer c.TCOD_map_delete(m);

    mapSetProperties(m, 1, 1, true, true);
    computeFov(m, 1, 1);

    try expect(mapIsWalkable(m, 1, 1));
    try expect(mapIsInFov(m, 1, 1));
    try expect(!mapIsWalkable(m, 0, 0));

    mapClear(m, false, false);
    try expect(!mapIsWalkable(m, 1, 1));
}

test "line interop steps through a diagonal" {
    lineInit(0, 0, 2, 2);

    var x: i32 = undefined;
    var y: i32 = undefined;
    _ = lineStep(&x, &y);
    try expect(x == 1 and y == 1);
    try expect(!lineStep(&x, &y));
    try expect(x == 2 and y == 2);
    try expect(lineStep(&x, &y));
}

test "path interop computes and walks a route on an open map" {
    const m = mapNew(4, 4);
    defer c.TCOD_map_delete(m);
    for (0..4) |y| {
        for (0..4) |x| {
            mapSetProperties(m, @intCast(x), @intCast(y), true, true);
        }
    }

    const path = pathNewUsingMap(m);
    defer pathDelete(path);

    try expect(pathCompute(path, 0, 0, 3, 3));
    try expect(!pathIsEmpty(path));
    try expect(pathSize(path) > 0);

    var x: i32 = undefined;
    var y: i32 = undefined;
    pathGet(path, pathSize(path) - 1, &x, &y);
    try expect(x == 3 and y == 3);
    try expect(pathWalk(path, &x, &y));
}

pub fn setFps(fpsValue: c_int) void {
    c.TCOD_sys_set_fps(fpsValue);
}

pub fn pathNewUsingMap(m: TcodMap) TcodPath {
    return c.TCOD_path_new_using_map(m, 1.41);
}

pub fn pathNewUsingFn(width: i32, height: i32, callback: TcodCallback, userData: *anyopaque) TcodPath {
    return c.TCOD_path_new_using_function(width, height, callback, userData, 1.41);
}

pub fn pathDelete(path: TcodPath) void {
    c.TCOD_path_delete(path);
}

pub fn pathCompute(path: TcodPath, ox: i32, oy: i32, dx: i32, dy: i32) bool {
    return c.TCOD_path_compute(path, ox, oy, dx, dy);
}

pub fn pathSize(path: TcodPath) i32 {
    return c.TCOD_path_size(path);
}

pub fn pathGet(path: TcodPath, index: i32, x: *i32, y: *i32) void {
    c.TCOD_path_get(path, index, x, y);
}

pub fn pathIsEmpty(path: TcodPath) bool {
    return c.TCOD_path_is_empty(path);
}

pub fn pathWalk(path: TcodPath, x: *i32, y: *i32) bool {
    return c.TCOD_path_walk(path, x, y, true);
}

pub fn consolePrint(console: TcodConsole, x: i32, y: i32, fmt: []const u8) void {
    var xi: i32 = 0;
    for (fmt) |ch| {
        consolePutCharEx(console, x + xi, y, ch, TcodColorRGB{ .r = 255, .g = 255, .b = 255 }, TcodColorRGB{ .r = 0, .g = 0, .b = 0 });
        xi += 1;
    }
}

/// Prints a string setting only the foreground color and leaving the bg alone
pub fn consolePrintFg(console: TcodConsole, x: i32, y: i32, fmt: []const u8, fg: TcodColorRGB) void {
    var xi: i32 = 0;
    for (fmt) |ch| {
        c.TCOD_console_set_char(console, x + xi, y, ch);
        c.TCOD_console_set_char_foreground(console, x + xi, y, fg);
        xi += 1;
    }
}

pub fn consolePrintFgMaxLength(console: TcodConsole, x: i32, y: i32, fmt: []const u8, fg: TcodColorRGB, maxLength: i32) void {
    var xi: i32 = 0;
    for (fmt) |ch| {
        if (xi > maxLength) return;
        c.TCOD_console_set_char(console, x + xi, y, ch);
        c.TCOD_console_set_char_foreground(console, x + xi, y, fg);
        xi += 1;
    }
}

pub fn consoleDrawRectRgb(console: TcodConsole, x: i32, y: i32, width: i32, height: i32, ch: u8, fg: TcodColorRGB, bg: TcodColorRGB) void {
    _ = c.TCOD_console_draw_rect_rgb(console, x, y, width, height, ch, &fg, &bg, c.TCOD_BKGND_SET);
}
