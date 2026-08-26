#!/usr/bin/env python3
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).parents[1]


class OmarchyInstallTest(unittest.TestCase):
    def test_installs_omarchy_overlay_idempotently(self):
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

            agents_panel = Path(directory) / "Panel.qml"
            agents_panel.write_text(
                """import QtQuick

Panel {
  property double nowMs: Date.now()

  readonly property var limits: limitWindows(provider)
  readonly property var models: modelRows(provider)
  readonly property var headline: bindingWindow(provider)
  readonly property var balance: provider ? (provider.balance || null) : null
  readonly property bool balanceAlarming: !!balance && balance.funded > 0
    && balance.remaining / balance.funded <= 0.1
  readonly property bool alarming: (!!headline && headline.percent >= 0.9) || balanceAlarming

  function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }
  function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

  function launchAgent() {
    if (root.bar) root.bar.run("omarchy-agent --pick")
    root.close()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󱚣"
    active: root.alarming
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.launchAgent()
      else if (buttonCode === Qt.MiddleButton) root.selectProvider(root.providerIndex + 1)
      else root.toggle()
    }
  }
}
"""
            )

            for command in ("chsh", "pacman", "sudo", "systemctl", "yay"):
                stub = bin_dir / command
                stub.write_text('#!/usr/bin/env bash\nprintf "%s %s\\n" "$(basename "$0")" "$*" >> "$TEST_LOG"\n')
                stub.chmod(0o755)

            git_stub = bin_dir / "git"
            git_stub.write_text(
                """#!/usr/bin/env bash
if [[ $1 == "-C" && $3 == "apply" ]]; then
  exec /usr/bin/git "$@"
fi
printf "%s %s\\n" "$(basename "$0")" "$*" >> "$TEST_LOG"
"""
            )
            git_stub.chmod(0o755)

            omarchy_stub = bin_dir / "omarchy"
            omarchy_stub.write_text(
                """#!/usr/bin/env bash
printf "%s %s\\n" "$(basename "$0")" "$*" >> "$TEST_LOG"
if [[ $1 == "plugin" && $2 == "clone" ]]; then
  target="$HOME/.config/omarchy/plugins/$USER.agents"
  mkdir -p "$target"
  cp "$TEST_AGENTS_PANEL" "$target/Panel.qml"
fi
"""
            )
            omarchy_stub.chmod(0o755)

            environment = os.environ.copy()
            environment.update(
                {
                    "HOME": str(home),
                    "PATH": f"{bin_dir}:/usr/bin",
                    "TEST_LOG": str(log),
                    "TEST_AGENTS_PANEL": str(agents_panel),
                    "USER": "archne-test",
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

            ruby_config = home / ".config/nvim/lua/plugins/ruby.lua"
            self.assertEqual(ruby_config.read_text(), (ROOT / "config/nvim/lua/plugins/ruby.lua").read_text())

            solargraph_patch = home / ".config/nvim/solargraph_mapping_patch.rb"
            self.assertEqual(solargraph_patch.read_text(), (ROOT / "config/nvim/solargraph_mapping_patch.rb").read_text())
            self.assertEqual(hyprland_config.count('require("hypr.archne")'), 1)
            self.assertIn("Existing local_overrides.conf must be converted to Lua", outputs[0])
            self.assertIn("For Ruby LSP support, install Solargraph for each Ruby version you use:", outputs[0])
            self.assertIn("mise x ruby@<version> -- gem install solargraph --no-document", outputs[0])
            self.assertIn("omarchy mise install npm:@earendil-works/pi-coding-agent pi", commands)
            self.assertIn("omarchy install chromium google account", commands)
            self.assertEqual(commands.count("omarchy plugin clone omarchy.agents"), 1)
            self.assertIn("omarchy restart shell", commands)

            customized_panel = home / ".config/omarchy/plugins/archne-test.agents/Panel.qml"
            panel_contents = customized_panel.read_text()
            self.assertEqual(panel_contents.count("readonly property int weeklyRemainingPercent"), 1)
            self.assertIn("Math.round((1 - root.clamp(weeklyLimit.percent, 0, 1)) * 100)", panel_contents)
            self.assertIn('root.weeklyRemainingPercent + "% 󱚣"', panel_contents)
            self.assertEqual(panel_contents.count("root.launchAgent()"), 1)


if __name__ == "__main__":
    unittest.main()
