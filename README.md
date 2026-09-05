Fast command-line line counter for your project. Written in Zig.

## Features

- Counts lines, code, blanks, and comments across 70+ languages/formats
- Parallel directory walking and file counting
- Respects `.gitignore` by default
- Colored table, JSON, and per-file output
- Skips binary files by default
- Windows: auto-enables UTF-8 + ANSI output

## Install

Requires Zig 0.17.

```sh
zig build -Doptimize=ReleaseFast
# binary at zig-out/bin/lc4
```

## Usage

```sh
lc4                     # scan cwd, recursive, respect .gitignore
lc4 ./src               # scan specific path
lc4 -a                  # ignore .gitignore, scan everything
lc4 -v                  # per-file breakdown
lc4 -b                  # include binary files
lc4 --json              # JSON output
lc4 -e .zig,.rs         # only these extensions
lc4 -n                  # no colors
lc4 --sort name         # sort by name instead of lines
lc4 --top 5             # show only top 5 languages
```

## Options

| Flag | Description |
|------|-------------|
| `[path]` | Directory to scan (default: cwd) |
| `-a, --all` | Ignore `.gitignore`, scan all files |
| `-b, --binaries` | Include binary files |
| `-n, --no-color` | Disable colored output |
| `-v, --verbose` | Per-file breakdown |
| `--json` | JSON output |
| `--sort FIELD` | Sort by: `lines` (default), `files`, `code`, `name` |
| `--top N` | Show only top N languages |
| `-e, --ext` | Filter by extension (comma-separated) |
| `-V, --version` | Show version |
| `-h, --help` | Show help |

## Example

```
┌────────────┬────────┬──────────┬──────────┬────────────┬──────────┐
│ Language   │  Files │    Lines │   Blanks │   Comments │     Code │
├────────────┼────────┼──────────┼──────────┼────────────┼──────────┤
│ Rust       │     33 │    15327 │      868 │        997 │    13462 │
│ Unknown    │      3 │     3352 │      355 │          0 │     2997 │
│ Markdown   │      2 │      312 │       69 │          0 │      243 │
│ TOML       │      1 │       40 │        2 │          0 │       38 │
│ PowerShell │      1 │       39 │        6 │          7 │       26 │
│ Shell      │      1 │       29 │        6 │          8 │       15 │
├────────────┼────────┼──────────┼──────────┼────────────┼──────────┤
│ Total      │     41 │    19099 │     1306 │       1012 │    16781 │
└────────────┴────────┴──────────┴──────────┴────────────┴──────────┘
```

## Test

```sh
zig build test
```
