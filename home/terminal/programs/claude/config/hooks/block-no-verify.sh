# PreToolUse / Bash: refuse to let git skip its own hooks.
#
# `git commit --no-verify` (or -n) and `git push --no-verify` bypass pre-commit
# and pre-push hooks — the checks that keep secrets and broken evals out of
# history. Denying here means the model has to fix the failure instead of
# routing around it.
#
# Shebang and `set -euo pipefail` are supplied by writeShellApplication.

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
[ -n "$cmd" ] || exit 0

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# Only care about commit/push subcommands; `git -c foo=bar commit` counts too.
if ! grep -Eq '(^|[|;&[:space:]])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+(commit|push)([[:space:]]|$)' <<<"$cmd"; then
  exit 0
fi

if grep -Eq '(^|[[:space:]])--no-verify([[:space:]]|$)' <<<"$cmd"; then
  deny "git --no-verify skips pre-commit/pre-push hooks. Fix what the hook reports instead of bypassing it."
fi

# `-n` means --no-verify for commit but --dry-run for push, so scope it.
if grep -Eq '(^|[|;&[:space:]])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+commit([[:space:]]|$)' <<<"$cmd" &&
  grep -Eq '(^|[[:space:]])-[a-zA-Z]*n([a-zA-Z]*)?([[:space:]]|$)' <<<"$cmd"; then
  deny "git commit -n is --no-verify: it skips pre-commit hooks. Fix the failure instead of bypassing it."
fi

exit 0
