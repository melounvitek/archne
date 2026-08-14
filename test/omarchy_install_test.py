#!/usr/bin/env python3
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).parents[1]


class OmarchyInstallTest(unittest.TestCase):
    def test_installs_quattro_hyprland_config_with_current_commands(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory) / "home"
            bin_dir = Path(directory) / "bin"
            log = Path(directory) / "commands.log"
            (home / ".config/hypr").mkdir(parents=True)
            (home / ".oh-my-zsh").mkdir()
            (home / ".config/hypr/hyprland.lua").write_text("-- user config\n")
            (home / ".config/hypr/local_overrides.conf").write_text("legacy override\n")
            (home / ".zshrc").write_text("")
            bin_dir.mkdir()

            for command in ("chsh", "git", "omarchy", "pacman", "sudo", "systemctl", "yay"):
                stub = bin_dir / command
                stub.write_text('#!/usr/bin/env bash\nprintf "%s %s\\n" "$(basename "$0")" "$*" >> "$TEST_LOG"\n')
                stub.chmod(0o755)

            environment = os.environ.copy()
            environment.update(
                {
                    "HOME": str(home),
                    "PATH": f"{bin_dir}:/usr/bin",
                    "TEST_LOG": str(log),
                }
            )

            outputs = []
            for _ in range(2):
                result = subprocess.run(
                    ["bash", "omarchy_install.sh"],
                    cwd=ROOT,
                    env=environment,
                    check=True,
                    capture_output=True,
                    text=True,
                )
                outputs.append(result.stdout)

            hyprland_config = (home / ".config/hypr/hyprland.lua").read_text()
            commands = log.read_text()

            self.assertTrue((home / ".config/hypr/archne.lua").is_file())
            self.assertTrue((home / ".config/hypr/local_overrides.lua").is_file())
            self.assertEqual(hyprland_config.count('require("hypr.archne")'), 1)
            self.assertIn("Existing local_overrides.conf must be converted to Lua", outputs[0])
            self.assertIn("omarchy mise install npm:@earendil-works/pi-coding-agent pi", commands)
            self.assertIn("omarchy restart hyprsunset", commands)
            self.assertIn("omarchy install chromium google account", commands)


if __name__ == "__main__":
    unittest.main()
