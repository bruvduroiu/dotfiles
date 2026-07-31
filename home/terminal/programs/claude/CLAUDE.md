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

## Development practices

- Verify a command's tool is reachable (`command -v`, or just wrap it in
  `nix run`/`nix shell`) before building a plan around it.
- Validate inputs, handle edge cases, and consider the security implications of
  file access and command execution.
- Match the surrounding code's style and conventions.
- Test before claiming something works; report failures with the actual output.
