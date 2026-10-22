# Part 7: Creating the interface

By Martin Lehner ([@anotherlehner](https://github.com/anotherlehner))

## Zig 0.17 upgrade

The build translates `src/c.h` with `addTranslateC` and makes the generated declarations available as the shared `c` module. The header includes libtcod and the platform-specific SDL header (SDL2 on non-macOS platforms and SDL3 on macOS); matching libraries are linked for both the executable and tests. `tcod.zig` now uses `@import("c")` instead of `@cImport`.

The program allocator in `main.zig` is now `std.heap.SafeAllocator`; its `deinit` returns a leak count, which is checked on exit. Procedural generation uses `std.Random.DefaultPrng` seeded with `time(null)` from `<time.h>`, replacing the removed `std.time.Instant` API. The allocator-aware `ArrayList` operations use the Zig 0.17 `.empty` initialization and take an allocator argument.