Fast command-line line counter for your project. Written in Zig.

## Features

- Counts physical lines, code, blanks, and comments using definitions for 70+ languages/formats
- Bounded parallel file counting (up to eight jobs); iterative, non-symlink-following directory traversal
- Reads root and nested `.gitignore` files without writing caches into the scanned tree
- Colored table, JSON, and per-file output
- Skips binary files by default
- Windows: auto-enables UTF-8 + ANSI output

## Install

Requires **Zig `0.17.0-dev.1978+c961124d9`**, the exact development snapshot used by CI and releases. Other Zig 0.17 snapshots are not guaranteed compatible.

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
| `--json` | JSON output (takes precedence over `--short`; `-v` does not change JSON totals) |
| `-s, --short` | One-line summary |
| `--sort FIELD` | Sort by: `lines` (default), `files`, `code`, `name` |
| `--top N` | Show only top N languages |
| `-e, --ext` | Filter by extension (comma-separated) |
| `-V, --version` | Show version |
| `-h, --help` | Show help |

## Example output

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

## Counting semantics and limits

- Each physical line is counted exactly once: `lines = code + comments + blanks`. A final newline does not create an additional empty line; an empty file has zero lines but counts as one file.
- A line containing code before or after a comment counts as code. Whitespace-only lines inside an open block comment count as comments.
- Unknown extensions are reported as `Unknown`, including extensionless files. Normal, verbose and JSON modes use the same counting pipeline.
- `--top N` limits displayed languages, not the grand total. `--top 0` displays no language rows but preserves the total. Equal numeric sort values are ordered by language name.
- Binary detection checks for NUL bytes in the initial sample. `-b` disables that filter; it does not decode binary formats or UTF-16.
- Language detection uses the longest declared suffix. Ambiguous extensions retain the first table definition; there is no content-based language detection.
- Python single/double-quoted and triple-single/triple-double-quoted strings retain their lexical state across supported line continuations and multiline bodies. All string-literal lines, **including docstrings and empty lines within a string**, count as code. This intentionally replaces the earlier convention that treated triple-double-quoted regions as comments; there is no AST-based docstring inference. Comment-only lines outside strings still count as comments.
- JavaScript/TypeScript backtick templates retain their state across lines, including escaped delimiters, nested templates and `${...}` expressions. Raw template body lines count as code even when they contain comment-like text. Real comment-only lines inside interpolation expressions count as comments. Escaped-newline single/double-quoted strings are also tracked.
- Classification remains lightweight, **not a full parser**. JavaScript regex literals and JSX syntax, Python f-string expression grammar, other languages' specialized raw/multiline strings, heredocs and embedded languages may still be classified approximately. Ordinary quotes and C-style comments, including Rust's nested block comments, remain supported.
- The former 100 MiB file cutoff is removed. Large files are memory-mapped; available address space limits the maximum size. Files should not be concurrently modified or truncated during a scan; lc4 does not take a filesystem snapshot.
- File counting uses at most eight jobs. Directory traversal is deliberately sequential and iterative to avoid unbounded tasks and to make inherited ignore rules predictable. This is a correctness-first tradeoff, not a new performance claim.

### Ignore rules

Root and nested `.gitignore` files support relative scope, `/` anchoring, directory-only rules, `!` negation, `*`, `?`, component-boundary `**`, simple character classes/ranges, and escaped metacharacters. An excluded directory is not traversed, so a child cannot be re-included without also re-including its parent.

This is not full Git integration: global excludes, `.git/info/exclude`, ignore rules above the selected root, and POSIX named character classes are not supported. Matching is byte-oriented and case-sensitive. A pattern is limited to 4096 bytes and each `.gitignore` to 10 MiB; exceeding those limits fails the scan rather than silently accepting partial results.

By default lc4 also skips `.git`, `.svn`, `.hg`, `node_modules`, `__pycache__`, `.venv`, `venv`, `.idea`, `.vscode`, `.zig-cache`, `.zig-out`, `zig-out`, and `target`. `-a` disables both these exclusions and `.gitignore` processing. Symlink entries remain skipped, including with `-a`. Scanning never creates an ignore cache in the target tree.

### Failures and exit codes

Invalid options return exit code 2. Traversal or file I/O failures return a nonzero status instead of reporting a successful partial count. Diagnostics go to stderr; failed scans do not emit a successful JSON report. A successful empty scan returns valid JSON with zero totals.

## Test

Using the pinned compiler and Python 3.9+:

```sh
zig build test
zig build
python3 tests/test_cli.py zig-out/bin/lc4
```

On Windows, use `python tests/test_cli.py zig-out/bin/lc4.exe`.

Repeat the build and unit tests with `-Doptimize=ReleaseSafe` and `-Doptimize=ReleaseFast`, then run the CLI suite against each resulting executable. [CI](.github/workflows/ci.yml) runs formatting, unit tests and CLI regression tests natively on Linux, Windows and macOS in all three modes. [Release builds](.github/workflows/release.yml) depend on the same reusable test matrix. The repository pins LF line endings through `.gitattributes` so Windows checkout does not change formatter input.

The reliability revision `152c4cd` passed all nine CI jobs on 2026-09-06; check the latest PR checks for subsequent changes. The suite now includes JavaScript/TypeScript templates and Python multiline strings, with tests for interpolation comments, escapes, CRLF, memory-mapped files, file-state isolation and allocation failures. Platform-dependent permission and symlink tests explicitly skip when the host cannot enforce or create the required condition; a green job does not imply every conditional test ran on every platform.

The CLI suite covers explicit roots, nested ignores, mode parity, ownership-sensitive options, binary inclusion, physical-line invariants, unknown/empty files, top-N, Unicode paths, symlink cycles (where available), hundreds of files, and a file larger than 100 MiB.
