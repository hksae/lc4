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
# binary at zig-out/bin/linescounter4 (or linescounter4.exe on Windows)
```

## Usage

```sh
linescounter4                 # scan cwd, recursive, respect .gitignore
linescounter4 -a              # ignore .gitignore, scan everything
linescounter4 -v              # per-file breakdown
linescounter4 -b              # include binary files
linescounter4 --json          # JSON output
linescounter4 -e .zig,.rs     # only these extensions
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
