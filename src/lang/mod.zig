const std = @import("std");

pub const Language = struct {
    name: []const u8,
    line_comment: ?[]const u8 = null,
    block_open: ?[]const u8 = null,
    block_close: ?[]const u8 = null,
    color: []const u8,
};

pub const LanguageStat = struct {
    name: []const u8,
    color: []const u8,
    files: u64 = 0,
    lines: u64 = 0,
    blanks: u64 = 0,
    comments: u64 = 0,
    code: u64 = 0,
};

const Entry = struct {
    ext: []const u8,
    lang: Language,
};

const unknown = Language{ .name = "Unknown", .color = "\x1b[37m" };

pub const table = [_]Entry{
    .{ .ext = ".zig", .lang = .{ .name = "Zig", .line_comment = "//", .block_open = "//!", .block_close = null, .color = "\x1b[38;5;208m" } },
    .{ .ext = ".rs", .lang = .{ .name = "Rust", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;216m" } },
    .{ .ext = ".c", .lang = .{ .name = "C", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".h", .lang = .{ .name = "C", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".cpp", .lang = .{ .name = "C++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".cxx", .lang = .{ .name = "C++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".cc", .lang = .{ .name = "C++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".hpp", .lang = .{ .name = "C++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".hxx", .lang = .{ .name = "C++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".hh", .lang = .{ .name = "C++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".cs", .lang = .{ .name = "C#", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;150m" } },
    .{ .ext = ".java", .lang = .{ .name = "Java", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".js", .lang = .{ .name = "JavaScript", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;220m" } },
    .{ .ext = ".jsx", .lang = .{ .name = "JavaScript", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;220m" } },
    .{ .ext = ".ts", .lang = .{ .name = "TypeScript", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;033m" } },
    .{ .ext = ".tsx", .lang = .{ .name = "TypeScript", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;033m" } },
    .{ .ext = ".py", .lang = .{ .name = "Python", .line_comment = "#", .block_open = "\"\"\"", .block_close = "\"\"\"", .color = "\x1b[38;5;082m" } },
    .{ .ext = ".pyw", .lang = .{ .name = "Python", .line_comment = "#", .block_open = "\"\"\"", .block_close = "\"\"\"", .color = "\x1b[38;5;082m" } },
    .{ .ext = ".go", .lang = .{ .name = "Go", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;036m" } },
    .{ .ext = ".rb", .lang = .{ .name = "Ruby", .line_comment = "#", .block_open = "=begin", .block_close = "=end", .color = "\x1b[38;5;196m" } },
    .{ .ext = ".php", .lang = .{ .name = "PHP", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;135m" } },
    .{ .ext = ".swift", .lang = .{ .name = "Swift", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;214m" } },
    .{ .ext = ".kt", .lang = .{ .name = "Kotlin", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".kts", .lang = .{ .name = "Kotlin", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".scala", .lang = .{ .name = "Scala", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;203m" } },
    .{ .ext = ".dart", .lang = .{ .name = "Dart", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;032m" } },
    .{ .ext = ".hs", .lang = .{ .name = "Haskell", .line_comment = "--", .block_open = "{-", .block_close = "-}", .color = "\x1b[38;5;140m" } },
    .{ .ext = ".ml", .lang = .{ .name = "OCaml", .line_comment = null, .block_open = "(*", .block_close = "*)", .color = "\x1b[38;5;209m" } },
    .{ .ext = ".mli", .lang = .{ .name = "OCaml", .line_comment = null, .block_open = "(*", .block_close = "*)", .color = "\x1b[38;5;209m" } },
    .{ .ext = ".ex", .lang = .{ .name = "Elixir", .line_comment = "#", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".exs", .lang = .{ .name = "Elixir", .line_comment = "#", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".erl", .lang = .{ .name = "Erlang", .line_comment = "%", .color = "\x1b[38;5;033m" } },
    .{ .ext = ".hrl", .lang = .{ .name = "Erlang", .line_comment = "%", .color = "\x1b[38;5;033m" } },
    .{ .ext = ".clj", .lang = .{ .name = "Clojure", .line_comment = ";", .color = "\x1b[38;5;036m" } },
    .{ .ext = ".cljs", .lang = .{ .name = "ClojureScript", .line_comment = ";", .color = "\x1b[38;5;036m" } },
    .{ .ext = ".lua", .lang = .{ .name = "Lua", .line_comment = "--", .block_open = "--[[", .block_close = "]]", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".pl", .lang = .{ .name = "Perl", .line_comment = "#", .color = "\x1b[38;5;045m" } },
    .{ .ext = ".pm", .lang = .{ .name = "Perl", .line_comment = "#", .color = "\x1b[38;5;045m" } },
    .{ .ext = ".r", .lang = .{ .name = "R", .line_comment = "#", .color = "\x1b[38;5;249m" } },
    .{ .ext = ".R", .lang = .{ .name = "R", .line_comment = "#", .color = "\x1b[38;5;249m" } },
    .{ .ext = ".jl", .lang = .{ .name = "Julia", .line_comment = "#", .block_open = "#=", .block_close = "=#", .color = "\x1b[38;5;133m" } },
    .{ .ext = ".sh", .lang = .{ .name = "Shell", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".bash", .lang = .{ .name = "Bash", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".zsh", .lang = .{ .name = "Zsh", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".ps1", .lang = .{ .name = "PowerShell", .line_comment = "#", .block_open = "<#", .block_close = "#>", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".psm1", .lang = .{ .name = "PowerShell", .line_comment = "#", .block_open = "<#", .block_close = "#>", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".sql", .lang = .{ .name = "SQL", .line_comment = "--", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;220m" } },
    .{ .ext = ".asm", .lang = .{ .name = "Assembly", .line_comment = ";", .color = "\x1b[38;5;242m" } },
    .{ .ext = ".s", .lang = .{ .name = "Assembly", .line_comment = ";", .color = "\x1b[38;5;242m" } },
    .{ .ext = ".nasm", .lang = .{ .name = "Assembly", .line_comment = ";", .color = "\x1b[38;5;242m" } },
    .{ .ext = ".html", .lang = .{ .name = "HTML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".htm", .lang = .{ .name = "HTML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".css", .lang = .{ .name = "CSS", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".scss", .lang = .{ .name = "SCSS", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;205m" } },
    .{ .ext = ".less", .lang = .{ .name = "Less", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".xml", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".json", .lang = .{ .name = "JSON", .color = "\x1b[38;5;227m" } },
    .{ .ext = ".jsonc", .lang = .{ .name = "JSON", .line_comment = "//", .color = "\x1b[38;5;227m" } },
    .{ .ext = ".yaml", .lang = .{ .name = "YAML", .line_comment = "#", .color = "\x1b[38;5;167m" } },
    .{ .ext = ".yml", .lang = .{ .name = "YAML", .line_comment = "#", .color = "\x1b[38;5;167m" } },
    .{ .ext = ".toml", .lang = .{ .name = "TOML", .line_comment = "#", .color = "\x1b[38;5;215m" } },
    .{ .ext = ".md", .lang = .{ .name = "Markdown", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".markdown", .lang = .{ .name = "Markdown", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".mk", .lang = .{ .name = "Makefile", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".cmake", .lang = .{ .name = "CMake", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".tex", .lang = .{ .name = "LaTeX", .line_comment = "%", .color = "\x1b[38;5;067m" } },
    .{ .ext = ".vim", .lang = .{ .name = "Vim", .line_comment = "\"", .color = "\x1b[38;5;034m" } },
    .{ .ext = ".m", .lang = .{ .name = "Objective-C", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".mm", .lang = .{ .name = "Objective-C++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".vue", .lang = .{ .name = "Vue", .line_comment = "//", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;154m" } },
    .{ .ext = ".svelte", .lang = .{ .name = "Svelte", .line_comment = "//", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;203m" } },
    .{ .ext = ".sol", .lang = .{ .name = "Solidity", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".tf", .lang = .{ .name = "Terraform", .line_comment = "#", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".nim", .lang = .{ .name = "Nim", .line_comment = "#", .color = "\x1b[38;5;214m" } },
    .{ .ext = ".v", .lang = .{ .name = "V", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;036m" } },
    .{ .ext = ".cr", .lang = .{ .name = "Crystal", .line_comment = "#", .block_open = "=begin", .block_close = "=end", .color = "\x1b[38;5;196m" } },
};

var map: std.StringHashMap(*const Language) = undefined;
var map_init: bool = false;

fn ensureInit() void {
    if (map_init) return;
    map = std.StringHashMap(*const Language).init(std.heap.page_allocator);
    for (&table) |*entry| {
        map.put(entry.ext, &entry.lang) catch {};
    }
    map_init = true;
}

pub fn detect(filename: []const u8) *const Language {
    ensureInit();
    const ext = std.fs.path.extension(filename);
    return map.get(ext) orelse &unknown;
}
