//! zig-roguelike, by Martin Lehner (@anotherlehner)
const std = @import("std");
const tcod = @import("tcod.zig");
const color = @import("color.zig");
const ai = @import("ai.zig");
const engine = @import("engine.zig");
const Allocator = std.mem.Allocator;

pub const ComponentTag = enum {
    fighter,
};

pub const ComponentType = union(ComponentTag) {
    fighter: ComponentFighter,
};

pub const RenderOrder = enum {
    corpse,
    item,
    actor,
};

pub const Entity = struct {
    x: i32 = 0,
    y: i32 = 0,
    glyph: u8 = '?',
    color: tcod.TcodColorRGB = color.rgb(255, 255, 255),
    name: []const u8 = "Unnamed",
    blocksMovement: bool = false,
    component: ComponentType = undefined,
    ai: ?ai.AIType = null, // optional ai
    isPlayer: bool = false,
    renderOrder: RenderOrder = RenderOrder.corpse,

    pub fn move(self: *Entity, dx: i32, dy: i32) void {
        self.x += dx;
        self.y += dy;
    }
};

pub fn renderOrderComparator(context: void, a: *Entity, b: *Entity) bool {
    _ = context;
    return @intFromEnum(a.renderOrder) < @intFromEnum(b.renderOrder);
}

pub const ComponentFighter = struct {
    maxHp: i32,
    hp: i32,
    defense: i32,
    power: i32,

    pub fn setHp(self: *ComponentFighter, value: i32) void {
        self.hp = @max(0, @min(value, self.maxHp));
    }

    pub fn isAlive(self: *ComponentFighter) bool {
        return self.hp > 0;
    }
};

pub fn die(eng: *engine.Engine, e: *Entity) void {
    if (e.isPlayer) {
        const msg = std.fmt.allocPrint(eng.allocator, "You died!", .{}) catch @panic("eom");
        eng.log.addMessage(msg, color.Player_die, true);
    } else {
        const msg = std.fmt.allocPrint(eng.allocator, "{s} died.", .{e.name}) catch @panic("eom");
        eng.log.addMessage(msg, color.Enemy_die, true);
    }

    e.glyph = '%';
    e.color = color.rgb(191, 0, 0);
    e.blocksMovement = false;
    e.ai = null;
    e.name = "remains"; // TODO: how do i manage freeing this if it's dynamic?
    e.renderOrder = RenderOrder.corpse;
}

pub fn orc(x: i32, y: i32, allocator: Allocator) !*Entity {
    const e = try allocator.create(Entity);
    e.x = x;
    e.y = y;
    e.glyph = 'o';
    e.color = color.rgb(63, 127, 63);
    e.name = "Orc";
    e.blocksMovement = true;
    e.component.fighter = ComponentFighter{ .maxHp = 10, .hp = 10, .defense = 0, .power = 3 };
    e.ai = ai.AIType.hostile;
    e.renderOrder = RenderOrder.actor;
    return e;
}

pub fn troll(x: i32, y: i32, allocator: Allocator) !*Entity {
    const e = try allocator.create(Entity);
    e.x = x;
    e.y = y;
    e.glyph = 'T';
    e.color = color.rgb(0, 127, 0);
    e.name = "Troll";
    e.blocksMovement = true;
    e.component.fighter = ComponentFighter{ .maxHp = 16, .hp = 16, .defense = 1, .power = 4 };
    e.renderOrder = RenderOrder.actor;
    return e;
}

pub fn player(x: i32, y: i32, allocator: Allocator) !*Entity {
    const e = try allocator.create(Entity);
    e.x = x;
    e.y = y;
    e.glyph = '@';
    e.color = color.rgb(255, 255, 255);
    e.name = "Player";
    e.blocksMovement = true;
    e.component.fighter = ComponentFighter{ .maxHp = 30, .hp = 30, .defense = 2, .power = 5 };
    e.isPlayer = true;
    e.renderOrder = RenderOrder.actor;
    return e;
}

test "entity move updates coordinates" {
    var e = Entity{ .x = 4, .y = 7 };

    e.move(-2, 3);

    try std.testing.expectEqual(@as(i32, 2), e.x);
    try std.testing.expectEqual(@as(i32, 10), e.y);
}

test "fighter clamps hit points and reports alive state" {
    var fighter = ComponentFighter{ .maxHp = 10, .hp = 5, .defense = 1, .power = 2 };

    fighter.setHp(15);
    try std.testing.expectEqual(@as(i32, 10), fighter.hp);
    try std.testing.expect(fighter.isAlive());

    fighter.setHp(-3);
    try std.testing.expectEqual(@as(i32, 0), fighter.hp);
    try std.testing.expect(!fighter.isAlive());
}

test "entity factories initialize player and monster components" {
    const allocator = std.testing.allocator;
    const p = try player(2, 3, allocator);
    defer allocator.destroy(p);
    const o = try orc(4, 5, allocator);
    defer allocator.destroy(o);
    const t = try troll(6, 7, allocator);
    defer allocator.destroy(t);

    try std.testing.expectEqual(@as(i32, 2), p.x);
    try std.testing.expectEqual(@as(i32, 3), p.y);
    try std.testing.expect(p.isPlayer);
    try std.testing.expect(p.blocksMovement);
    try std.testing.expectEqual(@as(i32, 30), p.component.fighter.maxHp);
    try std.testing.expectEqual(@as(u8, 'o'), o.glyph);
    try std.testing.expectEqual(@as(i32, 10), o.component.fighter.maxHp);
    try std.testing.expect(o.ai != null);
    try std.testing.expectEqual(@as(u8, 'T'), t.glyph);
    try std.testing.expectEqual(@as(i32, 16), t.component.fighter.maxHp);
    try std.testing.expect(t.blocksMovement);
}

test "render order comparator sorts corpses before actors" {
    var corpse = Entity{ .renderOrder = .corpse };
    var actor = Entity{ .renderOrder = .actor };

    try std.testing.expect(renderOrderComparator({}, &corpse, &actor));
    try std.testing.expect(!renderOrderComparator({}, &actor, &corpse));
}
