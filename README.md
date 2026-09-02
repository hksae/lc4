# linescounter4

Blazing-fast command-line line counter for your project. Written in Zig.

## Features

- Counts lines, code, blanks, and comments across 60+ languages/formats
- Parallel file counting via thread pool
- Respects `.gitignore` by default
- Colored table, JSON, and per-file output
- Skips binary files by default
- Windows: auto-enables UTF-8 + ANSI output

## Install

Requires Zig 0.17.

```sh
zig build -Doptimize=ReleaseFast
# binary at zig-out/bin/lc4 (or lc4.exe on Windows)
```

The executable is named `lc4` (short for linescounter4). The project name stays `linescounter4`.

## Usage

```sh
lc4                     # scan cwd, recursive, respect .gitignore
lc4 -a                  # ignore .gitignore, scan everything
lc4 -v                  # per-file breakdown
lc4 -b                  # include binary files
lc4 --json              # JSON output
lc4 -e .zig,.rs         # only these extensions
```

## Options

| Flag | Description |
|------|-------------|
| `-a, --all` | Ignore `.gitignore` |
| `-b, --binaries` | Include binary files |
| `-v, --verbose` | Per-file breakdown |
| `--json` | JSON output |
| `-e, --ext` | Filter by extension (comma-separated) |
| `-h, --help` | Show help |

## Example

```
  Language    Files  Lines  Blanks  Comments  Code
  ───────────────────────────────────────────────────
  Zig            15    831     106         0   725
  TypeScript     42   5671     612       331  4728
  ───────────────────────────────────────────────────
  Total          57   6502     718       331  5453
```

## Test

```sh
zig build test
```
