"""Unit tests requiring no live SSH daemon, DNS, or VM."""

import json
from pathlib import Path
import socket
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
import health_report  # noqa: E402


class TestCommandHandling(unittest.TestCase):
    @patch("health_report.subprocess.run")
    def test_command_success(self, run):
        run.return_value.returncode = 0
        run.return_value.stdout = "active\n"
        run.return_value.stderr = ""
        self.assertEqual(
            health_report.run_command(["systemctl", "is-active", "ssh"]),
            {"ok": True, "output": "active", "error": None},
        )

    @patch("health_report.subprocess.run", side_effect=FileNotFoundError("ip unavailable"))
    def test_missing_command_is_nonfatal(self, unused_run):
        result = health_report.run_command(["ip"])
        self.assertFalse(result["ok"])
        self.assertIn("ip unavailable", result["error"])

    @patch("health_report.socket.create_connection")
    def test_tcp_probe_pass(self, connect):
        connect.return_value.__enter__.return_value = object()
        self.assertEqual(health_report.tcp_probe("localhost", 22), {"reachable": True, "error": None})
        connect.assert_called_once_with(("localhost", 22), timeout=2)

    @patch("health_report.socket.create_connection", side_effect=OSError("refused"))
    def test_tcp_probe_failure(self, unused_connect):
        result = health_report.tcp_probe("localhost", 22)
        self.assertFalse(result["reachable"])
        self.assertIn("refused", result["error"])

    def test_report_fields_and_json(self):
        with patch("health_report.run_command", return_value={"ok": True, "output": "", "error": None}), \
             patch("health_report.tcp_probe", return_value={"reachable": True, "error": None}):
            report = health_report.collect_report("127.0.0.1", 2222)
        self.assertEqual(report["tcp_probe"]["port"], 2222)
        self.assertIn("used_percent", report["disk_root"])
        self.assertIn("generated_at_utc", report)
        json.dumps(report)

    def test_output_is_private_and_parseable(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "reports" / "health.json"
            result = health_report.write_report({"ok": True}, output)
            self.assertEqual(result, output)
            self.assertEqual(json.loads(output.read_text()), {"ok": True})
            self.assertEqual(output.stat().st_mode & 0o777, 0o600)

    def test_invalid_port_rejected(self):
        with self.assertRaises(SystemExit) as raised:
            health_report.main(["--tcp-port", "0"])
        self.assertEqual(raised.exception.code, 2)

    def test_invalid_timeout_rejected(self):
        with self.assertRaises(SystemExit) as raised:
            health_report.main(["--timeout", "0"])
        self.assertEqual(raised.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
