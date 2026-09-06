const std = @import("std");

pub const Language = struct {
    name: []const u8,
    line_comment: ?[]const u8 = null,
    block_open: ?[]const u8 = null,
    block_close: ?[]const u8 = null,
    block_nesting: bool = false,
    /// Single-byte quote delimiters recognized by the lightweight line scanner.
    quotes: []const u8 = "\"'",
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
    filename: ?[]const u8 = null,
    lang: Language,
};

pub const unknown = Language{ .name = "Unknown", .color = "\x1b[37m" };

pub const table = [_]Entry{
    // в”Ђв”Ђ Zig в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".zig", .lang = .{ .name = "Zig", .line_comment = "//", .block_open = "//!", .block_close = null, .color = "\x1b[38;5;208m" } },
    .{ .ext = ".zon", .lang = .{ .name = "Zig", .line_comment = "//", .block_open = "//!", .block_close = null, .color = "\x1b[38;5;208m" } },

    // в”Ђв”Ђ C/C++ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".c", .lang = .{ .name = "C", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".h", .lang = .{ .name = "C", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".cpp", .lang = .{ .name = "C++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".cxx", .lang = .{ .name = "C++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".cc", .lang = .{ .name = "C++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".hpp", .lang = .{ .name = "C++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".hxx", .lang = .{ .name = "C++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".hh", .lang = .{ .name = "C++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".cppm", .lang = .{ .name = "C++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".ixx", .lang = .{ .name = "C++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".inl", .lang = .{ .name = "C++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },

    // в”Ђв”Ђ C# в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".cs", .lang = .{ .name = "C#", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;150m" } },
    .{ .ext = ".csx", .lang = .{ .name = "C#", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;150m" } },

    // в”Ђв”Ђ Java в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".java", .lang = .{ .name = "Java", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".jsp", .lang = .{ .name = "Java", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".kt", .lang = .{ .name = "Kotlin", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".kts", .lang = .{ .name = "Kotlin", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".ktm", .lang = .{ .name = "Kotlin", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".scala", .lang = .{ .name = "Scala", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;203m" } },
    .{ .ext = ".sc", .lang = .{ .name = "Scala", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;203m" } },
    .{ .ext = ".scs", .lang = .{ .name = "Scala", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;203m" } },

    // в”Ђв”Ђ JavaScript / TypeScript в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".js", .lang = .{ .name = "JavaScript", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;220m" } },
    .{ .ext = ".mjs", .lang = .{ .name = "JavaScript", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;220m" } },
    .{ .ext = ".cjs", .lang = .{ .name = "JavaScript", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;220m" } },
    .{ .ext = ".jsx", .lang = .{ .name = "JavaScript", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;220m" } },
    .{ .ext = ".ts", .lang = .{ .name = "TypeScript", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;033m" } },
    .{ .ext = ".mts", .lang = .{ .name = "TypeScript", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;033m" } },
    .{ .ext = ".cts", .lang = .{ .name = "TypeScript", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;033m" } },
    .{ .ext = ".tsx", .lang = .{ .name = "TypeScript", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;033m" } },

    // в”Ђв”Ђ Python в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".py", .lang = .{ .name = "Python", .line_comment = "#", .block_open = "\"\"\"", .block_close = "\"\"\"", .color = "\x1b[38;5;082m" } },
    .{ .ext = ".pyw", .lang = .{ .name = "Python", .line_comment = "#", .block_open = "\"\"\"", .block_close = "\"\"\"", .color = "\x1b[38;5;082m" } },
    .{ .ext = ".pyi", .lang = .{ .name = "Python", .line_comment = "#", .block_open = "\"\"\"", .block_close = "\"\"\"", .color = "\x1b[38;5;082m" } },
    .{ .ext = ".pyt", .lang = .{ .name = "Python", .line_comment = "#", .block_open = "\"\"\"", .block_close = "\"\"\"", .color = "\x1b[38;5;082m" } },
    .{ .ext = ".wsgi", .lang = .{ .name = "Python", .line_comment = "#", .block_open = "\"\"\"", .block_close = "\"\"\"", .color = "\x1b[38;5;082m" } },
    .{ .ext = ".uwsgi", .lang = .{ .name = "Python", .line_comment = "#", .block_open = "\"\"\"", .block_close = "\"\"\"", .color = "\x1b[38;5;082m" } },
    .{ .ext = ".ipy", .lang = .{ .name = "Python", .line_comment = "#", .block_open = "\"\"\"", .block_close = "\"\"\"", .color = "\x1b[38;5;082m" } },
    .{ .ext = ".pyde", .lang = .{ .name = "Python", .line_comment = "#", .block_open = "\"\"\"", .block_close = "\"\"\"", .color = "\x1b[38;5;082m" } },
    .{ .ext = ".pyp", .lang = .{ .name = "Python", .line_comment = "#", .block_open = "\"\"\"", .block_close = "\"\"\"", .color = "\x1b[38;5;082m" } },
    .{ .ext = ".cpy", .lang = .{ .name = "Python", .line_comment = "#", .block_open = "\"\"\"", .block_close = "\"\"\"", .color = "\x1b[38;5;082m" } },
    .{ .ext = ".gyp", .lang = .{ .name = "Python", .line_comment = "#", .block_open = "\"\"\"", .block_close = "\"\"\"", .color = "\x1b[38;5;082m" } },
    .{ .ext = ".gypi", .lang = .{ .name = "Python", .line_comment = "#", .block_open = "\"\"\"", .block_close = "\"\"\"", .color = "\x1b[38;5;082m" } },
    .{ .ext = ".pylintrc", .lang = .{ .name = "Python", .line_comment = "#", .color = "\x1b[38;5;082m" } },
    .{ .ext = ".pypirc", .lang = .{ .name = "Python", .line_comment = "#", .color = "\x1b[38;5;082m" } },
    .{ .ext = ".pythonrc", .lang = .{ .name = "Python", .line_comment = "#", .color = "\x1b[38;5;082m" } },
    .{ .ext = ".pythonstartup", .lang = .{ .name = "Python", .line_comment = "#", .color = "\x1b[38;5;082m" } },

    // в”Ђв”Ђ Go в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".go", .lang = .{ .name = "Go", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;036m" } },
    .{ .ext = ".go.sum", .filename = "go.sum", .lang = .{ .name = "Go", .color = "\x1b[38;5;036m" } },

    // в”Ђв”Ђ Rust в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".rs", .lang = .{ .name = "Rust", .line_comment = "//", .block_open = "/*", .block_close = "*/", .block_nesting = true, .color = "\x1b[38;5;216m" } },
    .{ .ext = ".rs.in", .lang = .{ .name = "Rust", .line_comment = "//", .block_open = "/*", .block_close = "*/", .block_nesting = true, .color = "\x1b[38;5;216m" } },

    // в”Ђв”Ђ Ruby в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".rb", .lang = .{ .name = "Ruby", .line_comment = "#", .block_open = "=begin", .block_close = "=end", .color = "\x1b[38;5;196m" } },
    .{ .ext = ".rake", .lang = .{ .name = "Ruby", .line_comment = "#", .block_open = "=begin", .block_close = "=end", .color = "\x1b[38;5;196m" } },
    .{ .ext = ".gemspec", .lang = .{ .name = "Ruby", .line_comment = "#", .block_open = "=begin", .block_close = "=end", .color = "\x1b[38;5;196m" } },
    .{ .ext = ".rbw", .lang = .{ .name = "Ruby", .line_comment = "#", .block_open = "=begin", .block_close = "=end", .color = "\x1b[38;5;196m" } },
    .{ .ext = ".rbx", .lang = .{ .name = "Ruby", .line_comment = "#", .block_open = "=begin", .block_close = "=end", .color = "\x1b[38;5;196m" } },
    .{ .ext = ".erb", .lang = .{ .name = "Ruby", .line_comment = "#", .block_open = "=begin", .block_close = "=end", .color = "\x1b[38;5;196m" } },
    .{ .ext = ".gemfile", .filename = "Gemfile", .lang = .{ .name = "Ruby", .line_comment = "#", .block_open = "=begin", .block_close = "=end", .color = "\x1b[38;5;196m" } },
    .{ .ext = ".builder", .lang = .{ .name = "Ruby", .line_comment = "#", .block_open = "=begin", .block_close = "=end", .color = "\x1b[38;5;196m" } },
    .{ .ext = ".ru", .lang = .{ .name = "Ruby", .line_comment = "#", .block_open = "=begin", .block_close = "=end", .color = "\x1b[38;5;196m" } },
    .{ .ext = ".podspec", .lang = .{ .name = "Ruby", .line_comment = "#", .block_open = "=begin", .block_close = "=end", .color = "\x1b[38;5;196m" } },
    .{ .ext = ".Vagrantfile", .filename = "Vagrantfile", .lang = .{ .name = "Ruby", .line_comment = "#", .block_open = "=begin", .block_close = "=end", .color = "\x1b[38;5;196m" } },

    // в”Ђв”Ђ PHP в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".php", .lang = .{ .name = "PHP", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;135m" } },
    .{ .ext = ".php3", .lang = .{ .name = "PHP", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;135m" } },
    .{ .ext = ".php4", .lang = .{ .name = "PHP", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;135m" } },
    .{ .ext = ".php5", .lang = .{ .name = "PHP", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;135m" } },
    .{ .ext = ".php7", .lang = .{ .name = "PHP", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;135m" } },
    .{ .ext = ".php8", .lang = .{ .name = "PHP", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;135m" } },
    .{ .ext = ".phtml", .lang = .{ .name = "PHP", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;135m" } },
    .{ .ext = ".phps", .lang = .{ .name = "PHP", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;135m" } },
    .{ .ext = ".inc", .lang = .{ .name = "PHP", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;135m" } },
    .{ .ext = ".phpt", .lang = .{ .name = "PHP", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;135m" } },

    // в”Ђв”Ђ Swift в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".swift", .lang = .{ .name = "Swift", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;214m" } },
    .{ .ext = ".swiftinterface", .lang = .{ .name = "Swift", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;214m" } },

    // в”Ђв”Ђ Dart в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".dart", .lang = .{ .name = "Dart", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;032m" } },

    // в”Ђв”Ђ Lua в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".lua", .lang = .{ .name = "Lua", .line_comment = "--", .block_open = "--[[", .block_close = "]]", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".lua54", .lang = .{ .name = "Lua", .line_comment = "--", .block_open = "--[[", .block_close = "]]", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".luac", .lang = .{ .name = "Lua", .line_comment = "--", .block_open = "--[[", .block_close = "]]", .color = "\x1b[38;5;039m" } },

    // в”Ђв”Ђ Perl в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".pl", .lang = .{ .name = "Perl", .line_comment = "#", .color = "\x1b[38;5;045m" } },
    .{ .ext = ".pm", .lang = .{ .name = "Perl", .line_comment = "#", .color = "\x1b[38;5;045m" } },
    .{ .ext = ".plx", .lang = .{ .name = "Perl", .line_comment = "#", .color = "\x1b[38;5;045m" } },
    .{ .ext = ".perl", .lang = .{ .name = "Perl", .line_comment = "#", .color = "\x1b[38;5;045m" } },
    .{ .ext = ".t", .lang = .{ .name = "Perl", .line_comment = "#", .color = "\x1b[38;5;045m" } },
    .{ .ext = ".psgi", .lang = .{ .name = "Perl", .line_comment = "#", .color = "\x1b[38;5;045m" } },
    .{ .ext = ".cpanfile", .filename = "cpanfile", .lang = .{ .name = "Perl", .line_comment = "#", .color = "\x1b[38;5;045m" } },

    // в”Ђв”Ђ R в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".r", .lang = .{ .name = "R", .line_comment = "#", .color = "\x1b[38;5;249m" } },
    .{ .ext = ".rmd", .lang = .{ .name = "R", .line_comment = "#", .color = "\x1b[38;5;249m" } },
    .{ .ext = ".rms", .lang = .{ .name = "R", .line_comment = "#", .color = "\x1b[38;5;249m" } },
    .{ .ext = ".q", .lang = .{ .name = "R", .line_comment = "#", .color = "\x1b[38;5;249m" } },
    .{ .ext = ".Rprofile", .lang = .{ .name = "R", .line_comment = "#", .color = "\x1b[38;5;249m" } },
    .{ .ext = ".Rproj", .lang = .{ .name = "R", .line_comment = "#", .color = "\x1b[38;5;249m" } },

    // в”Ђв”Ђ Julia в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".jl", .lang = .{ .name = "Julia", .line_comment = "#", .block_open = "#=", .block_close = "=#", .color = "\x1b[38;5;133m" } },

    // в”Ђв”Ђ MATLAB / Octave в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".m", .lang = .{ .name = "Objective-C", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".matlab", .lang = .{ .name = "MATLAB", .line_comment = "%", .block_open = "%{", .block_close = "%}", .color = "\x1b[38;5;019m" } },
    .{ .ext = ".octave", .lang = .{ .name = "MATLAB", .line_comment = "%", .block_open = "%{", .block_close = "%}", .color = "\x1b[38;5;019m" } },
    .{ .ext = ".mex", .lang = .{ .name = "MATLAB", .line_comment = "%", .block_open = "%{", .block_close = "%}", .color = "\x1b[38;5;019m" } },
    .{ .ext = ".mexa64", .lang = .{ .name = "MATLAB", .line_comment = "%", .block_open = "%{", .block_close = "%}", .color = "\x1b[38;5;019m" } },
    .{ .ext = ".mexmaci64", .lang = .{ .name = "MATLAB", .line_comment = "%", .block_open = "%{", .block_close = "%}", .color = "\x1b[38;5;019m" } },
    .{ .ext = ".mexw64", .lang = .{ .name = "MATLAB", .line_comment = "%", .block_open = "%{", .block_close = "%}", .color = "\x1b[38;5;019m" } },
    .{ .ext = ".mn", .lang = .{ .name = "MATLAB", .line_comment = "%", .block_open = "%{", .block_close = "%}", .color = "\x1b[38;5;019m" } },

    // в”Ђв”Ђ Haskell в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".hs", .lang = .{ .name = "Haskell", .line_comment = "--", .block_open = "{-", .block_close = "-}", .color = "\x1b[38;5;140m" } },
    .{ .ext = ".lhs", .lang = .{ .name = "Haskell", .line_comment = "--", .block_open = "{-", .block_close = "-}", .color = "\x1b[38;5;140m" } },
    .{ .ext = ".hsc", .lang = .{ .name = "Haskell", .line_comment = "--", .block_open = "{-", .block_close = "-}", .color = "\x1b[38;5;140m" } },
    .{ .ext = ".cabal", .lang = .{ .name = "Haskell", .line_comment = "--", .block_open = "{-", .block_close = "-}", .color = "\x1b[38;5;140m" } },

    // в”Ђв”Ђ OCaml в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".ml", .lang = .{ .name = "OCaml", .line_comment = null, .block_open = "(*", .block_close = "*)", .color = "\x1b[38;5;209m" } },
    .{ .ext = ".mli", .lang = .{ .name = "OCaml", .line_comment = null, .block_open = "(*", .block_close = "*)", .color = "\x1b[38;5;209m" } },
    .{ .ext = ".mll", .lang = .{ .name = "OCaml", .line_comment = null, .block_open = "(*", .block_close = "*)", .color = "\x1b[38;5;209m" } },
    .{ .ext = ".mly", .lang = .{ .name = "OCaml", .line_comment = null, .block_open = "(*", .block_close = "*)", .color = "\x1b[38;5;209m" } },

    // в”Ђв”Ђ Elixir в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".ex", .lang = .{ .name = "Elixir", .line_comment = "#", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".exs", .lang = .{ .name = "Elixir", .line_comment = "#", .color = "\x1b[38;5;141m" } },

    // в”Ђв”Ђ Erlang в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".erl", .lang = .{ .name = "Erlang", .line_comment = "%", .color = "\x1b[38;5;033m" } },
    .{ .ext = ".hrl", .lang = .{ .name = "Erlang", .line_comment = "%", .color = "\x1b[38;5;033m" } },
    .{ .ext = ".escript", .lang = .{ .name = "Erlang", .line_comment = "%", .color = "\x1b[38;5;033m" } },

    // в”Ђв”Ђ Clojure в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".clj", .lang = .{ .name = "Clojure", .line_comment = ";", .color = "\x1b[38;5;036m" } },
    .{ .ext = ".cljs", .lang = .{ .name = "ClojureScript", .line_comment = ";", .color = "\x1b[38;5;036m" } },
    .{ .ext = ".cljc", .lang = .{ .name = "Clojure", .line_comment = ";", .color = "\x1b[38;5;036m" } },
    .{ .ext = ".cljd", .lang = .{ .name = "Clojure", .line_comment = ";", .color = "\x1b[38;5;036m" } },
    .{ .ext = ".edn", .lang = .{ .name = "Clojure", .line_comment = ";", .color = "\x1b[38;5;036m" } },

    // в”Ђв”Ђ Lisp в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".lisp", .lang = .{ .name = "Lisp", .line_comment = ";", .block_open = "#|", .block_close = "|#", .color = "\x1b[38;5;219m" } },
    .{ .ext = ".lsp", .lang = .{ .name = "Lisp", .line_comment = ";", .block_open = "#|", .block_close = "|#", .color = "\x1b[38;5;219m" } },
    .{ .ext = ".l", .lang = .{ .name = "Lisp", .line_comment = ";", .block_open = "#|", .block_close = "|#", .color = "\x1b[38;5;219m" } },
    .{ .ext = ".el", .lang = .{ .name = "Emacs Lisp", .line_comment = ";", .block_open = "#|", .block_close = "|#", .color = "\x1b[38;5;140m" } },
    .{ .ext = ".elv", .lang = .{ .name = "Elvish", .line_comment = "#", .color = "\x1b[38;5;109m" } },

    // в”Ђв”Ђ Scheme в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".scm", .lang = .{ .name = "Scheme", .line_comment = ";", .block_open = "#|", .block_close = "|#", .color = "\x1b[38;5;168m" } },
    .{ .ext = ".ss", .lang = .{ .name = "Scheme", .line_comment = ";", .block_open = "#|", .block_close = "|#", .color = "\x1b[38;5;168m" } },
    .{ .ext = ".sls", .lang = .{ .name = "Scheme", .line_comment = ";", .block_open = "#|", .block_close = "|#", .color = "\x1b[38;5;168m" } },
    .{ .ext = ".sps", .lang = .{ .name = "Scheme", .line_comment = ";", .block_open = "#|", .block_close = "|#", .color = "\x1b[38;5;168m" } },
    .{ .ext = ".rkt", .lang = .{ .name = "Racket", .line_comment = ";", .block_open = "#|", .block_close = "|#", .color = "\x1b[38;5;168m" } },
    .{ .ext = ".rktd", .lang = .{ .name = "Racket", .line_comment = ";", .block_open = "#|", .block_close = "|#", .color = "\x1b[38;5;168m" } },
    .{ .ext = ".rktl", .lang = .{ .name = "Racket", .line_comment = ";", .block_open = "#|", .block_close = "|#", .color = "\x1b[38;5;168m" } },

    // в”Ђв”Ђ F# в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".fs", .lang = .{ .name = "F#", .line_comment = "//", .block_open = "(*", .block_close = "*)", .color = "\x1b[38;5;074m" } },
    .{ .ext = ".fsx", .lang = .{ .name = "F#", .line_comment = "//", .block_open = "(*", .block_close = "*)", .color = "\x1b[38;5;074m" } },
    .{ .ext = ".fsi", .lang = .{ .name = "F#", .line_comment = "//", .block_open = "(*", .block_close = "*)", .color = "\x1b[38;5;074m" } },
    .{ .ext = ".fsproj", .lang = .{ .name = "F#", .color = "\x1b[38;5;074m" } },

    // в”Ђв”Ђ Elm в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".elm", .lang = .{ .name = "Elm", .line_comment = "--", .block_open = "{-", .block_close = "-}", .color = "\x1b[38;5;081m" } },

    // в”Ђв”Ђ PureScript в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".purs", .lang = .{ .name = "PureScript", .line_comment = "--", .block_open = "{-", .block_close = "-}", .color = "\x1b[38;5;207m" } },

    // в”Ђв”Ђ Idris в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".idr", .lang = .{ .name = "Idris", .line_comment = "--", .block_open = "{-", .block_close = "-}", .color = "\x1b[38;5;167m" } },
    .{ .ext = ".ipkg", .lang = .{ .name = "Idris", .line_comment = "--", .color = "\x1b[38;5;167m" } },

    // в”Ђв”Ђ Lean в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".lean", .lang = .{ .name = "Lean", .line_comment = "--", .block_open = "/-", .block_close = "-/", .color = "\x1b[38;5;033m" } },

    // в”Ђв”Ђ Agda в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".agda", .lang = .{ .name = "Agda", .line_comment = "--", .color = "\x1b[38;5;203m" } },
    .{ .ext = ".lagda", .lang = .{ .name = "Agda", .line_comment = "--", .color = "\x1b[38;5;203m" } },
    .{ .ext = ".lagda.md", .lang = .{ .name = "Agda", .line_comment = "--", .color = "\x1b[38;5;203m" } },
    .{ .ext = ".lagda.rst", .lang = .{ .name = "Agda", .line_comment = "--", .color = "\x1b[38;5;203m" } },
    .{ .ext = ".lagda.tex", .lang = .{ .name = "Agda", .line_comment = "--", .color = "\x1b[38;5;203m" } },

    // в”Ђв”Ђ Coq в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".v", .lang = .{ .name = "V", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;036m" } },

    // в”Ђв”Ђ Nim в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".nim", .lang = .{ .name = "Nim", .line_comment = "#", .block_open = null, .block_close = null, .color = "\x1b[38;5;214m" } },
    .{ .ext = ".nimble", .lang = .{ .name = "Nim", .line_comment = "#", .color = "\x1b[38;5;214m" } },
    .{ .ext = ".nims", .lang = .{ .name = "Nim", .line_comment = "#", .color = "\x1b[38;5;214m" } },
    .{ .ext = ".cfg", .lang = .{ .name = "Nim", .line_comment = "#", .color = "\x1b[38;5;214m" } },

    // в”Ђв”Ђ Crystal в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".cr", .lang = .{ .name = "Crystal", .line_comment = "#", .block_open = "=begin", .block_close = "=end", .color = "\x1b[38;5;196m" } },

    // в”Ђв”Ђ V в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    // (already .v above as Coq вЂ” V uses .v too, keeping last definition)
    .{ .ext = ".vsh", .lang = .{ .name = "V", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;036m" } },

    // в”Ђв”Ђ Groovy в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".groovy", .lang = .{ .name = "Groovy", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;077m" } },
    .{ .ext = ".gvy", .lang = .{ .name = "Groovy", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;077m" } },
    .{ .ext = ".gy", .lang = .{ .name = "Groovy", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;077m" } },
    .{ .ext = ".gsh", .lang = .{ .name = "Groovy", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;077m" } },
    .{ .ext = ".gradle", .lang = .{ .name = "Groovy", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;077m" } },
    .{ .ext = ".gradle.kts", .lang = .{ .name = "Kotlin", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;141m" } },

    // в”Ђв”Ђ CoffeeScript в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".coffee", .lang = .{ .name = "CoffeeScript", .line_comment = "#", .block_open = "###", .block_close = "###", .color = "\x1b[38;5;180m" } },
    .{ .ext = ".litcoffee", .lang = .{ .name = "CoffeeScript", .line_comment = "#", .block_open = "###", .block_close = "###", .color = "\x1b[38;5;180m" } },
    .{ .ext = ".cjsx", .lang = .{ .name = "CoffeeScript", .line_comment = "#", .block_open = "###", .block_close = "###", .color = "\x1b[38;5;180m" } },

    // в”Ђв”Ђ LiveScript в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".ls", .lang = .{ .name = "LiveScript", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;113m" } },

    // в”Ђв”Ђ MoonScript в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".moon", .lang = .{ .name = "MoonScript", .line_comment = "--", .color = "\x1b[38;5;224m" } },

    // в”Ђв”Ђ Fortran в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".f", .lang = .{ .name = "Fortran", .line_comment = "!", .color = "\x1b[38;5;073m" } },
    .{ .ext = ".for", .lang = .{ .name = "Fortran", .line_comment = "!", .color = "\x1b[38;5;073m" } },
    .{ .ext = ".f90", .lang = .{ .name = "Fortran", .line_comment = "!", .color = "\x1b[38;5;073m" } },
    .{ .ext = ".f95", .lang = .{ .name = "Fortran", .line_comment = "!", .color = "\x1b[38;5;073m" } },
    .{ .ext = ".f03", .lang = .{ .name = "Fortran", .line_comment = "!", .color = "\x1b[38;5;073m" } },
    .{ .ext = ".f08", .lang = .{ .name = "Fortran", .line_comment = "!", .color = "\x1b[38;5;073m" } },
    .{ .ext = ".f18", .lang = .{ .name = "Fortran", .line_comment = "!", .color = "\x1b[38;5;073m" } },
    .{ .ext = ".fpp", .lang = .{ .name = "Fortran", .line_comment = "!", .color = "\x1b[38;5;073m" } },

    // в”Ђв”Ђ Pascal / Delphi в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".pas", .lang = .{ .name = "Pascal", .line_comment = "//", .block_open = "{", .block_close = "}", .color = "\x1b[38;5;218m" } },
    .{ .ext = ".pp", .lang = .{ .name = "Pascal", .line_comment = "//", .block_open = "{", .block_close = "}", .color = "\x1b[38;5;218m" } },
    .{ .ext = ".lpr", .lang = .{ .name = "Pascal", .line_comment = "//", .block_open = "{", .block_close = "}", .color = "\x1b[38;5;218m" } },
    .{ .ext = ".dpr", .lang = .{ .name = "Delphi", .line_comment = "//", .block_open = "{", .block_close = "}", .color = "\x1b[38;5;218m" } },
    .{ .ext = ".dpk", .lang = .{ .name = "Delphi", .line_comment = "//", .block_open = "{", .block_close = "}", .color = "\x1b[38;5;218m" } },
    .{ .ext = ".dfm", .lang = .{ .name = "Delphi", .line_comment = "//", .block_open = "{", .block_close = "}", .color = "\x1b[38;5;218m" } },
    .{ .ext = ".fmx", .lang = .{ .name = "Delphi", .line_comment = "//", .block_open = "{", .block_close = "}", .color = "\x1b[38;5;218m" } },

    // в”Ђв”Ђ Ada в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".adb", .lang = .{ .name = "Ada", .line_comment = "--", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".ads", .lang = .{ .name = "Ada", .line_comment = "--", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".ad", .lang = .{ .name = "Ada", .line_comment = "--", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".gpr", .lang = .{ .name = "Ada", .line_comment = "--", .color = "\x1b[38;5;141m" } },

    // в”Ђв”Ђ COBOL в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".cob", .lang = .{ .name = "COBOL", .line_comment = null, .color = "\x1b[38;5;107m" } },
    .{ .ext = ".cbl", .lang = .{ .name = "COBOL", .line_comment = null, .color = "\x1b[38;5;107m" } },
    .{ .ext = ".ccp", .lang = .{ .name = "COBOL", .line_comment = null, .color = "\x1b[38;5;107m" } },

    // в”Ђв”Ђ Assembly в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".asm", .lang = .{ .name = "Assembly", .line_comment = ";", .color = "\x1b[38;5;242m" } },
    .{ .ext = ".s", .lang = .{ .name = "Assembly", .line_comment = ";", .color = "\x1b[38;5;242m" } },
    .{ .ext = ".nasm", .lang = .{ .name = "Assembly", .line_comment = ";", .color = "\x1b[38;5;242m" } },
    .{ .ext = ".a51", .lang = .{ .name = "Assembly", .line_comment = ";", .color = "\x1b[38;5;242m" } },
    .{ .ext = ".29k", .lang = .{ .name = "Assembly", .line_comment = ";", .color = "\x1b[38;5;242m" } },
    .{ .ext = ".68k", .lang = .{ .name = "Assembly", .line_comment = ";", .color = "\x1b[38;5;242m" } },

    // в”Ђв”Ђ Shell в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".sh", .lang = .{ .name = "Shell", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".bash", .lang = .{ .name = "Bash", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".zsh", .lang = .{ .name = "Zsh", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".fish", .lang = .{ .name = "Fish", .line_comment = "#", .color = "\x1b[38;5;109m" } },
    .{ .ext = ".csh", .lang = .{ .name = "Csh", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".tcsh", .lang = .{ .name = "Tcsh", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".ksh", .lang = .{ .name = "Ksh", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".bashrc", .lang = .{ .name = "Bash", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".bash_profile", .lang = .{ .name = "Bash", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".zshrc", .lang = .{ .name = "Zsh", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".zshenv", .lang = .{ .name = "Zsh", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".zprofile", .lang = .{ .name = "Zsh", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".fish_history", .lang = .{ .name = "Fish", .line_comment = "#", .color = "\x1b[38;5;109m" } },
    .{ .ext = ".inputrc", .lang = .{ .name = "Shell", .line_comment = "#", .color = "\x1b[38;5;078m" } },

    // в”Ђв”Ђ PowerShell в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".ps1", .lang = .{ .name = "PowerShell", .line_comment = "#", .block_open = "<#", .block_close = "#>", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".psm1", .lang = .{ .name = "PowerShell", .line_comment = "#", .block_open = "<#", .block_close = "#>", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".psd1", .lang = .{ .name = "PowerShell", .line_comment = "#", .block_open = "<#", .block_close = "#>", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".ps1xml", .lang = .{ .name = "PowerShell", .line_comment = "#", .block_open = "<#", .block_close = "#>", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".psc1", .lang = .{ .name = "PowerShell", .line_comment = "#", .block_open = "<#", .block_close = "#>", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".psrc", .lang = .{ .name = "PowerShell", .line_comment = "#", .block_open = "<#", .block_close = "#>", .color = "\x1b[38;5;039m" } },

    // в”Ђв”Ђ Batch / CMD в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".bat", .lang = .{ .name = "Batch", .line_comment = "REM", .color = "\x1b[38;5;244m" } },
    .{ .ext = ".cmd", .lang = .{ .name = "Batch", .line_comment = "REM", .color = "\x1b[38;5;244m" } },
    .{ .ext = ".btm", .lang = .{ .name = "Batch", .line_comment = "REM", .color = "\x1b[38;5;244m" } },

    // в”Ђв”Ђ AWK в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".awk", .lang = .{ .name = "AWK", .line_comment = "#", .color = "\x1b[38;5;140m" } },
    .{ .ext = ".gawk", .lang = .{ .name = "AWK", .line_comment = "#", .color = "\x1b[38;5;140m" } },
    .{ .ext = ".nawk", .lang = .{ .name = "AWK", .line_comment = "#", .color = "\x1b[38;5;140m" } },
    .{ .ext = ".mawk", .lang = .{ .name = "AWK", .line_comment = "#", .color = "\x1b[38;5;140m" } },
    .{ .ext = ".pawk", .lang = .{ .name = "AWK", .line_comment = "#", .color = "\x1b[38;5;140m" } },

    // в”Ђв”Ђ Tcl в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".tcl", .lang = .{ .name = "Tcl", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".tk", .lang = .{ .name = "Tcl", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".itcl", .lang = .{ .name = "Tcl", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".expect", .lang = .{ .name = "Tcl", .line_comment = "#", .color = "\x1b[38;5;078m" } },

    // в”Ђв”Ђ Prolog в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".pro", .lang = .{ .name = "Prolog", .line_comment = "%", .color = "\x1b[38;5;226m" } },
    .{ .ext = ".prolog", .lang = .{ .name = "Prolog", .line_comment = "%", .color = "\x1b[38;5;226m" } },
    .{ .ext = ".yap", .lang = .{ .name = "Prolog", .line_comment = "%", .color = "\x1b[38;5;226m" } },

    // в”Ђв”Ђ SQL в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".sql", .lang = .{ .name = "SQL", .line_comment = "--", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;220m" } },
    .{ .ext = ".ddl", .lang = .{ .name = "SQL", .line_comment = "--", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;220m" } },
    .{ .ext = ".dml", .lang = .{ .name = "SQL", .line_comment = "--", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;220m" } },
    .{ .ext = ".pls", .lang = .{ .name = "PL/SQL", .line_comment = "--", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;220m" } },
    .{ .ext = ".plsql", .lang = .{ .name = "PL/SQL", .line_comment = "--", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;220m" } },
    .{ .ext = ".pgsql", .lang = .{ .name = "PL/pgSQL", .line_comment = "--", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;220m" } },
    .{ .ext = ".cql", .lang = .{ .name = "CQL", .line_comment = "--", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;220m" } },
    .{ .ext = ".hql", .lang = .{ .name = "HiveQL", .line_comment = "--", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;220m" } },
    .{ .ext = ".tsql", .lang = .{ .name = "T-SQL", .line_comment = "--", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;220m" } },

    // в”Ђв”Ђ Visual Basic в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".vb", .lang = .{ .name = "Visual Basic", .line_comment = "'", .color = "\x1b[38;5;074m" } },
    .{ .ext = ".bas", .lang = .{ .name = "Visual Basic", .line_comment = "'", .color = "\x1b[38;5;074m" } },
    .{ .ext = ".cls", .lang = .{ .name = "Visual Basic", .line_comment = "'", .color = "\x1b[38;5;074m" } },
    .{ .ext = ".frm", .lang = .{ .name = "Visual Basic", .line_comment = "'", .color = "\x1b[38;5;074m" } },
    .{ .ext = ".vbs", .lang = .{ .name = "VBScript", .line_comment = "'", .color = "\x1b[38;5;074m" } },
    .{ .ext = ".vba", .lang = .{ .name = "VBA", .line_comment = "'", .color = "\x1b[38;5;074m" } },

    // в”Ђв”Ђ AutoHotkey в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".ahk", .lang = .{ .name = "AutoHotkey", .line_comment = ";", .color = "\x1b[38;5;167m" } },
    .{ .ext = ".ahkl", .lang = .{ .name = "AutoHotkey", .line_comment = ";", .color = "\x1b[38;5;167m" } },

    // в”Ђв”Ђ AutoIt в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".au3", .lang = .{ .name = "AutoIt", .line_comment = ";", .color = "\x1b[38;5;106m" } },

    // в”Ђв”Ђ AppleScript в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".applescript", .lang = .{ .name = "AppleScript", .line_comment = "--", .color = "\x1b[38;5;218m" } },
    .{ .ext = ".scpt", .lang = .{ .name = "AppleScript", .line_comment = "--", .color = "\x1b[38;5;218m" } },

    // в”Ђв”Ђ Applescript (JS for Automation) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

    // в”Ђв”Ђ HTML / Web в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".html", .lang = .{ .name = "HTML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".htm", .lang = .{ .name = "HTML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".xhtml", .lang = .{ .name = "HTML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".html.vue", .lang = .{ .name = "HTML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".shtml", .lang = .{ .name = "HTML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".stm", .lang = .{ .name = "HTML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".cfm", .lang = .{ .name = "HTML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".tmpl", .lang = .{ .name = "HTML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".tpl", .lang = .{ .name = "HTML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".hbs", .lang = .{ .name = "HTML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".ejs", .lang = .{ .name = "HTML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".pug", .lang = .{ .name = "Pug", .line_comment = "//-", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".jade", .lang = .{ .name = "Pug", .line_comment = "//-", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".njk", .lang = .{ .name = "HTML", .block_open = "{#", .block_close = "#}", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".liquid", .lang = .{ .name = "HTML", .block_open = "{% comment %}", .block_close = "{% endcomment %}", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".twig", .lang = .{ .name = "HTML", .block_open = "{#", .block_close = "#}", .color = "\x1b[38;5;202m" } },
    .{ .ext = ".blade.php", .lang = .{ .name = "HTML", .block_open = "{{--", .block_close = "--}}", .color = "\x1b[38;5;202m" } },

    // в”Ђв”Ђ CSS / Preprocessors в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".css", .lang = .{ .name = "CSS", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".scss", .lang = .{ .name = "SCSS", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;205m" } },
    .{ .ext = ".sass", .lang = .{ .name = "Sass", .line_comment = "//", .color = "\x1b[38;5;205m" } },
    .{ .ext = ".less", .lang = .{ .name = "Less", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },
    .{ .ext = ".styl", .lang = .{ .name = "Stylus", .line_comment = "//", .color = "\x1b[38;5;113m" } },

    // в”Ђв”Ђ JavaScript Frameworks в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".vue", .lang = .{ .name = "Vue", .line_comment = "//", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;154m" } },
    .{ .ext = ".svelte", .lang = .{ .name = "Svelte", .line_comment = "//", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;203m" } },
    .{ .ext = ".astro", .lang = .{ .name = "Astro", .line_comment = "//", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;207m" } },
    .{ .ext = ".mdx", .lang = .{ .name = "MDX", .line_comment = "//", .block_open = "{/*", .block_close = "*/}", .color = "\x1b[38;5;208m" } },

    // в”Ђв”Ђ XML в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".xml", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".xsd", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".xsl", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".xslt", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".svg", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".csproj", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".vbproj", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".vcxproj", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".props", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".targets", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".plist", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".resx", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".axml", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".xaml", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".nuspec", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".atom", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".rss", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".opml", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".kml", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".gpx", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".vcproj", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".vsproj", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".build", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".rdf", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".wsdl", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },
    .{ .ext = ".wml", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },

    // в”Ђв”Ђ JSON в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".json", .lang = .{ .name = "JSON", .color = "\x1b[38;5;227m" } },
    .{ .ext = ".jsonc", .lang = .{ .name = "JSON", .line_comment = "//", .color = "\x1b[38;5;227m" } },
    .{ .ext = ".json5", .lang = .{ .name = "JSON", .line_comment = "//", .color = "\x1b[38;5;227m" } },
    .{ .ext = ".jsonl", .lang = .{ .name = "JSON", .color = "\x1b[38;5;227m" } },
    .{ .ext = ".ndjson", .lang = .{ .name = "JSON", .color = "\x1b[38;5;227m" } },
    .{ .ext = ".geojson", .lang = .{ .name = "JSON", .color = "\x1b[38;5;227m" } },
    .{ .ext = ".jsonld", .lang = .{ .name = "JSON", .color = "\x1b[38;5;227m" } },
    .{ .ext = ".webmanifest", .lang = .{ .name = "JSON", .color = "\x1b[38;5;227m" } },
    .{ .ext = ".browserslistrc", .lang = .{ .name = "JSON", .color = "\x1b[38;5;227m" } },
    .{ .ext = ".tsconfig", .lang = .{ .name = "JSON", .color = "\x1b[38;5;227m" } },
    .{ .ext = ".composer", .lang = .{ .name = "JSON", .color = "\x1b[38;5;227m" } },

    // в”Ђв”Ђ YAML в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".yaml", .lang = .{ .name = "YAML", .line_comment = "#", .color = "\x1b[38;5;167m" } },
    .{ .ext = ".yml", .lang = .{ .name = "YAML", .line_comment = "#", .color = "\x1b[38;5;167m" } },
    .{ .ext = ".yaml-tmlanguage", .lang = .{ .name = "YAML", .line_comment = "#", .color = "\x1b[38;5;167m" } },
    .{ .ext = ".yml.tmpl", .lang = .{ .name = "YAML", .line_comment = "#", .color = "\x1b[38;5;167m" } },
    .{ .ext = ".yaml.tmpl", .lang = .{ .name = "YAML", .line_comment = "#", .color = "\x1b[38;5;167m" } },

    // в”Ђв”Ђ TOML в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".toml", .lang = .{ .name = "TOML", .line_comment = "#", .color = "\x1b[38;5;215m" } },
    .{ .ext = ".tml", .lang = .{ .name = "TOML", .line_comment = "#", .color = "\x1b[38;5;215m" } },

    // в”Ђв”Ђ INI / Config в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".ini", .lang = .{ .name = "INI", .line_comment = ";", .color = "\x1b[38;5;248m" } },
    .{ .ext = ".conf", .lang = .{ .name = "INI", .line_comment = ";", .color = "\x1b[38;5;248m" } },
    .{ .ext = ".config", .lang = .{ .name = "INI", .line_comment = ";", .color = "\x1b[38;5;248m" } },
    .{ .ext = ".properties", .lang = .{ .name = "Java Properties", .line_comment = "#", .color = "\x1b[38;5;248m" } },
    .{ .ext = ".env", .lang = .{ .name = "Env", .line_comment = "#", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".env.local", .lang = .{ .name = "Env", .line_comment = "#", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".env.development", .lang = .{ .name = "Env", .line_comment = "#", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".env.production", .lang = .{ .name = "Env", .line_comment = "#", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".editorconfig", .lang = .{ .name = "INI", .line_comment = "#", .color = "\x1b[38;5;248m" } },

    // в”Ђв”Ђ CSV / Data в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".csv", .lang = .{ .name = "CSV", .color = "\x1b[38;5;251m" } },
    .{ .ext = ".tsv", .lang = .{ .name = "TSV", .color = "\x1b[38;5;251m" } },
    .{ .ext = ".psv", .lang = .{ .name = "PSV", .color = "\x1b[38;5;251m" } },
    .{ .ext = ".ssv", .lang = .{ .name = "SSV", .color = "\x1b[38;5;251m" } },

    // в”Ђв”Ђ Protobuf / Schema в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".proto", .lang = .{ .name = "Protobuf", .line_comment = "//", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".thrift", .lang = .{ .name = "Thrift", .line_comment = "//", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".avsc", .lang = .{ .name = "Avro", .line_comment = "//", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".avdl", .lang = .{ .name = "Avro", .line_comment = "//", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".capnp", .lang = .{ .name = "Cap'n Proto", .line_comment = "#", .color = "\x1b[38;5;208m" } },
    .{ .ext = ".fbs", .lang = .{ .name = "FlatBuffers", .line_comment = "//", .color = "\x1b[38;5;109m" } },
    .{ .ext = ".graphql", .lang = .{ .name = "GraphQL", .line_comment = "#", .color = "\x1b[38;5;199m" } },
    .{ .ext = ".gql", .lang = .{ .name = "GraphQL", .line_comment = "#", .color = "\x1b[38;5;199m" } },

    // в”Ђв”Ђ Markdown / Docs в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".md", .lang = .{ .name = "Markdown", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".markdown", .lang = .{ .name = "Markdown", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".mdown", .lang = .{ .name = "Markdown", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".mkd", .lang = .{ .name = "Markdown", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".mkdn", .lang = .{ .name = "Markdown", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".mdwn", .lang = .{ .name = "Markdown", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".mdtxt", .lang = .{ .name = "Markdown", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".mdtext", .lang = .{ .name = "Markdown", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".worknotes", .lang = .{ .name = "Markdown", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".livemd", .lang = .{ .name = "Markdown", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".rst", .lang = .{ .name = "reStructuredText", .color = "\x1b[38;5;230m" } },
    .{ .ext = ".adoc", .lang = .{ .name = "AsciiDoc", .line_comment = "//", .color = "\x1b[38;5;230m" } },
    .{ .ext = ".asciidoc", .lang = .{ .name = "AsciiDoc", .line_comment = "//", .color = "\x1b[38;5;230m" } },
    .{ .ext = ".textile", .lang = .{ .name = "Textile", .color = "\x1b[38;5;230m" } },
    .{ .ext = ".org", .lang = .{ .name = "Org", .line_comment = "#", .color = "\x1b[38;5;140m" } },
    .{ .ext = ".typ", .lang = .{ .name = "Typst", .line_comment = "//", .color = "\x1b[38;5;081m" } },
    .{ .ext = ".tex", .lang = .{ .name = "LaTeX", .line_comment = "%", .color = "\x1b[38;5;067m" } },
    .{ .ext = ".sty", .lang = .{ .name = "LaTeX", .line_comment = "%", .color = "\x1b[38;5;067m" } },
    .{ .ext = ".bib", .lang = .{ .name = "LaTeX", .line_comment = "%", .color = "\x1b[38;5;067m" } },
    .{ .ext = ".bst", .lang = .{ .name = "LaTeX", .line_comment = "%", .color = "\x1b[38;5;067m" } },
    .{ .ext = ".dtx", .lang = .{ .name = "LaTeX", .line_comment = "%", .color = "\x1b[38;5;067m" } },
    .{ .ext = ".ins", .lang = .{ .name = "LaTeX", .line_comment = "%", .color = "\x1b[38;5;067m" } },
    .{ .ext = ".ltx", .lang = .{ .name = "LaTeX", .line_comment = "%", .color = "\x1b[38;5;067m" } },

    // в”Ђв”Ђ Vim / Neovim в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".vim", .lang = .{ .name = "Vim", .line_comment = "\"", .color = "\x1b[38;5;034m" } },
    .{ .ext = ".vimrc", .lang = .{ .name = "Vim", .line_comment = "\"", .color = "\x1b[38;5;034m" } },
    .{ .ext = ".nvim", .lang = .{ .name = "Vim", .line_comment = "\"", .color = "\x1b[38;5;034m" } },
    .{ .ext = ".nvimrc", .lang = .{ .name = "Vim", .line_comment = "\"", .color = "\x1b[38;5;034m" } },
    .{ .ext = ".exrc", .lang = .{ .name = "Vim", .line_comment = "\"", .color = "\x1b[38;5;034m" } },

    // в”Ђв”Ђ Emacs в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".elc", .lang = .{ .name = "Emacs Lisp", .line_comment = ";", .block_open = "#|", .block_close = "|#", .color = "\x1b[38;5;140m" } },
    .{ .ext = ".eld", .lang = .{ .name = "Emacs Lisp", .line_comment = ";", .block_open = "#|", .block_close = "|#", .color = "\x1b[38;5;140m" } },

    // в”Ђв”Ђ Objective-C / C++ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".mm", .lang = .{ .name = "Objective-C++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;075m" } },

    // в”Ђв”Ђ VHDL / Verilog в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".vhd", .lang = .{ .name = "VHDL", .line_comment = "--", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".vhdl", .lang = .{ .name = "VHDL", .line_comment = "--", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".vhdx", .lang = .{ .name = "VHDL", .line_comment = "--", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".sv", .lang = .{ .name = "SystemVerilog", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".svh", .lang = .{ .name = "SystemVerilog", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".uvm", .lang = .{ .name = "SystemVerilog", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;113m" } },

    // в”Ђв”Ђ GLSL / HLSL / Shaders в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".glsl", .lang = .{ .name = "GLSL", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".vert", .lang = .{ .name = "GLSL", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".frag", .lang = .{ .name = "GLSL", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".geom", .lang = .{ .name = "GLSL", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".tesc", .lang = .{ .name = "GLSL", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".tese", .lang = .{ .name = "GLSL", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".comp", .lang = .{ .name = "GLSL", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".hlsl", .lang = .{ .name = "HLSL", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;104m" } },
    .{ .ext = ".fx", .lang = .{ .name = "HLSL", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;104m" } },
    .{ .ext = ".fxh", .lang = .{ .name = "HLSL", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;104m" } },
    .{ .ext = ".cg", .lang = .{ .name = "Cg", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;104m" } },
    .{ .ext = ".metal", .lang = .{ .name = "Metal", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;248m" } },
    .{ .ext = ".wgsl", .lang = .{ .name = "WGSL", .line_comment = "//", .color = "\x1b[38;5;248m" } },
    .{ .ext = ".usf", .lang = .{ .name = "HLSL", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;104m" } },
    .{ .ext = ".ush", .lang = .{ .name = "HLSL", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;104m" } },

    // в”Ђв”Ђ Game Scripting в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".gd", .lang = .{ .name = "GDScript", .line_comment = "#", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".gdshader", .lang = .{ .name = "Godot Shader", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".tres", .lang = .{ .name = "Godot", .line_comment = ";", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".tscn", .lang = .{ .name = "Godot", .line_comment = ";", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".gml", .lang = .{ .name = "GML", .line_comment = "//", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".lsl", .lang = .{ .name = "LSL", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".as", .lang = .{ .name = "AngelScript", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;214m" } },
    .{ .ext = ".nut", .lang = .{ .name = "Squirrel", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;180m" } },
    .{ .ext = ".pawn", .lang = .{ .name = "Pawn", .line_comment = "//", .color = "\x1b[38;5;180m" } },
    .{ .ext = ".pwn", .lang = .{ .name = "Pawn", .line_comment = "//", .color = "\x1b[38;5;180m" } },
    .{ .ext = ".uc", .lang = .{ .name = "UnrealScript", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;104m" } },

    // в”Ђв”Ђ Terraform / HCL в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".tf", .lang = .{ .name = "Terraform", .line_comment = "#", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".tfvars", .lang = .{ .name = "Terraform", .line_comment = "#", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".tf.json", .lang = .{ .name = "Terraform", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".hcl", .lang = .{ .name = "HCL", .line_comment = "#", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".nomad", .lang = .{ .name = "HCL", .line_comment = "#", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".pkr", .lang = .{ .name = "HCL", .line_comment = "#", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".pkr.hcl", .lang = .{ .name = "HCL", .line_comment = "#", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;141m" } },

    // в”Ђв”Ђ Nix в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".nix", .lang = .{ .name = "Nix", .line_comment = "#", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".nixos", .lang = .{ .name = "Nix", .line_comment = "#", .color = "\x1b[38;5;113m" } },

    // в”Ђв”Ђ Solidity в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".sol", .lang = .{ .name = "Solidity", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;039m" } },
    .{ .ext = ".vy", .lang = .{ .name = "Vyper", .line_comment = "#", .color = "\x1b[38;5;113m" } },

    // в”Ђв”Ђ Build Systems в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".cmake", .lang = .{ .name = "CMake", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".mk", .lang = .{ .name = "Makefile", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".mak", .lang = .{ .name = "Makefile", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".make", .lang = .{ .name = "Makefile", .line_comment = "#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".ninja", .lang = .{ .name = "Ninja", .line_comment = "#", .color = "\x1b[38;5;244m" } },
    .{ .ext = ".bzl", .lang = .{ .name = "Starlark", .line_comment = "#", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".star", .lang = .{ .name = "Starlark", .line_comment = "#", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".sbt", .lang = .{ .name = "Scala", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;203m" } },
    .{ .ext = ".ant", .lang = .{ .name = "XML", .block_open = "<!--", .block_close = "-->", .color = "\x1b[38;5;173m" } },

    // в”Ђв”Ђ Jam / Bake в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".jam", .lang = .{ .name = "Jam", .line_comment = "#", .color = "\x1b[38;5;244m" } },
    .{ .ext = ".vpc", .lang = .{ .name = "VPC", .line_comment = "//", .color = "\x1b[38;5;244m" } },
    .{ .ext = ".vgd", .lang = .{ .name = "VGD", .line_comment = "//", .color = "\x1b[38;5;244m" } },

    // в”Ђв”Ђ Nim (already added above, skip) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

    // в”Ђв”Ђ Nim (skipped) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

    // в”Ђв”Ђ Rebol / Red в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".red", .lang = .{ .name = "Red", .line_comment = ";", .color = "\x1b[38;5;196m" } },
    .{ .ext = ".reds", .lang = .{ .name = "Red", .line_comment = ";", .color = "\x1b[38;5;196m" } },
    .{ .ext = ".reb", .lang = .{ .name = "Rebol", .line_comment = ";", .color = "\x1b[38;5;216m" } },
    .{ .ext = ".r3", .lang = .{ .name = "Rebol", .line_comment = ";", .color = "\x1b[38;5;216m" } },

    // в”Ђв”Ђ Factor в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".factor", .lang = .{ .name = "Factor", .line_comment = "!", .color = "\x1b[38;5;180m" } },

    // в”Ђв”Ђ Forth в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".fth", .lang = .{ .name = "Forth", .line_comment = null, .block_open = "(", .block_close = ")", .color = "\x1b[38;5;180m" } },
    .{ .ext = ".forth", .lang = .{ .name = "Forth", .line_comment = null, .block_open = "(", .block_close = ")", .color = "\x1b[38;5;180m" } },
    .{ .ext = ".4th", .lang = .{ .name = "Forth", .line_comment = null, .block_open = "(", .block_close = ")", .color = "\x1b[38;5;180m" } },

    // в”Ђв”Ђ PostScript / PDF в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".ps", .lang = .{ .name = "PostScript", .line_comment = "%", .color = "\x1b[38;5;248m" } },
    .{ .ext = ".eps", .lang = .{ .name = "PostScript", .line_comment = "%", .color = "\x1b[38;5;248m" } },
    .{ .ext = ".pdf", .lang = .{ .name = "PDF", .color = "\x1b[38;5;248m" } },

    // в”Ђв”Ђ APL / J в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".apl", .lang = .{ .name = "APL", .line_comment = "⍝", .color = "\x1b[38;5;213m" } },
    .{ .ext = ".ijs", .lang = .{ .name = "J", .line_comment = "#", .color = "\x1b[38;5;213m" } },
    .{ .ext = ".k", .lang = .{ .name = "K", .line_comment = "/", .color = "\x1b[38;5;213m" } },

    // в”Ђв”Ђ Crystal (already added) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

    // в”Ђв”Ђ PostScript (already added) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

    // в”Ђв”Ђ Mercury в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

    // в”Ђв”Ђ Smalltalk в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".st", .lang = .{ .name = "Smalltalk", .line_comment = null, .block_open = "\"", .block_close = "\"", .color = "\x1b[38;5;213m" } },

    // в”Ђв”Ђ Io в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".io", .lang = .{ .name = "Io", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;180m" } },

    // в”Ђв”Ђ_seed7 в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".sd7", .lang = .{ .name = "Seed7", .line_comment = "#", .color = "\x1b[38;5;113m" } },

    // в”Ђв”Ђ Seed7 (already added) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

    // в”Ђв”Ђ=valaв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".vala", .lang = .{ .name = "Vala", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".vapi", .lang = .{ .name = "Vala", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;113m" } },

    // в”Ђв”Ђ Crystal (already added) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

    // в”Ђв”Ђ Hack в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".hack", .lang = .{ .name = "Hack", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;141m" } },
    .{ .ext = ".hhi", .lang = .{ .name = "Hack", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;141m" } },

    // в”Ђв”Ђapelв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

    // в”Ђв”Ђ Wren в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".wren", .lang = .{ .name = "Wren", .line_comment = "//", .color = "\x1b[38;5;113m" } },

    // в”Ђв”Ђ Celia в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".celia", .lang = .{ .name = "Celia", .line_comment = "--", .color = "\x1b[38;5;113m" } },

    // в”Ђв”Ђ Zsh (already added) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

    // в”Ђв”Ђ Dart (already added) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

    // в”Ђв”Ђ Raku в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".raku", .lang = .{ .name = "Raku", .line_comment = "#", .block_open = "#[", .block_close = "]#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".rakumod", .lang = .{ .name = "Raku", .line_comment = "#", .block_open = "#[", .block_close = "]#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".rakutest", .lang = .{ .name = "Raku", .line_comment = "#", .block_open = "#[", .block_close = "]#", .color = "\x1b[38;5;078m" } },
    .{ .ext = ".pm6", .lang = .{ .name = "Raku", .line_comment = "#", .block_open = "#[", .block_close = "]#", .color = "\x1b[38;5;078m" } },

    // в”Ђв”Ђ chillв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".ch", .lang = .{ .name = "CHILL", .line_comment = null, .color = "\x1b[38;5;248m" } },

    // в”Ђв”Ђ Modula-2 / PIM в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".mod", .lang = .{ .name = "Modula-2", .line_comment = "(*", .block_open = "(*", .block_close = "*)", .color = "\x1b[38;5;213m" } },
    .{ .ext = ".def", .lang = .{ .name = "Modula-2", .line_comment = "(*", .block_open = "(*", .block_close = "*)", .color = "\x1b[38;5;213m" } },

    // в”Ђв”Ђ Oberon в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".obn", .lang = .{ .name = "Oberon", .line_comment = null, .block_open = "(*", .block_close = "*)", .color = "\x1b[38;5;213m" } },
    .{ .ext = ".ob", .lang = .{ .name = "Oberon", .line_comment = null, .block_open = "(*", .block_close = "*)", .color = "\x1b[38;5;213m" } },

    // в”Ђв”Ђ BASIC в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".basic", .lang = .{ .name = "BASIC", .line_comment = null, .color = "\x1b[38;5;213m" } },
    .{ .ext = ".bi", .lang = .{ .name = "BASIC", .line_comment = null, .color = "\x1b[38;5;213m" } },

    // в”Ђв”Ђ Whitespace в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".ws", .lang = .{ .name = "Whitespace", .color = "\x1b[38;5;248m" } },

    // в”Ђв”Ђ Befunge в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".bf", .lang = .{ .name = "Brainfuck", .color = "\x1b[38;5;196m" } },
    .{ .ext = ".b", .lang = .{ .name = "Befunge", .color = "\x1b[38;5;226m" } },

    // в”Ђв”Ђ Whitespace (already added) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

    // в”Ђв”Ђ ZIL в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".mud", .lang = .{ .name = "ZIL", .line_comment = ";", .color = "\x1b[38;5;213m" } },

    // в”Ђв”Ђ Ceylon в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".ceylon", .lang = .{ .name = "Ceylon", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;203m" } },

    // в”Ђв”Ђ Lasso в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".lasso", .lang = .{ .name = "Lasso", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;180m" } },
    .{ .ext = ".lasso8", .lang = .{ .name = "Lasso", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;180m" } },
    .{ .ext = ".lasso9", .lang = .{ .name = "Lasso", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;180m" } },

    // в”Ђв”Ђ XQuery в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".xquery", .lang = .{ .name = "XQuery", .line_comment = "(:", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".xq", .lang = .{ .name = "XQuery", .line_comment = "(:", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".xql", .lang = .{ .name = "XQuery", .line_comment = "(:", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".xqm", .lang = .{ .name = "XQuery", .line_comment = "(:", .color = "\x1b[38;5;113m" } },
    .{ .ext = ".xqy", .lang = .{ .name = "XQuery", .line_comment = "(:", .color = "\x1b[38;5;113m" } },

    // в”Ђв”Ђ XSLT в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

    // в”Ђв”Ђ Wollok в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".wkl", .lang = .{ .name = "Wollok", .line_comment = "//", .color = "\x1b[38;5;113m" } },

    // в”Ђв”Ђ Xtend в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".xtend", .lang = .{ .name = "Xtend", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;113m" } },

    // в”Ђв”Ђ Z++ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    .{ .ext = ".z", .lang = .{ .name = "Z++", .line_comment = "//", .block_open = "/*", .block_close = "*/", .color = "\x1b[38;5;213m" } },

    // в”Ђв”Ђ Zig (already added) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

    // в”Ђв”Ђ Zsh (already added) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

    // в”Ђв”Ђ Z++ (already added) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
};

pub fn detect(filename: []const u8) *const Language {
    const basename = std.fs.path.basename(filename);
    var best: ?*const Language = null;
    var best_len: usize = 0;

    // The declaration table is immutable. Longest suffix wins for multipart
    // extensions; equal-length collisions retain declaration order rather than
    // inventing content-based language semantics.
    for (&table) |*entry| {
        const exact_declared_filename = if (entry.filename) |name|
            std.ascii.eqlIgnoreCase(basename, name)
        else
            false;
        if ((std.mem.endsWith(u8, basename, entry.ext) or exact_declared_filename) and
            entry.ext.len > best_len)
        {
            best = &entry.lang;
            best_len = entry.ext.len;
        }
    }

    return best orelse &unknown;
}

test "detect uses immutable longest suffix lookup" {
    try std.testing.expectEqualStrings("Rust", detect("generated/module.rs.in").name);
    try std.testing.expectEqualStrings("Kotlin", detect("app/build.gradle.kts").name);
    try std.testing.expectEqualStrings("C++", detect("src/main.cpp").name);
    try std.testing.expectEqualStrings("Unknown", detect("README").name);
    for ([_][]const u8{ "json", "yaml", "toml", "html", "swift" }) |name| {
        try std.testing.expectEqualStrings("Unknown", detect(name).name);
    }
}

test "detect supports declared filenames without runtime mutation" {
    try std.testing.expectEqualStrings("Ruby", detect("config/Vagrantfile").name);
    try std.testing.expectEqualStrings("Ruby", detect("Gemfile").name);
    try std.testing.expectEqualStrings("Bash", detect(".bashrc").name);
}

test "language metadata distinguishes Rust nesting and APL comments" {
    try std.testing.expect(detect("lib.rs").block_nesting);
    try std.testing.expect(!detect("main.c").block_nesting);
    try std.testing.expectEqualStrings("⍝", detect("code.apl").line_comment.?);
}
