# Part 7: Creating the interface

By Martin Lehner ([@anotherlehner](https://github.com/anotherlehner))

## C interop

The build translates `src/c.h` with `addTranslateC` and makes the generated
declarations available as the shared `c` module, imported with `@import("c")`.
The header includes libtcod and the platform-specific SDL header (SDL2 on
non-macOS platforms and SDL3 on macOS); matching libraries are linked for the
executable and test modules.

## Memory and collections

The program uses `std.heap.SafeAllocator`; its `deinit` returns a leak count,
which is checked on exit. Procedural generation uses
`std.Random.DefaultPrng`, seeded with `time(null)` from the translated C
declarations. Dynamic collections use unmanaged `std.ArrayList` values,
initialized with `.empty` and passed an allocator for operations that may
allocate.

Run `zig build test` from this directory to exercise the game logic, entity
behavior, startup console dimensions, and libtcod interop wrappers. These tests
do not open a window, so they can run in headless environments.

## Rendering context and magnification

Part 7 creates a `TCOD_Context` with a 10x10 tileset and presents its console
through `TCOD_context_present`. `constants.zig` configures
`WINDOW_MAGNIFICATION`; `tcod.zig` uses it to size the context window in pixels
while keeping the game console at 80x50 cells. The context and tileset are
released before `TCOD_quit`.