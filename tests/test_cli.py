"""End-to-end regressions. Run: python3 tests/test_cli.py path/to/lc4[.exe]."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

BINARY = Path(sys.argv.pop(1)).resolve() if len(sys.argv) > 1 else Path("zig-out/bin/lc4.exe" if os.name == "nt" else "zig-out/bin/lc4").resolve()


class CliTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="lc4-test-")
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.root = self.base / "project with spaces"
        self.root.mkdir()

    def file(self, path, data=b"x\n"):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data.encode("utf-8") if isinstance(data, str) else data)
        return target

    def invoke(self, *args, cwd=None):
        return subprocess.run([str(BINARY), *map(str, args)], cwd=cwd or self.base,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              encoding="utf-8", errors="replace", timeout=120)

    def stats(self, *options, path=None, cwd=None):
        result = self.invoke("--json", *options, self.root if path is None else path, cwd=cwd)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "", result.stderr)
        data = json.loads(result.stdout)
        for item in [*data["languages"], data["total"]]:
            self.assertEqual(item["lines"], item["code"] + item["comments"] + item["blanks"])
        return data

    def assert_parity(self, *options):
        normal = self.stats(*options)
        verbose = self.stats("-v", *options)
        self.assertEqual(normal, verbose)
        return normal

    def test_explicit_root_absolute_relative_and_cwd(self):
        self.file("root.zig")
        self.file("sub/deep/nested.rs")
        # A similarly named directory in the process CWD must never be scanned.
        (self.base / "sub").mkdir()
        (self.base / "sub" / "wrong.rs").write_text("bad\n" * 20)
        absolute = self.assert_parity()
        relative = self.stats(path=self.root.name)
        current = self.stats(path=".", cwd=self.root)
        self.assertEqual(absolute, relative)
        self.assertEqual(absolute, current)
        self.assertEqual(absolute["total"]["files"], 2)
        self.assertEqual(absolute["total"]["lines"], 2)

    def test_unknown_and_empty_files_are_counted(self):
        self.file("LICENSE", "one\ntwo\n")
        self.file("empty.rs", b"")
        self.file("empty.no_such_ext", b"")
        result = self.assert_parity()
        self.assertEqual(result["total"]["files"], 3)
        self.assertEqual(result["total"]["lines"], 2)
        languages = {item["name"]: item for item in result["languages"]}
        self.assertEqual(languages["Unknown"]["files"], 2)
        self.assertEqual(languages["Rust"]["files"], 1)

    def test_empty_json(self):
        result = self.assert_parity()
        self.assertEqual(result["languages"], [])
        self.assertEqual(result["total"]["files"], 0)

    def test_extensions_owned_with_and_without_dot(self):
        self.file("a.rs")
        self.file("b.zig")
        self.file("c.py")
        dotted = self.assert_parity("-e", ".rs,.zig")
        self.assertEqual(dotted, self.assert_parity("-e", "rs,zig"))
        self.assertEqual(dotted["total"]["files"], 2)
        self.assertEqual(self.stats("-e", "py", "-e", ".rs")["total"]["files"], 1)

    def test_repeated_root_and_sort_options(self):
        self.file("a.rs")
        result = self.invoke("--json", self.base / "missing", self.root, "--sort", "code", "--sort", "name")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["total"]["files"], 1)

    def test_top_n_selects_actual_largest_and_keeps_grand_total(self):
        for ext, count in zip(["py", "rs", "go", "js", "c", "java", "rb", "php", "swift", "lua"], range(100, 0, -10)):
            self.file("a." + ext, "x\n" * count)
        top = self.assert_parity("--top", "3")
        self.assertEqual([item["lines"] for item in top["languages"]], [100, 90, 80])
        self.assertEqual(top["total"]["lines"], 550)
        self.assertEqual(self.stats("--top", "0")["languages"], [])
        self.assertEqual(len(self.stats("--top", "99")["languages"]), 10)

    def test_sort_modes_are_deterministic(self):
        self.file("a.rs", "// comment\nx\n")
        self.file("b.py", "x\nx\n")
        for sort in ["name", "lines", "files", "code"]:
            with self.subTest(sort=sort):
                result = self.assert_parity("--sort", sort)
                self.assertEqual([item["name"] for item in result["languages"]], ["Python", "Rust"])

    def test_binaries_flag_not_extension_filter_controls_binary_inclusion(self):
        self.file("data.rs", b"a\x00b\nc\n")
        self.assertEqual(self.assert_parity()["total"]["files"], 0)
        self.assertEqual(self.assert_parity("-e", ".rs")["total"]["files"], 0)
        for flags in [("-b",), ("-b", "-e", ".rs")]:
            result = self.assert_parity(*flags)
            self.assertEqual(result["total"]["files"], 1)
            self.assertEqual(result["total"]["lines"], 2)

    def test_mixed_block_comments_and_non_nesting_c(self):
        self.file("a.c", "/* doc */ int x;\n/* mention /* token */\nint y;\n")
        total = self.assert_parity()["total"]
        self.assertEqual((total["lines"], total["code"], total["comments"]), (3, 2, 1))

    def test_rust_nested_block_comments(self):
        self.file("a.rs", "/* outer /* inner */\nstill outer\n*/\nfn f() {}\n")
        total = self.assert_parity()["total"]
        self.assertEqual((total["lines"], total["code"], total["comments"]), (4, 1, 3))

    def test_crlf_and_no_final_newline(self):
        self.file("a.rs", b"// header\r\n\r\nfn main() {}")
        total = self.assert_parity()["total"]
        self.assertEqual((total["lines"], total["blanks"], total["comments"], total["code"]), (3, 1, 1, 1))

    def test_quoted_comment_delimiters(self):
        self.file("a.c", 'const char *s = "/*";\nint x;\n')
        self.assertEqual(self.assert_parity()["total"]["comments"], 0)

    def test_extension_words_without_dot_are_unknown(self):
        for name in ["json", "yaml", "toml", "html", "swift"]:
            self.file(name)
        result = self.assert_parity()
        self.assertEqual(len(result["languages"]), 1)
        self.assertEqual(result["languages"][0]["name"], "Unknown")
        self.assertEqual(result["total"]["files"], 5)

    def test_multipart_extensions_and_declared_names(self):
        self.file("generated.rs.in")
        self.file("Gemfile")
        self.file("Vagrantfile")
        result = self.assert_parity()
        languages = {item["name"]: item["files"] for item in result["languages"]}
        self.assertEqual(languages, {"Rust": 1, "Ruby": 2})

    def test_slash_glob_nested_rules_and_no_scan_side_effects(self):
        self.file(".gitignore", "src/*.gen\n*.tmp\nignored/\n")
        self.file("src/drop.gen")
        self.file("src/keep.rs")
        self.file("pkg/.gitignore", "!keep.tmp\nlocal.rs\n")
        self.file("pkg/drop.tmp")
        self.file("pkg/keep.tmp")
        self.file("pkg/local.rs")
        self.file("outside/local.rs")
        self.file("ignored/lost.rs")
        before = sorted(str(p.relative_to(self.root)) for p in self.root.rglob("*"))
        result = self.assert_parity()
        # Two .gitignore files + keep.rs + keep.tmp + outside/local.rs.
        self.assertEqual(result["total"]["files"], 5)
        self.assertEqual(sorted(str(p.relative_to(self.root)) for p in self.root.rglob("*")), before)

    def test_negation_cannot_reinclude_excluded_parent(self):
        self.file(".gitignore", "ignored/\n!ignored/keep.rs\n")
        self.file("ignored/keep.rs")
        self.assertEqual(self.assert_parity("-e", "rs")["total"]["files"], 0)
        self.assertEqual(self.assert_parity("-a", "-e", "rs")["total"]["files"], 1)

    def test_anchored_ignore_and_double_star(self):
        self.file(".gitignore", "/root.rs\na/**/drop.rs\n")
        self.file("root.rs")
        self.file("nested/root.rs")
        self.file("a/drop.rs")
        self.file("a/b/c/drop.rs")
        self.file("a/b/c/keep.rs")
        self.assertEqual(self.assert_parity("-e", "rs")["total"]["files"], 2)

    def test_ignore_character_classes_and_escaped_prefixes(self):
        self.file(".gitignore", "file[0-9].rs\n\\#literal.rs\n\\!literal.rs\n")
        for name in ["file1.rs", "filea.rs", "#literal.rs", "!literal.rs"]:
            self.file(name)
        self.assertEqual(self.assert_parity("-e", "rs")["total"]["files"], 1)

    def test_all_disables_builtin_directory_exclusions(self):
        self.file("target/a.rs")
        self.file("node_modules/a.rs")
        self.file("src/a.rs")
        self.assertEqual(self.assert_parity("-e", "rs")["total"]["files"], 1)
        self.assertEqual(self.assert_parity("-a", "-e", "rs")["total"]["files"], 3)

    def test_unicode_and_space_paths(self):
        self.file("каталог с пробелом/日本語.rs")
        self.assertEqual(self.assert_parity()["total"]["files"], 1)

    def test_symlink_cycle_is_not_followed(self):
        self.file("sub/a.rs")
        try:
            (self.root / "sub" / "cycle").symlink_to(self.root, target_is_directory=True)
            (self.root / "alias.rs").symlink_to(self.root / "sub" / "a.rs")
        except OSError as error:
            self.skipTest(f"Symlink creation unavailable: {error}")
        self.assertEqual(self.assert_parity()["total"]["files"], 1)

    def test_many_files_across_count_jobs(self):
        for i in range(513):
            self.file(f"d{i % 17}/file{i}.rs", "// header\nx\n")
        result = self.assert_parity()
        self.assertEqual(result["total"]["files"], 513)
        self.assertEqual(result["total"]["lines"], 1026)

    def test_large_file_is_not_silently_skipped(self):
        target = self.file("large.rs", b"")
        with target.open("wb") as handle:
            for _ in range(101):
                handle.write(b"x" * (1024 * 1024))
            handle.write(b"\n")
        result = self.stats()
        self.assertEqual(result["total"]["files"], 1)
        self.assertEqual(result["total"]["lines"], 1)

    def test_invalid_arguments_fail(self):
        cases = [("--sort",), ("--sort", "nonsense"), ("--top",), ("--top", "-1"),
                 ("--top", "text"), ("--top", "4294967296"), ("-e",), ("-e", " , "), ("--unknown",)]
        for args in cases:
            with self.subTest(args=args):
                result = self.invoke(*args)
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertIn("Invalid", result.stderr)
                self.assertEqual(result.stdout, "")

    def test_extension_flag_does_not_swallow_another_option(self):
        result = self.invoke("-e", "--json", self.root)
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_json_takes_precedence_over_short(self):
        self.file("a.rs")
        self.assertEqual(self.stats("--short")["total"]["files"], 1)

    def test_oversized_ignore_pattern_fails_explicitly(self):
        self.file(".gitignore", "x" * 4097 + "\n")
        self.file("a.rs")
        result = self.invoke("--json", self.root)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("PatternTooLong", result.stderr)
        self.assertEqual(result.stdout, "")

    def test_file_permission_failure_is_not_a_partial_success(self):
        if os.name == "nt" or (hasattr(os, "geteuid") and os.geteuid() == 0):
            self.skipTest("POSIX non-root permission test")
        target = self.file("unreadable.rs")
        self.addCleanup(target.chmod, 0o600)
        target.chmod(0)
        try:
            target.read_bytes()
        except PermissionError:
            pass
        else:
            self.skipTest("Environment permits reads despite chmod(0)")
        result = self.invoke("--json", self.root)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unreadable.rs", result.stderr)
        self.assertEqual(result.stdout, "")

    def test_missing_root_fails_instead_of_successful_empty_json(self):
        result = self.invoke("--json", self.base / "missing")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Cannot open", result.stderr)
        self.assertEqual(result.stdout, "")

    def test_help_version_short_and_verbose_output(self):
        self.file("a.rs")
        for flag in ["--help", "--version"]:
            result = self.invoke(flag)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("lc4", result.stdout)
        short = self.invoke("--short", self.root)
        self.assertEqual(short.returncode, 0, short.stderr)
        self.assertIn("1 files, 1 lines", short.stdout)
        verbose = self.invoke("--no-color", "--verbose", self.root)
        self.assertEqual(verbose.returncode, 0, verbose.stderr)
        self.assertIn("a.rs", verbose.stdout)
        self.assertNotIn("\x1b", verbose.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=2)
