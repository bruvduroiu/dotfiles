---
name: nix-app
description: The user's house layout for wrapping an application in Nix so it is deploy-ready — flake.nix (inputs/outputs, flake-parts), default.nix (package), shell.nix (dev shell + recipes instead of make/just), direnv `.envrc` that sources sops secrets decrypted with the YubiKey (age-plugin-yubikey, never new age keys), plus a NixOS module and an OCI image. Use when creating a new project, or when the user asks to nixify, package, add a dev shell / recipes / secrets / deployment to a repo. Templates for Go (buildGoModule) and Python (uv2nix) ship in this skill.
---

# Nix app layout

## When to activate

- **New project**: always scaffold it this way.
- **Existing repo**: only when the user asks (nixify, package, dev shell, recipes,
  secrets, deploy). Don't migrate a repo on your own initiative.

## The mental model

Three files, three jobs. Each one is importable on its own, and `flake.nix` only
wires them together:

| File | Job | Shape |
|---|---|---|
| `flake.nix` | Inputs (pins) + outputs. **No build logic.** | flake-parts `mkFlake`, `perSystem` |
| `default.nix` | How the app is built. | `{ lib, buildGoModule, … }: …`, called with `pkgs.callPackage` |
| `shell.nix` | Dev shell **and the recipes** (replaces make/just). | `{ pkgs, package }: pkgs.mkShell { … }` |
| `nix/module.nix` | NixOS service. Secrets come from the host. | `{ self }: { config, lib, pkgs, … }: …` |
| `nix/image.nix` | OCI image, no Dockerfile. Linux only. | `dockerTools.buildLayeredImage` |
| `.envrc` | `use flake`, then decrypt `secrets.env.yaml` into the env | direnv + nix-direnv |
| `.sops.yaml` | Recipient = the YubiKey's age-plugin-yubikey identity | |

The flow for a human: `cd repo` → direnv loads the flake's dev shell → `.envrc`
decrypts `secrets.env.yaml` (**one YubiKey touch per load**) → recipes and
secrets are in the shell → coding agents launched **from that shell inherit
all of it**.

Outputs every project has: `packages.default`, `packages.image` (Linux),
`devShells.default`, `checks` (package build + tests + treefmt), `formatter`
(treefmt-nix: nixfmt + the language's formatter), `nixosModules.default`.
Systems: `x86_64-linux`, `aarch64-darwin`. nixpkgs: `nixos-unstable`.

## Scaffolding

The templates live next to this file in `template/`: `common/` plus one
language directory (`go/` or `python/`). Store copies are read-only, hence
`--no-preserve=mode`. Dotfiles are stored without the dot so they stay visible.

```bash
T=<this skill's directory>/template
cp -r --no-preserve=mode "$T"/common/. "$T"/<go|python>/. .
mv envrc .envrc && mv gitignore .gitignore && mv sops.yaml .sops.yaml
sed -i 's/myapp/<name>/g' flake.nix default.nix shell.nix nix/*.nix
```

Then:

1. **Make the files visible to the flake.** Flakes only see tracked files. In a
   jj repo any `jj st` snapshots them; for a new project run
   `jj git init --colocate` first. Never `git add` in a jj repo.
2. Python: the app needs `pyproject.toml` + `uv.lock` (`uv init --package`,
   `uv add --dev pytest`). Go: `go.mod`; set `vendorHash` (see below).
3. `.sops.yaml`: replace `age1yubikey1REPLACE_ME` with the output of
   `age-plugin-yubikey --list` (public recipient, no touch needed), or copy the
   recipient from another of the user's repos. **Never** run `age-keygen` or
   `age-plugin-yubikey --generate`.
4. Verify (see the checklist at the end), then tell the human to run
   `direnv allow`. Agents never run `direnv allow` for them.

## flake.nix

- Inputs: `nixpkgs` (nixos-unstable), `flake-parts`, `treefmt-nix`, plus
  language inputs. Every input `follows = "nixpkgs"` where it has one.
- `perSystem` only calls things: `pkgs.callPackage ./default.nix { … }`,
  `import ./shell.nix { inherit pkgs; package = config.packages.default; }`.
- The image is guarded with `lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux`.
  On darwin it would wrap a Mach-O binary that no container can run.
- `checks.package = config.packages.default`, merged with
  `config.packages.default.tests` when default.nix exposes them.
- `flake.nixosModules.default = import ./nix/module.nix { inherit self; };`.
- Never edit `flake.lock` by hand. `nix flake update` only when the user asks.

## default.nix

**Go** (`buildGoModule`):
- `src` = `lib.fileset` filtered to `*.go`, `go.mod`, `go.sum`, so that editing
  shell.nix or docs doesn't rebuild the app. Add embedded assets and testdata
  explicitly.
- `vendorHash = null` when there are no deps. Otherwise set it to `lib.fakeHash`,
  run `nix build`, and paste the `got:` hash. Re-do this after every `go get`.
- `env.CGO_ENABLED = 0` (static, image-friendly), `meta.mainProgram` set (the
  module and image use `lib.getExe`).
- `go test ./...` runs in checkPhase, so `checks.package` is also the test suite.

**Python** (uv2nix):
- `pyproject.toml` + `uv.lock` are the source of truth. Dependencies change via
  `uv add` / `uv remove`, never by editing Nix. **Commit `uv.lock`.**
- `pythonSet` = pyproject.nix base set + build-systems overlay +
  `workspace.mkPyprojectOverlay { sourcePreference = "wheel"; }` + a fixes
  overlay. Native-lib or missing-build-system failures get fixed in that last
  overlay, per package.
- `mkApplication` exposes only the app's own executables. Tests are a separate
  `deps.all` venv (`[dependency-groups] dev` holds pytest), attached with
  `lib.extendDerivation` as `.tests.pytest` and run by `nix flake check`.
- Inputs arrive as callPackage arguments
  (`inherit (inputs) pyproject-nix uv2nix pyproject-build-systems`).

## shell.nix and recipes

Recipes are `writeShellApplication` binaries placed in `mkShell.packages`. They
are **not** shell functions or aliases: direnv only exports environment
variables, so anything defined in `shellHook` never reaches the user's fish
shell. Each recipe pins its own `runtimeInputs`.

```nix
recipe = name: description: runtimeInputs: text:
  pkgs.writeShellApplication {
    inherit name runtimeInputs text;
    meta.description = description;
  };
```

Standard set: `dev`, `tests`, `lint`, `push-image`, `secrets`, and `recipes`
(lists the others). Rules:

- **Never name a recipe after a shell builtin or a coreutils tool.** `test`
  silently runs the builtin instead of your recipe, and `fmt` shadows coreutils.
  That's why it's `tests`, and formatting is just `nix fmt`. Check with `type -a <name>`.
- shellcheck runs at build time. A `'$VAR'` meant literally (SC2016) fails the
  shell build, so emit literal text through a quoted heredoc.
- Non-secret dev config goes in `mkShell.env` (committed). Secrets never go
  in shell.nix.
- Python: the shell provides `python3` + `uv` with `UV_PYTHON` pinned and
  `UV_PYTHON_DOWNLOADS=never`. Day-to-day work runs in uv's `.venv`, while the
  Nix build follows the same lock. `shellHook` unsets `PYTHONPATH`.
- sops and age-plugin-yubikey are in the shell because `.envrc` decrypts
  *after* `use flake`.

## Secrets: sops + YubiKey

- One file, `secrets.env.yaml`: a flat map that `.envrc` decrypts with
  `sops decrypt --output-type dotenv` and exports. A failed decrypt logs a red
  direnv error and loads nothing. It never exports half a file.
- **No plaintext on disk, no cache.** Every direnv load decrypts again with a
  touch. That's deliberate.
- Recipient: the YubiKey via age-plugin-yubikey. No new age identities, no
  `age-keygen`, no keys committed. The identity stub lives in
  `~/.config/sops/age/keys.txt`: **never read it**.
- Agents don't decrypt or edit secrets. `sops edit` is interactive and needs a
  touch, so tell the human to run the `secrets` recipe. Adding a recipient
  means `sops updatekeys secrets.env.yaml` (human, with a touch).
- Agents inherit the decrypted env from the shell they were started in. Never
  print it (`env`, `printenv FOO`, `echo $TOKEN`). Pass secrets by reference
  (let the program read the env var).

## Deployment

**NixOS module** (`nix/module.nix`): `services.<name>.{enable, package,
environmentFile, environment}`, DynamicUser, a hardened systemd unit.
`environmentFile` is `types.str` on purpose: a Nix path literal would copy
the secret into the world-readable store, and `str` rejects it. The module never
imports sops. The host wires it:

```nix
# in the dotfiles host config
imports = [ inputs.myapp.nixosModules.default ];
sops.secrets.myapp-env = { sopsFile = …; format = "dotenv"; };
services.myapp = {
  enable = true;
  environmentFile = config.sops.secrets.myapp-env.path;
};
# hosts with the late YubiKey decrypt: start only after secrets exist
systemd.services.myapp = {
  after = [ "sops-install-secrets-yubikey.service" ];
  wants = [ "sops-install-secrets-yubikey.service" ];
};
```

**OCI image** (`nix/image.nix`): `buildLayeredImage`, tag = package version,
cacert included, runs as 65534. The registry is per-project, not defaulted:
`push-image` needs `REGISTRY` (`host/namespace`) and optionally
`REGISTRY_USER`/`REGISTRY_PASSWORD`, all from `secrets.env.yaml`. It uses
skopeo, so no docker daemon is needed. Secrets are never baked into the image.

## Working inside such a repo (agents)

- You were launched from the direnv-loaded shell: tools, recipes, and secrets
  are **already on PATH and in the env**. Don't wrap commands in
  `direnv exec .` or `nix develop -c`. That would decrypt again and cost
  another touch.
- **Exception:** after *you* edit `shell.nix`, `default.nix` or `flake.nix`,
  your process env is stale. Verify the new shell with
  `nix develop -c <recipe>`, and tell the human to reload (their direnv picks it
  up on the next prompt; restart the agent to inherit it).
- If something expected is missing from PATH, the session probably wasn't
  started inside the repo's shell. Say so instead of working around it.

## Verify before claiming done

```bash
jj st                                  # snapshot → new files tracked
nix flake check                        # build + tests + treefmt
nix build .#image --no-link            # Linux
nix develop -c recipes                 # shell builds, shellcheck passes
nix fmt                                # if treefmt-check failed
```

## Anti-pattern clinic

| Old reflex | Why it breaks here | Instead |
|---|---|---|
| Makefile / justfile | A second task runner with unpinned tools | recipe in shell.nix |
| `shellHook` with `alias`/functions | direnv exports env only; they never reach the user's shell | `writeShellApplication` recipe |
| Recipe named `test` / `fmt` | builtin / coreutils wins or gets shadowed | `tests`; `nix fmt` |
| `buildGoModule` in flake.nix | Build logic mixed into wiring | `default.nix` + `callPackage` |
| `age-keygen` for a new project | Key material on disk; violates YubiKey-only policy | age-plugin-yubikey recipient |
| Plaintext `.env` with secrets | Plaintext on disk, gets committed | `secrets.env.yaml` via sops |
| `direnv exec . cmd` per command | Re-decrypts → a touch per command; env is already inherited | run `cmd` directly |
| `environmentFile = ./secret.env` | Copies the secret into /nix/store | sops-nix path string |
| `docker build` / Dockerfile | Non-reproducible, needs a daemon | `nix build .#image` + `push-image` |
| `pip install` / editing deps in Nix (Python) | Lock and Nix drift apart | `uv add`; uv2nix reads `uv.lock` |
| New files, then `nix build` fails "not found" | Flake only sees tracked files | `jj st` first |
