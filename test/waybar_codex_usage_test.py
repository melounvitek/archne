#!/usr/bin/env python3
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "local/bin/waybar-codex-usage"


class WaybarCodexUsageTest(unittest.TestCase):
    def run_script(self, codexbar_script):
        with tempfile.TemporaryDirectory() as directory:
            codexbar = Path(directory) / "codexbar"
            codexbar.write_text("#!/usr/bin/env bash\n" + codexbar_script)
            codexbar.chmod(0o755)

            environment = os.environ.copy()
            environment["PATH"] = f"{directory}:{environment['PATH']}"
            environment["TZ"] = "UTC"

            return subprocess.run(
                [SCRIPT],
                capture_output=True,
                check=False,
                env=environment,
                text=True,
            )

    def test_emits_weekly_usage_as_waybar_json(self):
        response = [
            {
                "provider": "codex",
                "usage": {
                    "primary": {
                        "windowMinutes": 300,
                        "resetsAt": "2026-08-01T10:00:00Z",
                        "usedPercent": 10,
                    },
                    "secondary": {
                        "windowMinutes": 10080,
                        "resetsAt": "2026-08-05T04:26:32Z",
                        "usedPercent": 85,
                    },
                },
            }
        ]
        result = self.run_script(f"printf '%s\\n' '{json.dumps(response)}'\n")

        self.assertEqual(result.returncode, 0)
        self.assertEqual(
            json.loads(result.stdout),
            {
                "text": "󰚩  15%",
                "tooltip": "Codex Weekly Usage\n85% used · 15% remaining\nResets Wed 05 Aug, 04:26",
                "class": "warning",
            },
        )

    def test_emits_unavailable_state_when_codexbar_fails(self):
        result = self.run_script("exit 1\n")

        self.assertEqual(result.returncode, 0)
        self.assertEqual(
            json.loads(result.stdout),
            {
                "text": "󰚩  ?",
                "tooltip": "Codex weekly usage unavailable",
                "class": "unavailable",
            },
        )


if __name__ == "__main__":
    unittest.main()
