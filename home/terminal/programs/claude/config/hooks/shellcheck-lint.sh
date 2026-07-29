# PostToolUse / Edit|Write: shellcheck freshly-written shell scripts.
#
# Advisory: findings come back as additionalContext so they get fixed in the
# same turn, but a warning never blocks the edit.

input=$(cat)
file=$(jq -r '.tool_response.filePath // .tool_input.file_path // empty' <<<"$input")

[ -n "$file" ] || exit 0
[ -f "$file" ] || exit 0

case "$file" in
*.sh | *.bash) ;;
*) exit 0 ;;
esac

output=$(shellcheck --format=gcc "$file" 2>&1) || true
[ -n "$output" ] || exit 0

jq -n --arg out "$output" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: ("shellcheck findings:\n" + $out)
  }
}'
