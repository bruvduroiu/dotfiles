# PreToolUse: keep decrypted secrets out of the conversation.
#
# `permissions.deny` in settings.json only constrains the Read tool — `cat`,
# `echo $TOKEN`, `grep -r . /run/secrets` and friends go through Bash and are
# not covered by it. Anything printed by a tool lands in the transcript, which
# is uploaded, cached and summarised, so a single `cat /run/secrets/foo` leaks
# the plaintext far more durably than reading it in a terminal would.
#
# Two tiers, same shape as secret-scan:
#   plaintext key material / runtime secrets -> deny
#   sops-encrypted stores, env dumps         -> ask (heuristic, your call)
#
# Bash matching strips quoted segments first, so searching the repo for a
# reference (`rg "/run/secrets" system/`) is allowed while reading the real
# file (`cat /run/secrets/foo`) is not. Env-var checks run on the raw command,
# since `echo "$FOO_TOKEN"` is quoted by construction.
#
# Shebang and `set -euo pipefail` are supplied by writeShellApplication.

input=$(cat)
tool=$(jq -r '.tool_name // empty' <<<"$input")

decide() {
  jq -n --arg decision "$1" --arg reason "$2" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: $decision,
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# Decrypted-at-runtime or on-disk key material. Reading any of these puts the
# plaintext in the transcript.
plaintext_re='(^|[^[:alnum:]_.+-])(/run/secrets(\.d)?(/|$)|/run/user/[0-9]+/secrets(/|$))'
# Anchored to shell-word/path boundaries so `jq '.env'` isn't mistaken for a file.
plaintext_re+='|(^|[[:space:]=/])\.env($|\.|[[:space:]])'
plaintext_re+='|/\.ssh/|/\.gnupg/|(^|/)id_(rsa|dsa|ecdsa|ed25519)($|[^.])'
plaintext_re+='|/\.aws/credentials|/\.config/sops/age/keys\.txt|(^|/)keys\.txt$'
plaintext_re+='|(^|/)\.(netrc|pgpass|npmrc|authinfo)($|\.)|/\.docker/config\.json'
# Leading [[:alnum:]_-] forces a real basename, so `jq '.key'` doesn't match.
plaintext_re+='|[[:alnum:]_-]\.(pem|p12|pfx|jks|kdbx|key|age)($|[^[:alnum:]])'

# Encrypted stores: safe to read in principle, but the private flake also
# carries network topology/identifiers that should stay out of context.
# shellcheck disable=SC2016  # regex literals, not shell expansions
encrypted_re='(^|[^[:alnum:]_.+-])(~|\$HOME|/home/[^/]+)/development/secrets(/|$)'
encrypted_re+='|(^|[^[:alnum:]_.+-])\.?/?secrets/'
encrypted_re+='|\.(enc|sops)\.(ya?ml|json|env)($|[^[:alnum:]])'

deny_msg="Refusing to read secret material. Whatever a tool prints lands in the transcript, which is uploaded, cached and summarised. Work from the declaration (the sops/nix file that defines the secret) or ask the user to check the value themselves."
ask_msg="This touches an encrypted secret store. Confirm only if the contents genuinely need to be in context."

case "$tool" in
Bash)
  cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
  [ -n "$cmd" ] || exit 0

  # Interpolating a secret-shaped variable into output is a leak regardless of
  # which file it came from. Checked before quote-stripping.
  if grep -Eq '\$\{?[A-Za-z_][A-Za-z0-9_]*(TOKEN|SECRET|PASSWORD|PASSWD|API_?KEY|PRIVATE_KEY|CREDENTIALS?)\b' <<<"$cmd"; then
    decide deny "Command interpolates a credential-shaped environment variable into its output. Reference the variable inside the program that needs it instead of printing it."
  fi

  # Bare environment dumps: usually harmless, occasionally a full credential
  # spill, so hand the call to the user.
  if grep -Eq '(^|[|;&[:space:]])(env|printenv|set)([[:space:]]*$|[[:space:]]*[|>])' <<<"$cmd" ||
    grep -Eq '(^|[|;&[:space:]])export[[:space:]]+-p([[:space:]]|$)' <<<"$cmd"; then
    decide ask "This dumps the whole environment, which may include tokens injected by direnv/sops. Prefer \`printenv <SPECIFIC_VAR>\` for a non-secret variable."
  fi

  # Metadata-only commands don't reveal contents, and "does this secret exist"
  # is a legitimate question. Every segment must be metadata, and command
  # substitution disqualifies the whole line (`ls "$(cat /run/secrets/x)"`).
  metadata_only=1
  case "$cmd" in
  *'$'* | *'`'*) metadata_only=0 ;;
  esac
  if [ "$metadata_only" -eq 1 ]; then
    while IFS= read -r seg; do
      seg=${seg#"${seg%%[![:space:]]*}"}
      case "${seg%%[[:space:]]*}" in
      ls | stat | file | test | '[' | realpath | dirname | basename | true | echo | '') ;;
      *) metadata_only=0 ;;
      esac
    done < <(tr '|;&' '\n' <<<"$cmd")
  fi
  if [ "$metadata_only" -eq 1 ]; then
    exit 0
  fi

  # Searching the repo *for* a secret path (`rg "/run/secrets" system/`) is
  # normal work; reading the file at that path is not. Distinguish them by
  # where the match sits: a search tool whose only match is inside quotes is
  # matching a pattern, not naming a file. Everything else — including
  # `python3 -c "open('/run/secrets/x')"` — is treated as a read.
  quoted_only() {
    case "${cmd%%[[:space:]]*}" in
    rg | grep | egrep | fgrep | ag | ack | fd | find | git) ;;
    *) return 1 ;;
    esac
    # sed drops '...' and "..." separately; commands from the tool are one line.
    ! grep -Eq -- "$1" <<<"$(sed -e "s/'[^']*'//g" -e 's/"[^"]*"//g' <<<"$cmd")"
  }

  if grep -Eq -- "$plaintext_re" <<<"$cmd" && ! quoted_only "$plaintext_re"; then
    decide deny "$deny_msg"
  fi
  if grep -Eq -- "$encrypted_re" <<<"$cmd" && ! quoted_only "$encrypted_re"; then
    decide ask "$ask_msg"
  fi
  ;;
*)
  # Read/Grep/Glob/Edit/Write/NotebookEdit all name their target by path.
  # Grep's `pattern` is deliberately not checked: searching the repo for the
  # string "/run/secrets" is normal work, and `path` covers the actual read.
  paths=$(jq -r '
    [ .tool_input.file_path?, .tool_input.notebook_path?, .tool_input.path?,
      .tool_input.glob?
    ] | map(select(. != null)) | join("\n")
  ' <<<"$input")
  [ -n "$paths" ] || exit 0

  if grep -Eq -- "$plaintext_re" <<<"$paths"; then
    decide deny "$deny_msg"
  fi
  if grep -Eq -- "$encrypted_re" <<<"$paths"; then
    decide ask "$ask_msg"
  fi
  ;;
esac

exit 0
