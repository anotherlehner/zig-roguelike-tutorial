# Zig Roguelike Tutorial

By Martin Lehner ([@anotherlehner](https://github.com/anotherlehner))

10/2026: This project is now abandoned. Unfortunately with time and major life and technology changes I don't have the time to continue working on this. Maybe at some point in the future I'll return to it.

## Parts

To run each part cd into the folder and execute `zig build run`. To do this make sure you've installed the libtcod headers and the library itself, along with SDL2, on your system -- see part-0 for some details on that.

[Repository](https://github.com/anotherlehner/zig-roguelike)

[Part 0 - Setting Up](part-0)

[Part 1 - Drawing the '@' symbol and moving it around](part-1)

[Part 2 - The generic Entity, the render functions, and the map](part-2)

[Part 3 - Generating a dungeon](part-3)

[Part 4 - Field of view](part-4)

[Part 5 - Placing enemies and kicking them (harmlessly)](part-5)

[Part 6 - Doing (and taking) some damage](part-6)

[Part 7 - Creating the interface](part-7)

[Part 8 - Items and inventory](part-8) (IN PROGRESS)

Part 9 - Ranged scrolls and targeting (TODO)

Part 10 - Saving and loading (TODO)

Part 11 - Delving into the dungeon (TODO)

Part 12 - Increasing difficulty (TODO)

Part 13 - Gearing up (TODO)

### Extras

A more "Traditional look (TODO)

_Note: I have tried to roughly keep the parts of my tutorial the same as the parts of the typical python tcod tutorial so the content can be compared more easily and the flow is similar._

## Intro

Each folder in this repository contains the full code to a part of the roguelike tutorial translated for Zig.

_Disclaimer: This is my first Zig project so please do not consider anything here as idiomatic or a demonstration of how Zig programs should be written. This is simply a fun project to explore, try Zig out, and see how it feels. Consider it an anecdata point._

To create this project the following commands were executed:

```
mkdir zig-roguelike
cd zig-roguelike/
git init
```

The .gitignore file was setup with some initial folders. We want to ignore the zig cache and build folders so they're not committed to git.

```
zig-out/
zig-cache/
```

See each part folder for a readme explanation of how that part was written, what issues I encountered, how I solved problems, and what I was thinking.

Enjoy!

# Links

The Roguelike Tutorials
https://rogueliketutorials.com/

The roguelike tutorial in python
https://rogueliketutorials.com/tutorials/tcod/v2/

Roguelike dev subreddit
https://www.reddit.com/r/roguelikedev/

## History

Note: I started this project in 2022 using a different username on gitlab.com (clockworkmartian) and have since come back to github and reclaimed my old anotherlehner account.

