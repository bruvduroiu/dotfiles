# PostToolUse / Edit|Write: parse-check .nix files immediately after writing.
#
# `nix-instantiate --parse` is pure syntax — no evaluation, no network, no
# NIX_PATH needed — so it is fast enough to run on every edit and catches the
# unbalanced-brace/missing-semicolon class of error at the moment it is
# introduced, instead of at the end of a 40-second nixos-rebuild.
#
# Exits 2 on failure: for PostToolUse that feeds stderr back to the model as a
# blocking error, which is what a broken .nix deserves.

input=$(cat)
file=$(jq -r '.tool_response.filePath // .tool_input.file_path // empty' <<<"$input")

[ -n "$file" ] || exit 0
[ -f "$file" ] || exit 0
[ "${file##*.}" = "nix" ] || exit 0

if ! output=$(nix-instantiate --parse "$file" 2>&1 >/dev/null); then
  printf 'nix parse error in %s:\n%s\n' "$file" "$output" >&2
  exit 2
fi

exit 0
