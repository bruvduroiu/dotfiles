"""Transport and routing checks using local peers, never live agent sessions."""

import base64
import importlib.util
import io
import json
import os
from pathlib import Path
import socket
import sys
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, HTTPServer
from unittest.mock import patch
import urllib.error

SCRIPT = Path(__file__).with_name("skepsis-agent.py")
SPEC = importlib.util.spec_from_file_location("skepsis_agent", SCRIPT)
bridge = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(bridge)


class FeedbackTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        env = {
            key: value
            for key, value in os.environ.items()
            if key not in bridge.SESSION_VARS.values()
        }
        env["XDG_STATE_HOME"] = str(self.root)
        self.environ = patch.dict(os.environ, env, clear=True)
        self.environ.start()
        self.addCleanup(self.environ.stop)

    def service(self, url, split=False):
        directory = self.root / "opencode"
        directory.mkdir(exist_ok=True)
        data = {"url": url}
        if split:
            (directory / "password").write_text("test-password\n")
        else:
            data["password"] = "test-password"
        (directory / ("server.json" if split else "service.json")).write_text(
            json.dumps(data)
        )

    def test_auto_and_explicit_session_selection(self):
        with self.assertRaises(bridge.FeedbackError):
            bridge.target_for("auto")
        os.environ["CODEX_THREAD_ID"] = "thread-a"
        frozen = bridge.target_for("auto")
        os.environ["CODEX_THREAD_ID"] = "thread-b"
        self.assertEqual(frozen["identity"], "thread-a")
        os.environ["OPENCODE_SESSION_ID"] = "session-a"
        with self.assertRaises(bridge.FeedbackError):
            bridge.target_for("auto")
        self.assertEqual(bridge.target_for("codex")["identity"], "thread-b")
        with self.assertRaises(bridge.FeedbackError):
            bridge.target_for("claude")

    def test_rejects_invalid_and_oversized_feedback(self):
        for data in [
            None,
            [],
            {},
            {"prompt": 7},
            {"prompt": " "},
            {"prompt": "x" * 65537},
        ]:
            with (
                self.subTest(data_type=type(data).__name__),
                self.assertRaises(bridge.FeedbackError),
            ):
                bridge.read_prompt(io.BytesIO(json.dumps(data).encode()))
        with self.assertRaises(bridge.FeedbackError):
            bridge.read_prompt(io.BytesIO(b"x" * (bridge.MAX_INPUT + 1)))

    def test_codex_passes_feedback_as_data_and_reports_failure(self):
        executable = self.root / "codex"
        output = self.root / "args.json"
        executable.write_text(
            f"#!{sys.executable}\nimport json,sys\n"
            f"open({str(output)!r}, 'w').write(json.dumps(sys.argv[1:]))\n"
        )
        executable.chmod(0o700)
        os.environ["SKEPSIS_CODEX"] = str(executable)
        prompt = "Review `echo unsafe`; $(false)\n'quoted' feedback"
        target = {"agent": "codex", "identity": "thread-a"}
        bridge.deliver(target, prompt)
        self.assertEqual(
            json.loads(output.read_text()),
            ["queue", "--thread", "thread-a", "--message", prompt],
        )
        executable.write_text(f"#!{sys.executable}\nraise SystemExit(3)\n")
        with self.assertRaisesRegex(bridge.FeedbackError, "exit 3"):
            bridge.deliver(target, prompt)

    def test_claude_socket_auth_and_message(self):
        address = str(self.root / "claude.sock")
        with socket.socket(socket.AF_UNIX) as server:
            server.bind(address)
            server.listen()
            server.settimeout(3)
            received = []

            def receive():
                connection, _ = server.accept()
                with connection, connection.makefile("rb") as stream:
                    received.extend(json.loads(line) for line in stream)

            thread = threading.Thread(target=receive, daemon=True)
            thread.start()
            os.environ.update(
                CLAUDE_CODE_MESSAGING_SOCKET=address,
                CLAUDE_CODE_MESSAGING_TOKEN="test-token",
            )
            bridge.deliver(bridge.target_for("auto"), "Please explain this line")
            thread.join(3)
            self.assertFalse(thread.is_alive())
            self.assertEqual(
                received,
                [
                    {"type": "auth", "token": "test-token"},
                    {
                        "type": "user",
                        "message": {
                            "role": "user",
                            "content": "Please explain this line",
                        },
                    },
                ],
            )
        with self.assertRaises(OSError):
            bridge.deliver(
                {"agent": "claude", "identity": address, "token": ""}, "closed"
            )

    def test_opencode_auth_session_routing_and_http_failures(self):
        received = []
        status = [200]

        class Handler(BaseHTTPRequestHandler):
            def do_POST(self):
                body = self.rfile.read(int(self.headers["Content-Length"]))
                received.append(
                    (self.path, self.headers["Authorization"], json.loads(body))
                )
                self.send_response(status[0])
                self.send_header("Location", "http://127.0.0.1:1/never-follow")
                self.end_headers()

            def log_message(self, *args):
                pass

        with HTTPServer(("127.0.0.1", 0), Handler) as server:
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            try:
                self.service(f"http://127.0.0.1:{server.server_port}", split=True)
                os.environ["OPENCODE_SESSION_ID"] = "session/with space"
                target = bridge.target_for("auto")
                with patch.dict(
                    os.environ, {"http_proxy": "http://127.0.0.1:1", "no_proxy": ""}
                ):
                    bridge.deliver(target, "Feedback")
                self.assertEqual(
                    received[0],
                    (
                        "/api/session/session%2Fwith%20space/prompt",
                        "Basic " + base64.b64encode(b"opencode:test-password").decode(),
                        {"text": "Feedback"},
                    ),
                )
                for code in (401, 500, 302):
                    status[0] = code
                    with self.assertRaises(urllib.error.HTTPError) as error:
                        bridge.deliver(target, "Rejected")
                    self.assertEqual(error.exception.code, code)
            finally:
                server.shutdown()
                thread.join(3)

    def test_opencode_discovery_validation(self):
        self.service("http://127.0.0.1:1234")
        self.assertEqual(bridge.opencode_service()["password"], "test-password")
        for url in [
            "http://example.com",
            "http://127.0.0.1@evil.test",
            "http://127.0.0.1/path",
            "http://localhost/#fragment",
        ]:
            self.service(url)
            with self.assertRaises(bridge.FeedbackError):
                bridge.opencode_service()

    def test_launcher_binds_target_and_preserves_arguments(self):
        os.environ.update(CODEX_THREAD_ID="thread-a", SKEPSIS_BIN="/test/skepsis")
        with (
            patch.object(
                sys, "argv", [str(SCRIPT), "--agent", "codex", "--no-open", "-r", "@"]
            ),
            patch.object(os, "execve") as execute,
        ):
            bridge.main()
        binary, argv, env = execute.call_args.args
        self.assertEqual(binary, "/test/skepsis")
        self.assertEqual(argv[1:4], ["--host", "localhost", "--send"])
        self.assertEqual(argv[5:], ["--no-open", "-r", "@"])
        self.assertEqual(
            json.loads(env["SKEPSIS_AGENT_TARGET"])["identity"], "thread-a"
        )

    def test_rejects_transport_overrides(self):
        for option in ["--send=wrong", "--host", "--dev"]:
            with (
                patch.object(sys, "argv", [str(SCRIPT), option]),
                self.assertRaises(SystemExit) as error,
            ):
                bridge.main()
            self.assertEqual(error.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
