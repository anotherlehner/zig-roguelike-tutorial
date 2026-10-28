# Part 7: Creating the interface

By Martin Lehner ([@anotherlehner](https://github.com/anotherlehner))

## Colors

The first step in part 7 is to separate the colors we've been using to their own location. I created `color.zig` for this purpose and moved all my color definitions there.

In addition, I added my color struct and a couple of utility functions related to color into the same file. This way everything "color" is located in the same place. I followed similar naming of variables to the tutorial code.

## Health

Next we need to add a way of rendering a health bar for the player on the interface showing how much health has been lost and how much we've got left. For this task the tutorial adds a `render_functions.py` file but here in my Zig code we're going to use `renderer.zig`, which will contain all our functions for displaying things on the screen.

_Off-topic: I noticed while working on this that the Zig file formatter was automatically making all of my function calls, signatures, etc... into long single lines instead of keeping my line breaks. This must have changed since I last used it or something? Either way, if you add a trailing comma at the end of any of these things the formatter will automatically use a line-per-item in the list of things. Weird to my brain to put a trailing comma in a function signature but I like the instant reformatting._

The idea the tutorial follows is for the "empty" red bar to be drawn first at the total width and then draw a proportional green bar over the top, if the player has any health left. So we approach this by calculating the bar width and then drawing the two rectancles. Once that's done we draw a message over the top of the bar with the actual numbers.

Let's start with some type conversion. Since my hp and total width values are integers I need to convert them to floats to do the bar width calculation. I also need to convert the result back to an integer because the draw rect function is expecting an integer width. The first part of the function ends up looking like this:

```zig
fn renderBar(
    console: tcod.TcodConsole,
    curValue: i32,
    maxValue: i32,
    totWidth: i32,
    allocator: Allocator,
) void {
    const curValueF = @as(f32, @floatFromInt(curValue));
    const maxValueF = @as(f32, @floatFromInt(maxValue));
    const totWidthF = @as(f32, @floatFromInt(totWidth));
    const barWidth: i32 = @intFromFloat(@floor((curValueF / maxValueF) * totWidthF));

    ...
}
```

The rectangle drawing is pretty straightforward:

```zig
    tcod.consoleDrawRectRgb(
        console,
        0,
        45,
        totWidth,
        1,
        1,
        color.Bar_empty,
        color.Bar_empty,
    );
```

And a very similar one using `barWidth` if it's greater than zero. The only other major difference between my Zig code and the Python is calling free on the allocator to make sure the message created and printed gets handled.

I'll discuss where this gets called later on in this part since the code will further be moved around.

## Messages

Right now all the output is going to the terminal console but we want to be able to display messages to the player during the game. For this we need a message log and a place to render it on the screen. I created a `messagelog.zig` file and started with a data structure as I often do:

```zig
const Message = struct {
    text: []u8,
    fg: tcod.TcodColorRGB,
    count: u8 = 1,
};

pub const MessageLog = struct {
    allocator: Allocator,
    messages: ArrayList(Message),

    ...
}
```

`Message`s are `u8` arrays with an associated foreground color (`fg`) and a length defaulting to `1`. The foreground will allow us to make different messages different colors.

The second structure here is the `MessageLog` and it will hold a list of our messages and the allocator for handling memory.

To the `MessageLog` we'll add some functions to handle different operations:

- initializing the log (`init`)
- adding a message (`addMessage`)
- deprovisioning the log (`deinit`)

I'm handling my screen rendering in `renderer.zig` so I also created a `renderMessages` function there:

```zig
fn renderMessages(
    console: tcod.TcodConsole,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
    log: *messagelog.MessageLog,
) void {
}
```

This function will take a message log, among other things, and show it on the screen.

I don't have a `textwrap.wrap` function available the way the tutorial does. Due to this I crafted my messages to fit in the space I have available. This is something I could improve on in the future and either write my own wrap function given a maximum width or some other approach. One might think it would be naively simple to make a wrap function given a max width, however, that's only the case if we don't have annotated strings. If we start using color codes and other annotations within the message strings we'll also need to make sure we handle those appropriately (eg: if we wanted to use a different color for numbers within a message line than the rest of the message).

My other message printing code was updated to use this new `MessageLog`.

## Closeout

I'm not sure if I'm going to continue doing a full writeup for each chapter. When I started this project I was envisioning a generic Zig roguelike tutorial that I could publish and everyone could use in their own projects. That was years ago and with AI being so pervasive now I'm not sure I see the point. Maybe that's my pessimism talking, I'm not sure quite yet. Either way we'll see during part-8 if I still write up my notes and how much in detail I go.

# Other notes

## C interop

The build translates `src/c.h` with `addTranslateC` and makes the generated
declarations available as the shared `c` module, imported with `@import("c")`.
The header includes libtcod and the platform-specific SDL header (SDL2 on
non-macOS platforms and SDL3 on macOS); matching libraries are linked for the
executable and test modules.

## Memory and collections

The program uses `std.heap.SafeAllocator`; its `deinit` returns a leak count,
which is checked on exit. Procedural generation seeds one
`std.Random.DefaultPrng` from `time(null)` per dungeon and shares it across
room, tunnel, and monster generation. Room placement is bounded and logs a
warning if it cannot place every requested room. Monsters are placed on
unoccupied room tiles. Dynamic collections use unmanaged `std.ArrayList`
values, initialized with `.empty` and passed an allocator for operations that
may allocate.

Run `zig build test` from this directory to exercise the game logic, entity
behavior, startup console dimensions, and libtcod interop wrappers. These tests
do not open a window, so they can run in headless environments.

## Rendering context and magnification

Part 7 creates a `TCOD_Context` with a 10x10 tileset and presents its console
through `TCOD_context_present`. `constants.zig` configures
`WINDOW_MAGNIFICATION`; `tcod.zig` uses it to size the context window in pixels
while keeping the game console at 80x50 cells. The context and tileset are
released before `TCOD_quit`.