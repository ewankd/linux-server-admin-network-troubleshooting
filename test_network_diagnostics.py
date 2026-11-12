"""End-to-end local-only tests of the Bash network diagnostic CLI."""

from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import socket
import subprocess
import threading
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "network_diagnostics.sh"


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


class TestNetworkDiagnostics(unittest.TestCase):
    def test_running_local_http_service(self):
        server = ThreadingHTTPServer(
            ("127.0.0.1", 0), partial(QuietHandler, directory=str(ROOT / "site"))
        )
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        try:
            thread.start()
            port = server.server_address[1]
            result = subprocess.run(
                ["bash", str(SCRIPT), "--offline", "--host", "127.0.0.1",
                 "--port", str(port), "--http-url", f"http://127.0.0.1:{port}/"],
                check=False, text=True, capture_output=True, timeout=12,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("[PASS] TCP connection", result.stdout)
            self.assertIn("[PASS] HTTP endpoint", result.stdout)
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=3)

    def test_stopped_tcp_service(self):
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]
        result = subprocess.run(
            ["bash", str(SCRIPT), "--offline", "--host", "127.0.0.1",
             "--port", str(port)],
            check=False, text=True, capture_output=True, timeout=12,
        )
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("[FAIL] TCP connection", result.stdout)


if __name__ == "__main__":
    unittest.main()
