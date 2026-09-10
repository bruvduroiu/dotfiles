# Global Instructions

## This machine runs NixOS

There is no FHS. `/usr/bin` is nearly empty, `/lib` does not exist, and there is
no system-wide `python3`, `node`, `pip`, `cargo`, `gcc`, or `uv`. A tool missing
from `PATH` is **normal**, not a broken install.

**Never** try to fix a missing tool with `apt`/`dnf`/`brew`, `pip install`,
`npm i -g`, `cargo install`, `go install`, or `curl … | sh`. They will fail, or
worse, half-succeed and leave junk in `$HOME`. Bring the tool in through Nix
instead.

### Getting a tool for a single command

Work down this list; stop at the first one that applies.

| Situation | Command |
|---|---|
| Repo has `.envrc` | `direnv exec . <cmd>` |
| Repo has `flake.nix` with a devShell | `nix develop -c <cmd>` |
| Repo has `shell.nix`, no flake | `nix-shell --run '<cmd>'` |
| Repo has `devenv.nix` | `devenv shell -- <cmd>` |
| Nothing project-local | `nix run nixpkgs#<pkg> -- <args>` |
| Need several tools at once | `nix shell nixpkgs#<a> nixpkgs#<b> -c <cmd>` |

Notes:

- **direnv must be explicit.** The direnv shell hook only runs in the user's
  interactive fish shell. Commands issued through the Bash tool do *not* pick up
  `.envrc`; `direnv exec . <cmd>` (or `direnv allow` first, if it has never been
  approved) is required.
- **Don't assume `nix develop` gives language tooling.** A flake's default
  devShell can be for anything. Run `nix flake show` or read `shell.nix` before
  relying on it. (Example: this dotfiles repo's default devShell is Android/Boox
  flashing tools — it contains no Nix development tooling at all.)
- `nix run` and `nix shell` may download from the binary cache on first use;
  give them a generous timeout, not the default.

### Python

```bash
# stdlib only
nix run nixpkgs#python3 -- script.py

# with nixpkgs-provided libraries
nix-shell -p "python3.withPackages(ps: with ps; [ requests numpy ])" \
  --run "python3 script.py"

# same thing, flake-style
nix shell --impure --expr \
  'with import <nixpkgs> {}; python3.withPackages(ps: with ps; [ requests ])' \
  -c python3 script.py

# project with a requirements.txt / pyproject.toml — use uv inside a nix shell
nix shell nixpkgs#uv -c bash -c 'uv venv && uv pip install -r requirements.txt && .venv/bin/python script.py'
```

`uv` and `pip` work fine **inside a venv created under a Nix shell** — manylinux
wheels (numpy, pydantic, …) load correctly. What does not work is installing
into a "system" Python, because there isn't one.

A `#!/usr/bin/env python3` shebang fails outside a Nix shell. Invoke the
interpreter explicitly (`… -c python3 script.py`) rather than `./script.py`.

### Prebuilt binaries downloaded from the internet

A dynamically-linked binary from outside Nix fails with a confusing
`No such file or directory` even though the file is right there — the missing
path is its ELF interpreter (`/lib64/ld-linux-x86-64.so.2`), not the binary.

In order of preference:
1. Use the nixpkgs build of the tool instead.
2. `nix run nixpkgs#steam-run -- ./thebinary` (FHS sandbox, no config change).
3. `programs.nix-ld` is enabled on this host; a library it lacks gets added to
   `system/programs/nix-ld.nix` (requires a rebuild — ask first).

### Writing temporary scripts

Put them in the session scratchpad directory, never in the repo, and run them
through one of the shells above.

## Rebuilding this system

The dotfiles flake lives at `~/development/dotfiles`. Hosts: `framework13`
(this laptop), `phantom`, `steamdeck`. Home Manager is a NixOS module on
`framework13`, so a system rebuild also applies user config.

```bash
# check evaluation without touching the system — safe, do this freely
nix flake check ~/development/dotfiles
nix eval ~/development/dotfiles#nixosConfigurations.framework13.config.<attr>
nixos-rebuild build --flake ~/development/dotfiles#framework13   # no root needed
```

`nixos-rebuild test` and `nixos-rebuild switch` need root and change the running
system — **ask before running either**. `nix flake update` rewrites `flake.lock`;
ask as well. Never edit `flake.lock` by hand.

Packages are declared, not installed: system-wide in `system/`, user-level in
`home/`, host overrides in `hosts/<host>/`. Adding a tool means editing the right
`.nix` file, not running an installer.

## Version control: jj-first

When a repo has a `.jj` directory, it is a Jujutsu repo colocated with git
(`.git` alongside `.jj`). jj is authoritative; treat git as a read-only view.

- Orient with `jj st`, `jj diff`, `jj log`, `jj show` — not `git status` /
  `git diff` / `git add`.
- Work lands in the working-copy revision `@`, which jj snapshots
  automatically. There is no staging area and nothing to commit. **Never run
  `git commit`, `git add`, or `git stash`** — a git-side commit in a
  colocated repo diverges from jj's view and has to be reconciled.
- **Never rewrite or land history**: no `jj squash`, `jj abandon`, `jj undo`,
  `jj rebase`, `jj op restore`, or `jj git push`. The human reviews the diff
  and carves `@` into revisions themselves (split/absorb/tug/push).
- **The one exception: the `/jj-stack`, `/jj-stack-push` and `/jj-stack-sync`
  skills.** When the human invokes one, rewriting is authorised for that
  skill's duration, bounded as its SKILL.md says: only revisions in
  `trunk()..@ & mine()`, only by naming revsets (`split`, `restore --from`,
  `rebase -r/-b`, `absorb`, `squash --into`, `bookmark set`, `git push -b
  'glob:…'`), never `jj edit`, never another author's revision, and
  `abandon`/`undo`/`op restore` stay human-only. Print the `jj op log` id
  first so the human has a one-command undo. If `@` grows past ~400
  changed lines, *suggest* `/jj-stack`; never run it unasked.
- Starting a substantial task on a dirty `@` that isn't yours? Suggest (or,
  if asked, run) `jj new -m "claude: <task>"` first so the session's work is
  isolated in its own revision. `jj describe` may update that revision's
  message; leave every other revision's message alone.

### Parallel agents: one workspace per agent

Multiple agent sessions may work the same repo at once. The unit of isolation
is the **jj workspace** (`jj workspace add`): shaped like a git worktree, but
all workspaces share one repo and one operation log, and each has its own
working-copy revision — shown as `<name>@` in `jj log`. Concurrent jj
commands from *different* workspaces are safe; the op log merges them. Two
agents snapshotting the **same directory** are not: never share a working
copy with another agent.

- Each parallel session gets a workspace, created off trunk (this mutates
  the repo — ask, or let the human pre-create it):

  ```
  jj workspace add --name claude-<task> -r 'trunk()' \
      -m "claude: <task>" ../<repo>.claude-<task>
  ```

  Then work entirely inside that directory. Its `@` is yours alone; every
  single-`@` rule above applies there unchanged.
- Secondary workspaces have no `.git` — git commands fail in them. That is
  fine: git was a read-only view anyway. Orient with jj only.
- Other agents' in-flight work is already visible — `jj log` shows every
  workspace's `<name>@`. There is nothing to fetch, pull, or sync.
- **Conflicts are data, not failures.** Integrating parallel lines is
  `jj new claude-a@ claude-b@ -m "claude: merge a+b"` — it always succeeds.
  Conflicted files carry markers; `jj st` lists them and
  `jj log -r 'conflicts()'` finds them repo-wide. Resolve by editing the
  files in that merge revision — the snapshot picks it up. There is no
  `--abort`, no `MERGE_HEAD`, no "commit your changes first".
- A workspace can go **stale** (jj says so explicitly) when its `@`'s
  ancestry is rewritten from another workspace. Recovery is
  `jj workspace update-stale`, then re-read `jj diff` before continuing.
  Never delete and re-create a workspace over staleness.
- Don't stack on another agent's live `@`: it is amended on every snapshot,
  so the child rebases constantly and its workspace goes stale on repeat.
  Build on a described, finished revision instead.
- `jj workspace forget`, like all history surgery, stays human-only.

## Development practices

- Verify a command's tool is reachable (`command -v`, or just wrap it in
  `nix run`/`nix shell`) before building a plan around it.
- Validate inputs, handle edge cases, and consider the security implications of
  file access and command execution.
- Match the surrounding code's style and conventions.
- Test before claiming something works; report failures with the actual output.
