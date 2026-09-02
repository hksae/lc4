const std = @import("std");

pub const Pattern = struct {
    text: []const u8,
    negated: bool,
    anchored: bool,
};

pub fn parse(allocator: std.mem.Allocator, content: []const u8) !std.ArrayList(Pattern) {
    var patterns = std.ArrayList(Pattern).init(allocator);
    errdefer patterns.deinit();

    var lines = std.mem.splitScalar(u8, content, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trimRight(u8, raw_line, " \t\r");
        if (line.len == 0 or line[0] == '#') continue;

        var pos: usize = 0;
        var negated = false;
        if (line[0] == '!') {
            negated = true;
            pos = 1;
        }

        const pattern_text = line[pos..];
        const anchored = pattern_text.len > 0 and (pattern_text[0] == '/' or std.mem.indexOfScalar(u8, pattern_text, '/') != null);

        const clean = if (anchored and pattern_text.len > 0 and pattern_text[0] == '/')
            pattern_text[1..]
        else
            pattern_text;

        try patterns.append(.{
            .text = try allocator.dupe(u8, clean),
            .negated = negated,
            .anchored = anchored,
        });
    }

    return patterns;
}

pub fn isIgnored(path: []const u8, patterns: []const Pattern) bool {
    var ignored = false;
    for (patterns) |pat| {
        if (matchPattern(path, pat)) {
            ignored = !pat.negated;
        }
    }
    return ignored;
}

fn matchPattern(path: []const u8, pat: Pattern) bool {
    if (pat.anchored) {
        return globMatch(path, pat.text);
    }
    const base = std.fs.path.basename(path);
    return globMatch(base, pat.text);
}

fn globMatch(text: []const u8, pattern: []const u8) bool {
    if (pattern.len == 0) return text.len == 0;

    if (pattern[0] == '*') {
        if (pattern.len > 1 and pattern[1] == '*') {
            var j: usize = 1;
            while (j < pattern.len and pattern[j] == '*') j += 1;
            if (j >= pattern.len) return true;
            const rest = pattern[j..];
            if (rest[0] == '/') {
                var i: usize = 0;
                while (i <= text.len) : (i += 1) {
                    if (globMatch(text[i..], rest[1..])) return true;
                }
            } else {
                var i: usize = 0;
                while (i <= text.len) : (i += 1) {
                    if (globMatch(text[i..], rest)) return true;
                }
            }
            return false;
        }
        var i: usize = 0;
        while (i <= text.len) : (i += 1) {
            if (i < text.len and text[i] == '/') break;
            if (globMatch(text[i..], pattern[1..])) return true;
        }
        return false;
    }

    if (text.len == 0) return false;

    if (pattern[0] == '?') {
        if (text[0] == '/') return false;
        return globMatch(text[1..], pattern[1..]);
    }

    if (pattern[0] == text[0]) {
        return globMatch(text[1..], pattern[1..]);
    }

    return false;
}
