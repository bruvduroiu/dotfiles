# agent: pick which coding agent runs in this pane, and pick again when it
# exits (so the workbench's agent pane never dies, it just goes back to the
# menu). The list is whatever is on PATH, plus the resume/continue forms;
# anything typed that matches nothing is run verbatim, so `claude -p "..."`
# or `codex --model x` need no menu entry.

candidates() {
  for bin in claude claude-work codex opencode; do
    command -v "$bin" >/dev/null 2>&1 || continue
    case "$bin" in
      claude | claude-work) printf '%s\n%s --continue\n%s --resume\n' "$bin" "$bin" "$bin" ;;
      codex) printf 'codex\ncodex resume\n' ;;
      opencode) printf 'opencode\nopencode --continue\n' ;;
    esac
  done
}

# One-shot: `agent claude --continue` skips the menu entirely.
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

while :; do
  # --print-query: the last line is the selection when one matched, else the
  # raw query. Esc/Ctrl-C leave both empty, which ends the loop (and the pane).
  out=$(candidates | fzf \
    --prompt='agent> ' \
    --header="$(pwd)" \
    --header-first \
    --print-query \
    --no-multi \
    --height=100% \
    --layout=reverse) || true
  choice=$(printf '%s\n' "$out" | tail -n 1)
  [ -n "$choice" ] || exit 0

  printf '\033[2J\033[H'
  # Subshell + eval so a multi-word choice gets normal word splitting and the
  # loop survives a non-zero exit (Ctrl-C in claude, codex failing to auth...).
  (eval "$choice") || printf '\n[agent] exited with status %s\n' "$?"
done
