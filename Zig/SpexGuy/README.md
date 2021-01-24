# GrailSort for Zig

This is a snapshot of SpexGuy's grailsort implementation for Zig, from [commit 96eb447](https://github.com/SpexGuy/Zig-GrailSort/tree/96eb4478efa03657d9e844e30644ec8796ef5ff5).
Ongoing work on this project [can be found here](https://github.com/SpexGuy/Zig-GrailSort).

This is the implementation at its most readable, before it was tweaked for optimization purposes.

To run the benchmarks, use the command
```
zig build bench -Drelease-fast
```
For functional tests, use
```
zig test src/grailsort.zig
```
Or, to debug the tests,
```
zig build vscode
gdb zig-cache/bin/vscode.exe
```

This repo also includes visual studio code files for debugging.
