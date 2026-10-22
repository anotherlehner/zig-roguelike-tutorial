//! zig-roguelike, by Martin Lehner (@anotherlehner)

const std = @import("std");
const tcod = @import("tcod.zig");
const color = @import("color.zig");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const expect = std.testing.expect;

const Message = struct {
    text: []u8,
    fg: tcod.TcodColorRGB,
    count: u8 = 1,
};

pub const MessageLog = struct {
    allocator: Allocator,
    messages: ArrayList(Message),

    pub fn init(allocator: Allocator) MessageLog {
        const ms: ArrayList(Message) = .empty;
        return MessageLog{ .allocator = allocator, .messages = ms };
    }

    pub fn addMessage(self: *MessageLog, text: []u8, fg: tcod.TcodColorRGB, stack: bool) void {
        if (stack and self.messages.items.len > 0 and std.mem.eql(u8, self.messages.items[self.messages.items.len - 1].text, text)) {
            self.messages.items[self.messages.items.len - 1].count += 1;
            self.allocator.free(text);
        } else {
            self.messages.append(self.allocator, Message{ .text = text, .fg = fg }) catch @panic("oom");
        }
    }

    pub fn deinit(self: *MessageLog) void {
        for (self.messages.items) |m| {
            self.allocator.free(m.text);
        }
        self.messages.deinit(self.allocator);
    }
};

test "messagelog.addMessage" {
    var ml = MessageLog.init(std.testing.allocator);
    defer ml.deinit();
    const msg = std.fmt.allocPrint(std.testing.allocator, "message", .{}) catch @panic("eom");
    ml.addMessage(msg, color.White_rgb, true);
    try expect(std.mem.eql(u8, ml.messages.items[0].text, msg));
}
