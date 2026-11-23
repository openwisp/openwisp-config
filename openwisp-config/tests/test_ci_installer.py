"""Check the dependency installer phases without changing the host."""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class TestCiInstaller(unittest.TestCase):
    def run_installer(self, **variables):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            log = path / "calls"
            for name in ("sudo", "python"):
                executable = path / name
                executable.write_text(
                    f'#!/bin/sh\nprintf "%s\\n" "{name} $*" >> "$CALLS"\n'
                )
                executable.chmod(0o755)
            env = {
                **os.environ,
                "PATH": f"{path}:{os.environ['PATH']}",
                "CALLS": str(log),
                **variables,
            }
            result = subprocess.run(
                [str(ROOT / "install-ci-deps.sh")],
                cwd=ROOT,
                env=env,
                capture_output=True,
                text=True,
            )
            return result, log.read_text().splitlines() if log.exists() else []

    def test_normal_ci_installs_system_and_python_dependencies(self):
        result, calls = self.run_installer()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            calls,
            [
                "sudo ./install-dev.sh",
                "python -m pip install --upgrade -r requirements-test.txt",
            ],
        )

    def test_system_phase_excludes_python_installation(self):
        result, calls = self.run_installer(CI_SYSTEM_DEPS_ONLY="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ["sudo ./install-dev.sh"])

    def test_reviewer_does_not_repeat_privileged_installation(self):
        result, calls = self.run_installer(CI_SYSTEM_DEPS_READY="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            calls, ["python -m pip install --upgrade -r requirements-test.txt"]
        )
