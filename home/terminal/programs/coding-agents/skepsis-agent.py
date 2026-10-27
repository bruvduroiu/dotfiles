"""Launch skepsis with feedback bound to the invoking coding-agent session."""

import argparse
import base64
import json
import os
from pathlib import Path
import shlex
import socket
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request


SESSION_VARS = {
    "codex": "CODEX_THREAD_ID",
    "claude": "CLAUDE_CODE_MESSAGING_SOCKET",
    "opencode": "OPENCODE_SESSION_ID",
}
MAX_INPUT = 1024 * 1024


class FeedbackError(Exception):
    """A diagnostic safe to display without request bodies or credentials."""


def opencode_service():
    """Capture the local service once, so later discovery cannot change targets."""
    state = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
    directory = state / "opencode"
    for name in ("service.json", "server.json"):
        path = directory / name
        if not path.exists():
            continue
        service = json.loads(path.read_text())
        if not isinstance(service, dict) or not isinstance(service.get("url"), str):
            raise FeedbackError("OpenCode service discovery is invalid")
        url = service.get("url", "")
        parsed = urllib.parse.urlsplit(url)
        if (
            parsed.scheme != "http"
            or parsed.hostname not in ("localhost", "127.0.0.1", "::1")
            or parsed.username is not None
            or parsed.password is not None
            or parsed.path not in ("", "/")
            or parsed.query
            or parsed.fragment
        ):
            raise FeedbackError("OpenCode service must use a loopback HTTP URL")
        password = service.get("password")
        if password is None:
            password = (directory / "password").read_text().strip()
        if not isinstance(password, str) or not password:
            raise FeedbackError("OpenCode service password is missing")
        return {"url": url.rstrip("/"), "password": password}
    raise FeedbackError("OpenCode 2 service discovery files are missing")


def target_for(agent):
    available = [name for name, var in SESSION_VARS.items() if os.environ.get(var)]
    if agent == "auto":
        if len(available) != 1:
            raise FeedbackError(
                "Run from an agent's shell tool; if nested, select --agent "
                "codex, claude, or opencode explicitly"
            )
        agent = available[0]
    identity = os.environ.get(SESSION_VARS[agent])
    if not identity:
        raise FeedbackError(f"{SESSION_VARS[agent]} is missing; launch from that agent")
    target = {"agent": agent, "identity": identity}
    if agent == "claude":
        target["token"] = os.environ.get("CLAUDE_CODE_MESSAGING_TOKEN", "")
        if not Path(identity).is_socket():
            raise FeedbackError("Claude's session inbox socket is unavailable")
    elif agent == "opencode":
        target.update(opencode_service())
    return target


def read_prompt(stream):
    raw = stream.read(MAX_INPUT + 1)
    if len(raw) > MAX_INPUT:
        raise FeedbackError("Feedback payload exceeds 1 MiB")
    data = json.loads(raw)
    prompt = data.get("prompt") if isinstance(data, dict) else None
    if not isinstance(prompt, str) or not prompt.strip():
        raise FeedbackError("Feedback must contain a non-empty prompt string")
    # Codex passes this as one argv entry; stay below Linux's per-argument cap.
    if len(prompt.encode()) > 64 * 1024:
        raise FeedbackError("Feedback exceeds 64 KiB; submit a smaller selection")
    return prompt


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def deliver(target, prompt):
    agent = target["agent"]
    identity = target["identity"]
    if agent == "codex":
        result = subprocess.run(
            [
                os.environ["SKEPSIS_CODEX"],
                "queue",
                "--thread",
                identity,
                "--message",
                prompt,
            ],
            capture_output=True,
            timeout=7,
            check=False,
        )
        if result.returncode:
            raise FeedbackError(
                f"Codex queue failed (exit {result.returncode}); check the target session"
            )
    elif agent == "claude":
        lines = []
        if target["token"]:
            lines.append({"type": "auth", "token": target["token"]})
        lines.append({"type": "user", "message": {"role": "user", "content": prompt}})
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
            connection.settimeout(7)
            connection.connect(identity)
            connection.sendall(
                "".join(json.dumps(line) + "\n" for line in lines).encode()
            )
            connection.shutdown(socket.SHUT_WR)
            while connection.recv(4096):
                pass
        # The socket has no delivery acknowledgement; inbound policy may hold it.
    elif agent == "opencode":
        auth = base64.b64encode(f"opencode:{target['password']}".encode()).decode()
        request = urllib.request.Request(
            f"{target['url']}/api/session/{urllib.parse.quote(identity, safe='')}/prompt",
            data=json.dumps({"text": prompt}).encode(),
            headers={
                "Authorization": f"Basic {auth}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        # Local credentials must never go through an HTTP proxy or redirect.
        opener = urllib.request.build_opener(
            urllib.request.ProxyHandler({}), NoRedirect()
        )
        with opener.open(request, timeout=7) as response:
            if not 200 <= response.status < 300:
                raise FeedbackError(
                    f"OpenCode rejected feedback (HTTP {response.status})"
                )
    else:
        raise FeedbackError("Unknown feedback transport")


def main():
    if sys.argv[1:] == ["_send"]:
        deliver(
            json.loads(os.environ["SKEPSIS_AGENT_TARGET"]),
            read_prompt(sys.stdin.buffer),
        )
        return
    parser = argparse.ArgumentParser(
        description=__doc__,
        epilog="Other arguments are passed to skepsis, e.g. --no-open -r @.",
        allow_abbrev=False,
    )
    parser.add_argument(
        "--agent",
        choices=["auto", *SESSION_VARS],
        default="auto",
        help="default: auto, requiring exactly one harness session in the environment",
    )
    args, options = parser.parse_known_args()
    if options[:1] == ["--"]:
        options = options[1:]
    for option in options:
        if option.split("=", 1)[0] in ("--send", "--host", "--dev"):
            parser.error("--send, --host and --dev are managed by skepsis-agent")
    target = target_for(args.agent)
    env = dict(os.environ, SKEPSIS_AGENT_TARGET=json.dumps(target))
    callback = shlex.join([sys.executable, str(Path(__file__).resolve()), "_send"])
    command = [
        os.environ["SKEPSIS_BIN"],
        "--host",
        "localhost",
        "--send",
        callback,
        *options,
    ]
    print(
        f"skepsis-agent: feedback bound to this {target['agent']} session",
        file=sys.stderr,
    )
    os.execve(command[0], command, env)


if __name__ == "__main__":
    try:
        main()
    except urllib.error.HTTPError as error:
        sys.exit(f"skepsis-agent: OpenCode rejected feedback (HTTP {error.code})")
    except FeedbackError as error:
        sys.exit(f"skepsis-agent: {error}")
    except (TimeoutError, subprocess.TimeoutExpired):
        sys.exit(
            "skepsis-agent: delivery timed out; check the conversation before retrying"
        )
    except (OSError, ValueError, KeyError) as error:
        # Do not echo payloads, subprocess argv, credentials, or service files.
        sys.exit(
            f"skepsis-agent: {type(error).__name__}; check the target session and service"
        )
