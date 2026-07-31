# Security

Don't be insecure (lmao)

## Never read or print secret values

Anything a tool prints becomes part of the transcript — uploaded, cached,
summarised into later context, and kept in `~/.claude/projects/`. A secret that
passes through a tool result is leaked, whether or not it is used afterwards.

Do not read, cat, grep, copy, base64, or otherwise print the contents of:

- `/run/secrets/**`, `/run/secrets.d/**`, `/run/user/*/secrets/**` — sops-nix
  decrypts secrets to these paths in plaintext at activation
- `.env`, `.env.*`, `.envrc`-exported credentials
- `~/.ssh/**` (private keys and `config`), `~/.gnupg/**`,
  `~/.config/sops/age/keys.txt`, `~/.aws/credentials`
- `~/.netrc`, `~/.pgpass`, `~/.npmrc`, `~/.docker/config.json`, `~/.authinfo`
- any `*.pem`, `*.key`, `*.age`, `*.p12`, `*.pfx`, `*.jks`, `*.kdbx`
- `~/development/secrets/**` (the private flake) — sops-encrypted, but it also
  carries network topology and identifiers that stay out of context

Equally: do not echo credential-shaped environment variables
(`echo "$FOO_TOKEN"`, `printenv API_KEY`), and do not dump the whole
environment (`env`, `printenv`, `export -p`) — direnv and sops inject tokens
into it.

The `secret-read-guard` hook enforces this, but it is a backstop, not the rule.
Do not attempt to route around it (base64, `dd`, a python one-liner, a
subshell); if it fires, the answer is that the value should not be in context.

### What to do instead

- Work from the **declaration**, not the value: the sops YAML key name, the
  `config.sops.secrets.<name>.path` attribute, the `.env.example` template.
- To check a secret *exists* or is readable, use metadata only:
  `test -r /run/secrets/foo && echo present`, `ls -l /run/secrets/`.
- When a command genuinely needs the secret, pass it by reference — let the
  program read the file or the env var itself — rather than interpolating it
  into a shell line whose output you will see.
- If the value itself is needed to make progress, say so and ask the user to
  check it; suggest they run it with the `!` prefix and report only what
  matters.

### Writing secrets

The same policy in the other direction is enforced by `secret-scan`: no key
material, age keys, or hardcoded credentials into the working tree. Secrets go
through sops with the YubiKey-backed recipient.
