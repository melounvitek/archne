#!/usr/bin/env python3
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).parents[1]
FOCUS_SCRIPT = ROOT / "config/hypr/scripts/group-aware-focus"
GROUP_SCRIPT = ROOT / "config/hypr/scripts/toggle-workspace-group"


class HyprScriptsTest(unittest.TestCase):
    def run_script(self, script, *, active_window, clients=None, direction=None):
        with tempfile.TemporaryDirectory() as directory:
            bin_dir = Path(directory) / "bin"
            log = Path(directory) / "dispatches.log"
            bin_dir.mkdir()

            hyprctl = bin_dir / "hyprctl"
            hyprctl.write_text(
                """#!/usr/bin/env bash
case "$1" in
  activewindow) printf '%s\\n' "$ACTIVE_WINDOW" ;;
  activeworkspace) printf '%s\\n' '{"id":2}' ;;
  clients) printf '%s\\n' "$CLIENTS" ;;
  dispatch) printf '%s\\n' "$*" >> "$DISPATCH_LOG" ;;
esac
"""
            )
            hyprctl.chmod(0o755)

            environment = os.environ.copy()
            environment.update(
                {
                    "ACTIVE_WINDOW": json.dumps(active_window),
                    "CLIENTS": json.dumps(clients or []),
                    "DISPATCH_LOG": str(log),
                    "PATH": f"{bin_dir}:/usr/bin",
                }
            )
            arguments = [script]
            if direction:
                arguments.append(direction)

            subprocess.run(arguments, check=True, env=environment, capture_output=True, text=True)

            return log.read_text().splitlines() if log.exists() else []

    def test_focuses_the_next_tiled_window(self):
        dispatches = self.run_script(
            FOCUS_SCRIPT,
            active_window={"address": "0x1", "grouped": []},
            direction="r",
        )

        self.assertEqual(dispatches, ['dispatch hl.dsp.focus({ direction = "r" })'])

    def test_focuses_the_next_window_inside_a_group(self):
        dispatches = self.run_script(
            FOCUS_SCRIPT,
            active_window={"address": "0x2", "grouped": ["0x1", "0x2", "0x3"]},
            direction="r",
        )

        self.assertEqual(dispatches, ["dispatch hl.dsp.group.next()"])

    def test_focuses_the_previous_window_inside_a_group(self):
        dispatches = self.run_script(
            FOCUS_SCRIPT,
            active_window={"address": "0x2", "grouped": ["0x1", "0x2", "0x3"]},
            direction="l",
        )

        self.assertEqual(dispatches, ["dispatch hl.dsp.group.prev()"])

    def test_does_not_wrap_at_group_boundary(self):
        dispatches = self.run_script(
            FOCUS_SCRIPT,
            active_window={"address": "0x1", "grouped": ["0x1", "0x2"]},
            direction="l",
        )

        self.assertEqual(dispatches, [])

    def test_rejects_an_invalid_direction(self):
        with self.assertRaises(subprocess.CalledProcessError):
            self.run_script(
                FOCUS_SCRIPT,
                active_window={"address": "0x1", "grouped": []},
                direction='r" }); os.execute("false")',
            )

    def test_toggles_a_group_for_a_single_window(self):
        clients = [
            {"address": "0x1", "workspace": {"id": 2}, "mapped": True, "floating": False, "grouped": [], "at": [0, 0]},
        ]
        dispatches = self.run_script(
            GROUP_SCRIPT,
            active_window={"address": "0x1", "grouped": []},
            clients=clients,
        )

        self.assertEqual(dispatches, ["dispatch hl.dsp.group.toggle()"])

    def test_groups_all_tiled_workspace_windows(self):
        clients = [
            {"address": "0x1", "workspace": {"id": 2}, "mapped": True, "floating": False, "grouped": [], "at": [0, 0]},
            {"address": "0x2", "workspace": {"id": 2}, "mapped": True, "floating": False, "grouped": [], "at": [100, 0]},
        ]
        dispatches = self.run_script(
            GROUP_SCRIPT,
            active_window={"address": "0x1", "grouped": []},
            clients=clients,
        )

        self.assertEqual(
            dispatches,
            [
                'dispatch hl.dsp.focus({ window = "address:0x1" })',
                "dispatch hl.dsp.group.toggle()",
                'dispatch hl.dsp.focus({ window = "address:0x2" })',
                'dispatch hl.dsp.window.move({ into_group = "l" })',
                'dispatch hl.dsp.focus({ window = "address:0x1" })',
            ],
        )

    def test_ungroups_all_workspace_windows(self):
        clients = [
            {"address": "0x1", "workspace": {"id": 2}, "mapped": True, "floating": False, "grouped": ["0x1", "0x2"], "at": [0, 0]},
            {"address": "0x2", "workspace": {"id": 2}, "mapped": True, "floating": False, "grouped": ["0x1", "0x2"], "at": [100, 0]},
        ]
        dispatches = self.run_script(
            GROUP_SCRIPT,
            active_window={"address": "0x1", "grouped": ["0x1", "0x2"]},
            clients=clients,
        )

        self.assertEqual(
            dispatches,
            [
                'dispatch hl.dsp.focus({ window = "address:0x1" })',
                "dispatch hl.dsp.window.move({ out_of_group = true })",
                'dispatch hl.dsp.focus({ window = "address:0x2" })',
                "dispatch hl.dsp.window.move({ out_of_group = true })",
                'dispatch hl.dsp.focus({ window = "address:0x1" })',
            ],
        )


if __name__ == "__main__":
    unittest.main()
