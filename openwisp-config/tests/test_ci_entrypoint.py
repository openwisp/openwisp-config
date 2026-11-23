"""Verify the supported test selectors and flags passed to the Lua runner."""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class TestCiEntrypoint(unittest.TestCase):
    def run_entrypoint(self, *arguments, status=0, root=ROOT):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            log = path / "calls"
            for name in ("lua", "luacheck"):
                command = path / name
                command.write_text(
                    f'#!/bin/sh\nprintf "%s\\n" "{name} $*" >> "$CALLS"\n'
                    f'exit "${{RUNNER_STATUS:-0}}"\n'
                )
                command.chmod(0o755)
            env = {
                **os.environ,
                "PATH": f"{path}:{os.environ['PATH']}",
                "CALLS": str(log),
                "RUNNER_STATUS": str(status),
            }
            result = subprocess.run(
                [str(root / "runtests"), *arguments],
                cwd=root,
                env=env,
                capture_output=True,
                text=True,
            )
            return result, log.read_text() if log.exists() else ""

    def test_rejects_unsupported_arguments(self):
        for argument in (
            "--config=other",
            "-e",
            "../test_net.lua",
            "test_net.lua;id",
            "openwisp-config/tests/test_unknown.lua",
        ):
            with self.subTest(argument=argument):
                result, calls = self.run_entrypoint(argument)
                self.assertEqual(result.returncode, 2)
                self.assertIn("unsupported", result.stderr.lower())
                self.assertEqual(calls, "")

    def test_runs_only_the_selected_test(self):
        result, calls = self.run_entrypoint("openwisp-config/tests/test_net.lua")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls.splitlines(), ["lua test_net.lua -v"])

    def test_returns_runner_failure(self):
        result, calls = self.run_entrypoint(
            "openwisp-config/tests/test_net.lua", status=17
        )
        self.assertEqual(result.returncode, 17)
        self.assertEqual(calls.splitlines(), ["lua test_net.lua -v"])

    def test_accepts_verbose_flag_with_a_selector(self):
        result, calls = self.run_entrypoint("-v", "openwisp-config/tests/test_net.lua")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls.splitlines(), ["lua test_net.lua -v"])

    def test_default_includes_lint_and_all_lua_tests(self):
        result, calls = self.run_entrypoint()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls.splitlines()[0], "luacheck ./openwisp-config/ -a")
        self.assertEqual(len(calls.splitlines()), 11)

    def test_rejects_symlinked_test_file(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            shutil.copy2(ROOT / "runtests", root / "runtests")
            tests = root / "openwisp-config" / "tests"
            tests.mkdir(parents=True)
            (tests / "test_net.lua").symlink_to(root / "outside.lua")
            result, calls = self.run_entrypoint(
                "openwisp-config/tests/test_net.lua", root=root
            )
        self.assertEqual(result.returncode, 2)
        self.assertIn("unsupported", result.stderr.lower())
        self.assertEqual(calls, "")
