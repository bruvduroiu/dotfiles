# PreToolUse / Edit|Write|MultiEdit: keep key material out of the working tree.
#
# Enforces the "no key material on disk" policy at the point of writing rather
# than at commit time — a private key written to a scratch file and deleted
# still hit the disk (and possibly a syncthing folder) in between.
#
# Hard patterns (unambiguous key material) → deny.
# Soft patterns (heuristic, false-positive prone) → ask, so the call is yours.
#
# Patterns are written as regexes that do not match their own source text, so
# editing this file does not trip the hook that lives in it.

input=$(cat)

# Write → .content, Edit → .new_string, MultiEdit → .edits[].new_string
content=$(jq -r '
  [ .tool_input.content?, .tool_input.new_string?, (.tool_input.edits[]?.new_string) ]
  | map(select(. != null)) | join("\n")
' <<<"$input")
[ -n "$content" ] || exit 0

file=$(jq -r '.tool_input.file_path // "(unknown)"' <<<"$input")

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

# --- hard: unambiguous key material -----------------------------------------
if grep -Eq -- '-----BEGIN ([A-Z]+ )*PRIVATE KEY-----' <<<"$content"; then
  decide deny "Refusing to write a PEM private key block into $file. Key material belongs in the YubiKey / sops-encrypted store, never in the working tree."
fi

if grep -Eq 'AGE-SECRET-KEY-1[0-9A-Z]{20,}' <<<"$content"; then
  decide deny "Refusing to write an age secret key into $file. Use sops with the YubiKey-backed recipient instead."
fi

if grep -Eq 'AKIA[0-9A-Z]{16}' <<<"$content"; then
  decide deny "Refusing to write what looks like an AWS access key ID into $file."
fi

# --- soft: heuristic, hand the decision to the user --------------------------
if grep -Eqi '(api[_-]?key|secret|token|passwd|password)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{20,}["'"'"']' <<<"$content"; then
  decide ask "$file contains something shaped like a hardcoded credential assignment. Confirm it is a placeholder, or route it through sops."
fi

exit 0
