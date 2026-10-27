---
name: skepsis
description: Open a local browser diff review with skepsis, or address its review comments. Use when the user requests skepsis or a browser review of local changes.
---

# Skepsis reviews

`skepsis` is packaged by these dotfiles. It detects jj before git and needs
no `ah` server, npm installation, or checkout of skepsis.

For feedback to the current agent, run `skepsis-agent` from that agent's
shell tool in the workspace being reviewed:

```sh
skepsis-agent --no-open -r @         # working revision only
skepsis-agent --no-open              # branch from its fork point with trunk
skepsis-agent --no-open -f main -t @ # explicit endpoints
```

Keep the process running with the terminal tool's background/session support.
Give the user the complete URL printed in `skepsis on <url>`, including its
`#token=…` fragment. Use `--no-open` in agent commands so the user can open the
link without a GUI-launch approval. In an interactive shell, `sk` and
`jj review` also launch it and open the browser. Ctrl-C stops that instance.
Choose the requested diff scope; the default includes more than `@`.

The launcher captures this session's identity and enables **Send**:

- Codex: `CODEX_THREAD_ID`, delivered with `codex queue`.
- Claude Code (personal or work): `CLAUDE_CODE_MESSAGING_SOCKET` and its
  inherited token, delivered to that socket. Existing inbound policy still
  applies; socket completion does not prove the agent accepted the message.
- OpenCode 2: `OPENCODE_SESSION_ID`, delivered through the authenticated local
  service described in its XDG state directory.

If multiple harness variables are inherited (nested agents), pass
`--agent codex`, `--agent claude`, or `--agent opencode` for the agent actually
opening the review. Missing identity or service discovery is an error, not a
reason to guess another session. Open a new review after changing sessions.
Use plain `skepsis --no-open` for a review without agent feedback.

The **Comment** button inserts real `<review>` comments into working-copy
files. When asked to address them, inspect the current file and diff, make the
requested change, and remove resolved review markers. These comments do not
wake an agent automatically. The UI offers Refresh when the diff changes;
the displayed diff stays put until refreshed.

**Send** delivers the selected code and feedback without modifying source
files. Replies appear in the agent conversation. Address feedback according
to what the user asks: a question is not an instruction to edit. Delivery
errors remain visible in skepsis; after a timeout, check the conversation
before retrying to avoid duplicate messages. The launcher uses loopback only.

Opening a review does not authorize fixing findings, rewriting jj history,
or publishing changes. Follow the user's requested scope when feedback arrives.
