"""Run with python3 tests/test_wezterm_activation.py (requires Nix and Bash).

Evaluate the real activation, replacing only host paths and Windows commands.
All writes stay in temporary directories; no Home Manager switch is performed.
"""

import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[1]


class WeztermActivationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.activation = subprocess.check_output(
            ["nix", "eval", "--raw", '.#homeConfigurations."akihiro@wsl".config.home.activation.weztermWslConfig.data'],
            cwd=REPO, text=True,
        )
        cls.home = subprocess.check_output(
            ["nix", "eval", "--raw", '.#homeConfigurations."akihiro@wsl".config.home.homeDirectory'],
            cwd=REPO, text=True,
        ).strip()

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.src = self.root / "source"
        self.src.mkdir()
        self.win = self.root / "Windows Home"
        self.win.mkdir()
        self.dest = self.win / ".config/wezterm"
        for name in ("wezterm.lua", "appearance.lua", "workspace.local.lua", "loader.lua"):
            (self.src / name).write_text(f"-- {name}\n")
        self.version = self.root / "version"
        self.version.write_text("Linux Microsoft WSL2")
        self.env = dict(os.environ, MOCK_PROFILE="C:\\Users\\tester\r\n",
                        MOCK_HOME=str(self.win), MOCK_CMD_STATUS="0", MOCK_PATH_STATUS="0")
        self.env.pop("DRY_RUN", None)

    def snapshot(self):
        return {str(p.relative_to(self.root)): (p.read_bytes(), p.stat().st_mtime_ns)
                for p in self.root.rglob("*") if p.is_file()}

    def activate(self, **env):
        script = self.activation
        replacements = {
            f'{self.home}/dotfiles/wezterm': str(self.src),
            '/proc/version': shlex.quote(str(self.version)),
            'cd /mnt/c && /mnt/c/Windows/System32/cmd.exe': 'mock_cmd',
            '/usr/bin/wslpath': 'mock_wslpath',
        }
        for old, new in replacements.items():
            self.assertEqual(script.count(old), 1, f"Unsafe mock replacement: {old}")
            script = script.replace(old, new)
        helpers = '''
set -euo pipefail
mock_cmd() { printf '%s' "$MOCK_PROFILE"; return "$MOCK_CMD_STATUS"; }
mock_wslpath() {
  # Model the dangerous real wslpath behavior for empty input.
  if [[ -z "$2" ]]; then printf '.'; else printf '%s' "$MOCK_HOME"; fi
  return "$MOCK_PATH_STATUS"
}
run() { if [[ -v DRY_RUN ]]; then printf 'would run: %s\\n' "$*"; else "$@"; fi; }
'''
        result = subprocess.run(["bash", "-c", helpers + script], cwd=self.root,
                                env=self.env | env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result

    def test_mock_drift_stops_before_running_shell(self):
        self.activation = self.activation.replace('/usr/bin/wslpath', '/bin/wslpath')
        with patch('subprocess.run') as run:
            with self.assertRaisesRegex(AssertionError, 'Unsafe mock replacement'):
                self.activate()
            run.assert_not_called()

    def test_invalid_windows_home_never_writes(self):
        for env in ({"MOCK_CMD_STATUS": "1"}, {"MOCK_PROFILE": ""},
                    {"MOCK_PROFILE": "\r\n"}, {"MOCK_PATH_STATUS": "1"},
                    {"MOCK_HOME": "."}, {"MOCK_HOME": str(self.root / "missing")}):
            with self.subTest(env=env):
                before = self.snapshot()
                result = self.activate(**env)
                self.assertIn("スキップ", result.stderr)
                self.assertEqual(before, self.snapshot())
                self.assertFalse(self.dest.exists())
                self.assertFalse((self.root / ".config").exists())

    def test_dry_run_leaves_new_destination_absent(self):
        before = self.snapshot()
        self.activate(DRY_RUN="1")
        self.assertEqual(before, self.snapshot())
        self.assertFalse(self.dest.exists())

    def test_bootstrap_update_and_dry_run_preview(self):
        self.activate()
        self.assertNotIn('更新する予定', self.activate(DRY_RUN='1').stdout)
        target = self.win / '.wezterm.lua'
        previous = target.read_text()
        (self.src / 'loader.lua').write_text('-- changed loader\n')
        self.assertIn('更新する予定', self.activate(DRY_RUN='1').stdout)
        self.assertEqual(target.read_text(), previous)
        self.activate()
        self.assertIn('-- changed loader', target.read_text())

    def test_dry_run_preserves_existing_files(self):
        self.activate()
        (self.dest / "obsolete.lua").write_text("keep during dry-run")
        (self.src / "appearance.lua").write_text("-- changed")
        before = self.snapshot()
        self.activate(DRY_RUN="1")
        self.assertEqual(before, self.snapshot())

    def test_sync_is_idempotent_and_removes_obsolete_files(self):
        self.activate()
        self.assertEqual((self.dest / "workspace.local.lua").read_bytes(),
                         (self.src / "workspace.local.lua").read_bytes())
        self.assertFalse((self.dest / "loader.lua").exists())
        self.assertIn("WEZTERM_DOTFILES_CONFIG_DIR", (self.win / ".wezterm.lua").read_text())
        before = self.snapshot()
        self.activate()
        self.assertEqual(before, self.snapshot())
        (self.dest / "obsolete.lua").write_text("old")
        (self.dest / "loader.lua").write_text("old loader")
        (self.src / "workspace.local.lua.example").write_text("example")
        (self.src / "appearance.lua").write_text("-- updated")
        self.activate()
        self.assertFalse((self.dest / "obsolete.lua").exists())
        self.assertFalse((self.dest / "loader.lua").exists())
        self.assertFalse((self.dest / "workspace.local.lua.example").exists())
        self.assertEqual((self.dest / "appearance.lua").read_text(), "-- updated")

    def test_unmanaged_entry_is_preserved(self):
        target = self.win / ".wezterm.lua"
        target.write_text("-- hand-written config")
        self.activate()
        self.assertEqual(target.read_text(), "-- hand-written config")
        self.assertEqual((self.dest / "wezterm.lua").read_bytes(),
                         (self.src / "wezterm.lua").read_bytes())

    def test_non_wsl_does_nothing(self):
        self.version.write_text("Linux generic")
        before = self.snapshot()
        self.activate()
        self.assertEqual(before, self.snapshot())
        self.assertFalse(self.dest.exists())


if __name__ == "__main__":
    unittest.main()
