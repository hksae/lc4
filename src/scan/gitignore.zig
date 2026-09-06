const std = @import("std");

/// Maximum stored pattern text length. Paths are intentionally unbounded; this
/// limit keeps the allocation-free matcher workspace fixed and predictable.
pub const max_pattern_bytes: usize = 4096;

pub const Pattern = struct {
    text: []const u8,
    scope: []const u8,
    negated: bool,
    anchored: bool,
    directory_only: bool,
    has_slash: bool,

    pub fn deinit(self: Pattern, allocator: std.mem.Allocator) void {
        allocator.free(self.text);
        allocator.free(self.scope);
    }
};

pub fn parse(allocator: std.mem.Allocator, content: []const u8) !std.ArrayList(Pattern) {
    return parseScoped(allocator, content, "");
}

pub fn parseScoped(allocator: std.mem.Allocator, content: []const u8, scope: []const u8) !std.ArrayList(Pattern) {
    var patterns: std.ArrayList(Pattern) = .empty;
    errdefer {
        for (patterns.items) |pat| pat.deinit(allocator);
        patterns.deinit(allocator);
    }
    var lines = std.mem.splitScalar(u8, content, '\n');
    while (lines.next()) |raw| {
        var line = std.mem.trimEnd(u8, raw, "\r");
        while (line.len > 0 and (line[line.len - 1] == ' ' or line[line.len - 1] == '\t')) {
            var slashes: usize = 0;
            var i = line.len - 1;
            while (i > 0 and line[i - 1] == '\\') : (i -= 1) slashes += 1;
            if (slashes % 2 == 1) break;
            line = line[0 .. line.len - 1];
        }
        if (line.len == 0) continue;
        var pos: usize = 0;
        var negated = false;
        if (line[0] == '#') continue;
        if (line[0] == '!') {
            negated = true;
            pos = 1;
        } else if (line.len >= 2 and line[0] == '\\' and (line[1] == '#' or line[1] == '!')) pos = 1;
        if (pos == line.len) continue;
        var source = line[pos..];
        const anchored = source[0] == '/';
        if (anchored) source = source[1..];
        var directory_only = false;
        if (source.len > 0 and source[source.len - 1] == '/' and !isEscaped(source, source.len - 1)) {
            directory_only = true;
            source = source[0 .. source.len - 1];
        }
        if (source.len == 0) continue;
        if (source.len > max_pattern_bytes) return error.PatternTooLong;
        // Preserve escapes for the matcher. In particular, \*, \?, and \[
        // must remain distinguishable from wildcard operators.
        const text = try allocator.dupe(u8, source);
        errdefer allocator.free(text);
        const scope_copy = try allocator.dupe(u8, scope);
        errdefer allocator.free(scope_copy);
        try patterns.append(allocator, .{ .text = text, .scope = scope_copy, .negated = negated, .anchored = anchored, .directory_only = directory_only, .has_slash = std.mem.indexOfScalar(u8, text, '/') != null });
    }
    return patterns;
}

fn isEscaped(s: []const u8, at: usize) bool {
    var n: usize = 0;
    var i = at;
    while (i > 0 and s[i - 1] == '\\') : (i -= 1) n += 1;
    return n % 2 == 1;
}

pub fn isIgnored(path: []const u8, patterns: []const Pattern) bool {
    return isIgnoredPath(path, false, patterns);
}
pub fn isIgnoredPath(path: []const u8, is_dir: bool, patterns: []const Pattern) bool {
    var ignored = false;
    for (patterns) |pat| {
        const relative = relativeToScope(path, pat.scope) orelse continue;
        if (matches(relative, is_dir, pat)) ignored = !pat.negated;
    }
    return ignored;
}
fn relativeToScope(path: []const u8, scope: []const u8) ?[]const u8 {
    if (scope.len == 0) return path;
    if (path.len <= scope.len or !std.mem.eql(u8, path[0..scope.len], scope) or path[scope.len] != '/') return null;
    return path[scope.len + 1 ..];
}
fn matches(path: []const u8, is_dir: bool, pat: Pattern) bool {
    if (pat.has_slash or pat.anchored) {
        if (globMatch(path, pat.text)) return !pat.directory_only or is_dir;
        if (pat.directory_only) {
            var end = std.mem.indexOfScalar(u8, path, '/') orelse return false;
            while (true) {
                if (globMatch(path[0..end], pat.text)) return true;
                const next = std.mem.indexOfScalarPos(u8, path, end + 1, '/') orelse return false;
                end = next;
            }
        }
        return false;
    }
    var segments = std.mem.splitScalar(u8, path, '/');
    while (segments.next()) |segment| if (globMatch(segment, pat.text)) {
        if (!pat.directory_only) return true;
        if (segments.peek() != null or is_dir) return true;
    };
    return false;
}
fn globMatch(text: []const u8, pattern: []const u8) bool {
    // parseScoped enforces this bound for normal inputs. A manually-constructed
    // overlong Pattern is a contract violation, not a silent non-match.
    if (pattern.len > max_pattern_bytes) @panic("gitignore pattern exceeds max_pattern_bytes");

    // NFA states are pattern byte offsets. `current` is epsilon-closed before
    // every input byte; `next` is then closed for the following byte. Memory is
    // O(pattern.len), recursion-free, and independent of path length.
    var current: [max_pattern_bytes + 1]bool = @splat(false);
    var next: [max_pattern_bytes + 1]bool = @splat(false);
    current[0] = true;
    epsilonClosure(pattern, current[0 .. pattern.len + 1], true);

    for (text, 0..) |char, ti| {
        @memset(next[0 .. pattern.len + 1], false);
        for (current[0..pattern.len], 0..) |active, pi| {
            if (!active) continue;
            const token = tokenAt(pattern, pi);
            switch (token.kind) {
                .literal => if (char == token.literal) {
                    next[token.next] = true;
                },
                .question => if (char != '/') {
                    next[token.next] = true;
                },
                .class => if (char != '/' and token.class_matched(char)) {
                    next[token.next] = true;
                },
                .star => if (char != '/') {
                    next[pi] = true;
                },
                .double_star_tail => next[pi] = true,
                .double_star_dirs => {
                    // Stay in **/ while consuming a component. On '/', also
                    // enter the following token at a text component boundary.
                    next[pi] = true;
                    if (char == '/') next[token.next] = true;
                },
            }
        }
        const at_boundary = char == '/' or ti + 1 == text.len;
        epsilonClosure(pattern, next[0 .. pattern.len + 1], at_boundary);
        current = next;
    }
    return current[pattern.len];
}

const TokenKind = enum { literal, question, class, star, double_star_tail, double_star_dirs };
const Token = struct {
    kind: TokenKind,
    next: usize,
    literal: u8 = 0,
    class_start: usize = 0,
    pattern: []const u8,

    fn class_matched(self: Token, char: u8) bool {
        return matchClass(char, self.pattern, self.class_start).?.matched;
    }
};

fn tokenAt(pattern: []const u8, pi: usize) Token {
    if (pattern[pi] == '\\') {
        const literal_index = if (pi + 1 < pattern.len) pi + 1 else pi;
        return .{ .kind = .literal, .next = if (pi + 1 < pattern.len) pi + 2 else pi + 1, .literal = pattern[literal_index], .pattern = pattern };
    }
    if (pattern[pi] == '?') return .{ .kind = .question, .next = pi + 1, .pattern = pattern };
    if (pattern[pi] == '[') {
        if (matchClass(0, pattern, pi)) |class| return .{ .kind = .class, .next = class.next, .class_start = pi, .pattern = pattern };
        return .{ .kind = .literal, .next = pi + 1, .literal = '[', .pattern = pattern };
    }
    if (pattern[pi] == '*') {
        var end = pi + 1;
        while (end < pattern.len and pattern[end] == '*') end += 1;
        const is_double_star = end - pi >= 2 and
            (pi == 0 or pattern[pi - 1] == '/') and
            (end == pattern.len or pattern[end] == '/');
        if (is_double_star and end == pattern.len) return .{ .kind = .double_star_tail, .next = end, .pattern = pattern };
        if (is_double_star) return .{ .kind = .double_star_dirs, .next = end + 1, .pattern = pattern };
        return .{ .kind = .star, .next = end, .pattern = pattern };
    }
    return .{ .kind = .literal, .next = pi + 1, .literal = pattern[pi], .pattern = pattern };
}

fn epsilonClosure(pattern: []const u8, states: []bool, at_text_boundary: bool) void {
    var pi: usize = 0;
    while (pi < pattern.len) : (pi += 1) {
        if (!states[pi] or pattern[pi] != '*') continue;
        const token = tokenAt(pattern, pi);
        switch (token.kind) {
            .star => states[token.next] = true,
            .double_star_tail => states[token.next] = true,
            // The empty **/ transition is legal only at a text component
            // boundary, preventing mid-component epsilon skips.
            .double_star_dirs => if (at_text_boundary) {
                states[token.next] = true;
            },
            else => unreachable,
        }
    }
}

const ClassMatch = struct { matched: bool, next: usize };

fn matchClass(char: u8, pattern: []const u8, start: usize) ?ClassMatch {
    var i = start + 1;
    if (i == pattern.len) return null;
    var negated = false;
    if (pattern[i] == '!' or pattern[i] == '^') {
        negated = true;
        i += 1;
    }
    const content_start = i;
    var matched = false;
    while (i < pattern.len and pattern[i] != ']') {
        const first = classChar(pattern, &i) orelse return null;
        if (i + 1 < pattern.len and pattern[i] == '-' and pattern[i + 1] != ']') {
            i += 1;
            const last = classChar(pattern, &i) orelse return null;
            if (first <= char and char <= last) matched = true;
        } else if (first == char) {
            matched = true;
        }
    }
    if (i == pattern.len or i == content_start) return null;
    return .{ .matched = if (negated) !matched else matched, .next = i + 1 };
}

fn classChar(pattern: []const u8, index: *usize) ?u8 {
    if (index.* >= pattern.len or pattern[index.*] == ']') return null;
    if (pattern[index.*] == '\\' and index.* + 1 < pattern.len) index.* += 1;
    const char = pattern[index.*];
    index.* += 1;
    return char;
}
fn freePatterns(allocator: std.mem.Allocator, patterns: *std.ArrayList(Pattern)) void {
    for (patterns.items) |pat| pat.deinit(allocator);
    patterns.deinit(allocator);
}

test "scoped precedence anchoring slash glob and double star" {
    const a = std.testing.allocator;
    var root = try parseScoped(a, "*.log\n/src/*.gen\ncache/\nall/**/tmp.txt\n", "");
    defer freePatterns(a, &root);
    var nested = try parseScoped(a, "!keep.log\n", "pkg");
    defer freePatterns(a, &nested);
    var all: std.ArrayList(Pattern) = .empty;
    defer all.deinit(a);
    try all.appendSlice(a, root.items);
    try all.appendSlice(a, nested.items);
    try std.testing.expect(isIgnored("pkg/drop.log", all.items));
    try std.testing.expect(!isIgnored("pkg/keep.log", all.items));
    try std.testing.expect(isIgnored("src/a.gen", all.items));
    try std.testing.expect(!isIgnored("deep/src/a.gen", all.items));
    try std.testing.expect(isIgnored("all/tmp.txt", all.items));
    try std.testing.expect(isIgnored("all/a/b/tmp.txt", all.items));
    try std.testing.expect(isIgnoredPath("x/cache", true, all.items));
}
test "escaped comment negation wildcard and trailing space" {
    const a = std.testing.allocator;
    var patterns = try parse(a, "\\#literal\n\\!literal\nname\\ \nliteral\\*star\nliteral\\?mark\nliteral\\[bracket\nback\\\\slash\n");
    defer freePatterns(a, &patterns);
    try std.testing.expect(isIgnored("#literal", patterns.items));
    try std.testing.expect(isIgnored("!literal", patterns.items));
    try std.testing.expect(isIgnored("name ", patterns.items));
    try std.testing.expect(isIgnored("literal*star", patterns.items));
    try std.testing.expect(!isIgnored("literalXXstar", patterns.items));
    try std.testing.expect(isIgnored("literal?mark", patterns.items));
    try std.testing.expect(!isIgnored("literalXmark", patterns.items));
    try std.testing.expect(isIgnored("literal[bracket", patterns.items));
    try std.testing.expect(isIgnored("back\\slash", patterns.items));
}

test "simple character classes ranges negation and malformed classes" {
    try std.testing.expect(globMatch("cat", "c[ab]t"));
    try std.testing.expect(!globMatch("cot", "c[ab]t"));
    try std.testing.expect(globMatch("file7", "file[0-9]"));
    try std.testing.expect(!globMatch("filex", "file[0-9]"));
    try std.testing.expect(globMatch("cot", "c[!ab]t"));
    try std.testing.expect(!globMatch("cat", "c[!ab]t"));
    try std.testing.expect(globMatch("a[b", "a[b"));
    try std.testing.expect(!globMatch("ab", "a[b"));
}

test "double star is special only at component boundaries" {
    try std.testing.expect(globMatch("a/x/y/b", "a/**/b"));
    try std.testing.expect(globMatch("a/b", "a/**/b"));
    try std.testing.expect(globMatch("a/x/y", "a/**"));
    try std.testing.expect(!globMatch("ab/x/cd", "ab**cd"));
    try std.testing.expect(globMatch("abXXcd", "ab**cd"));
    try std.testing.expect(!globMatch("a/x/b", "a**b"));
}

test "directory negation controls whether scanner may descend" {
    const a = std.testing.allocator;
    var blocked = try parse(a, "build/\n!build/keep.txt\n");
    defer freePatterns(a, &blocked);
    try std.testing.expect(isIgnoredPath("build", true, blocked.items));

    var reopened = try parse(a, "build/\n!build/\nbuild/*.tmp\n");
    defer freePatterns(a, &reopened);
    try std.testing.expect(!isIgnoredPath("build", true, reopened.items));
    try std.testing.expect(!isIgnored("build/keep.txt", reopened.items));
    try std.testing.expect(isIgnored("build/drop.tmp", reopened.items));
}

test "long matches have no path-pattern product cap" {
    var literal: [300]u8 = @splat('a');
    try std.testing.expect(globMatch(&literal, &literal));

    var deep: [8006]u8 = undefined;
    for (0..4000) |i| {
        deep[i * 2] = 'd';
        deep[i * 2 + 1] = '/';
    }
    @memcpy(deep[8000..], "target");
    try std.testing.expect(globMatch(&deep, "**/target"));
}

test "pathological wildcard pattern is iterative and bounded" {
    var pattern: [max_pattern_bytes]u8 = undefined;
    for (0..max_pattern_bytes / 2) |i| {
        pattern[i * 2] = '*';
        pattern[i * 2 + 1] = 'a';
    }
    var text: [max_pattern_bytes / 2]u8 = @splat('a');
    try std.testing.expect(globMatch(&text, &pattern));
}

test "parse rejects patterns beyond documented workspace limit" {
    const a = std.testing.allocator;
    var content: [max_pattern_bytes + 2]u8 = @splat('a');
    content[content.len - 1] = '\n';
    try std.testing.expectError(error.PatternTooLong, parse(a, &content));
}

fn parseAllocationTest(allocator: std.mem.Allocator) !void {
    var patterns = try parseScoped(allocator, "*.log\n!keep.log\nfoo/[a-z]\\*\n", "nested/scope");
    defer freePatterns(allocator, &patterns);
}

test "parse cleans up every allocation failure" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, parseAllocationTest, .{});
}
