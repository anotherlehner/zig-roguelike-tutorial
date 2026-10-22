# Part 5: Placing enemies and kicking them (harmlessly)

By Martin Lehner ([@anotherlehner](https://github.com/anotherlehner))

Nothing remarkable to write after part 5 completed other than I think the code is starting to get a bit messy. In trying to balance spending enough time working on the tutorial and learning zig and figuring out how to translate and solve problems to the Zig way I've let the overall structure get away from me. I think that's probably okay, I'll come back later on in the process and refactor once I get a bit more experience. I'll see how part 6 goes, it's a good bit longer than parts 4 or 5.

I'm also very slowly starting to build up some instinct for when there will be a memory leak and how to make sure I free memory when it's no longer needed.

Updated [screenshot](images/orcs_and_trolls.png).

## Zig 0.17 upgrade

`build.zig` now creates a translated C module from `src/c.h` and imports it into the program as `c`. The header includes libtcod and the appropriate SDL header for the platform (SDL2 except on macOS, which uses SDL3); the same C libraries are linked for the executable and test targets. `tcod.zig` now imports these declarations with `@import("c")` rather than `@cImport`.

The source uses `std.heap.SafeAllocator` in place of the removed `GeneralPurposeAllocator` API and checks the leak count returned by `deinit`. Procedural generation seeds `std.Random.DefaultPrng` using `time(null)` from `<time.h>`, replacing the removed `std.time.Instant` calls.
