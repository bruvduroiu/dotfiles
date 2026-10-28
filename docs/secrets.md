# Secrets: where each one lives

Companion to `system/core/sops.nix`, the private flake (`inputs.secrets`,
`~/development/secrets`) and `home/programs/keepassxc.nix`. Rotation steps are in
[`rotation.md`](rotation.md).

---

## 0. The governing idea: ask who reads it, and when

There is no single best store. Each secret goes where its **reader** can get at
it at the moment it needs it. Answer two questions and the store follows:

1. **Who reads it?** Nix at build time, root or systemd at boot, a user service
   in the background, you at the terminal, or the app itself (writing back).
2. **When?** Before anyone logs in, while the screen is locked, or only while
   you are at the desk.

| Reader, and when | Store | Examples |
|---|---|---|
| **Nix at build time** (private, not secret) | `inputs.secrets.vars` | WireGuard topology, host overlay IPs, syncthing device IDs, identity email, aws profiles |
| **root or systemd, no one logged in** | sops (system) | WireGuard private keys, restic and storage-box passwords, transmission |
| **user services, screen possibly locked** | sops (home) | syncthing GUI password, dictation key, opencode provider keys (opencode-web, scheduler timers), forgejo token |
| **you, at the terminal** | sops (home), **scoped to one command** | DeepSeek for `mods`, Alpha Vantage for `portfolio-update-prices`, `withkey …` |
| **the app, rewriting its own credential** | KeePassXC Secret Service | hey's OAuth login (refresh token rotates on every refresh), Codex's ChatGPT login and `codex mcp login` tokens, `podman login` / `docker login` registry credentials |

Both stores have the same hardware root: sops decrypts with the YubiKey
(age-plugin-yubikey), and nothing in this repo creates a software age identity.

### What each store can't do

- **sops is read-only at runtime.** A value changes only when you `sops edit`,
  commit to the private repo, and run `nix flake update secrets`. An app that
  refreshes its own token can't write the new one back, so the sops copy goes
  stale after the first refresh.
- **KeePassXC exists only in your session, while it's unlocked.** It locks
  with the screen (`LockDatabaseScreenLock`), isn't there before login, and
  isn't there on a host nobody has signed into. Anything that runs at boot, on
  a timer or headless must not depend on it.
- **Nix values end up in the world-readable store.** `vars` is for things that
  are private (topology, identifiers), never for credentials.

---

## 1. Delivering a sops value to a command

In order of preference:

1. **The program reads a file path.** Pass `config.sops.secrets.<name>.path`:
   `passwordFile`, opencode's `{file:…}`, `services.dictation.apiKeyFile`.
2. **The program accepts a `*_FILE` variable.** Export the *path* as a session
   variable, never the value: `DD_API_KEY_FILE`, `ALPHAVANTAGE_API_KEY_FILE`.
   A path in the environment leaks nothing.
3. **The program only reads `FOO_API_KEY`.** Load it for that one command:
   `withkey FOO_API_KEY -- cmd …`, or a wrapper that does the same (see `mods`
   in `home/profiles/framework13/default.nix`). New keys get added to
   `apiKeyFiles` there.
4. **The program wants a whole config file.** Render it with `sops.templates`
   at the exact path the program reads (`home/terminal/programs/forgejo.nix`).
   The rendered file is read-only, so the program's own login and logout
   commands stop working; edit the Nix attrset instead.

## 2. Using KeePassXC as the keyring

KeePassXC serves `org.freedesktop.secrets` (gnome-keyring stays off). Any
libsecret or go-keyring client can store items in the groups the database
exposes.

- **Exposing a group** is a per-database setting stored in the `.kdbx`:
  Database Settings → Secret Service Integration. Nothing is exposed until you
  pick a group; until then clients find the service but no collection.
- **The exposed group is the security boundary.** Reads don't prompt
  (`ConfirmAccessItem = false`): KeePassXC 2.7 remembers "Allow All & Future"
  only for the process that asked, so every new `hey`/`codex`/`podman` run
  prompted again. Anything on your session bus can therefore read the exposed
  group while the database is unlocked, so it must hold app tokens only.
  Expose a dedicated group, never the root, and keep website passwords out of it.
- **Keep apps off the plaintext fallback.** Many clients quietly fall back to
  a plaintext file when the keyring probe fails, and some ("auto" settings)
  switch backends silently when a keyring appears. Pin each one explicitly:
  - hey: `xdg.configFile."hey-cli/credential-storage"`
  - Codex: `cli_auth_credentials_store` / `mcp_oauth_credentials_store = "keyring"`
  - podman: `credential-helpers = ["secretservice"]` in a `registries.conf.d`
    drop-in, with no `containers-auth.json` entry to fall back to
- **Switching an app over doesn't move its existing credential.** Log out and
  back in once, then check the old plaintext file is gone.

---

## 3. Anti-patterns

| Reflex | Why it's wrong | Do instead |
|---|---|---|
| `set -gx FOO_API_KEY (cat …)` in fish init | Every child process, every coding agent included, inherits every key | `*_FILE` path or `withkey` |
| Copying an OAuth login (access + refresh token) into sops | Goes stale on the first refresh; HEY also revokes a refresh token two installs present | KeePassXC Secret Service, signed in per host |
| Moving a boot or timer secret to KeePassXC "to keep everything in one place" | It's locked or not running when the unit fires | sops |
| Reading a secret into a shell variable to pass it on | The value lands in the transcript, `ps` or shell history | Pass the path; let the program open it |
| Putting a token in `vars` because it is "only semi-secret" | `vars` ends up in the world-readable nix store | sops |
| Declaring a sops key before it exists in the private repo | sops-nix fails activation on a missing key | Add the value, commit, `nix flake update secrets`, then declare |
