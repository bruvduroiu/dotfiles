# zj-edit: yazi's `edit` opener. Outside zellij it is plain hx. Inside a
# session it sends `:open <files>` to the session's Helix pane, on whichever
# tab it is, and jumps there, so the Alt+y yazi overlay behaves like an IDE
# file picker for the editor you already have instead of starting a second
# hx.
#
# A held Helix pane (exited, or waiting for Enter after a resurrect) is
# started first. With no Helix pane anywhere, a new one opens in the
# current tab.

[ "$#" -gt 0 ] || exit 0

if [ -z "${ZELLIJ:-}" ]; then
  exec hx "$@"
fi

# Running from the yazi overlay: $ZELLIJ_PANE_ID is yazi's own floating
# pane. (are-floating-panes-visible prints nothing in 0.45, so ask about
# this pane directly.)
overlay=
if zellij action list-panes -j -s | jq -e --arg id "${ZELLIJ_PANE_ID:-}" \
  '.[] | select((.is_plugin | not) and (.id | tostring) == $id) | .is_floating' >/dev/null; then
  overlay=$ZELLIJ_PANE_ID
fi

# "ID\tSTATE\tTAB" for the first Helix pane: run (live editor) or held (a
# suspended or exited command pane waiting for Enter).
helix=$(zellij action list-panes -j -a | jq -r '
  [ .[] | select((.is_plugin | not)
      and ((.terminal_command // "") | test("(^|[ /])hx( |$)"))) ]
  | (map(select((.exited | not) and (.is_held | not))) + map(select(.exited or .is_held)))
  | first // empty
  | "\(.id)\t\(if (.exited or .is_held) then "held" else "run" end)\t\(.tab_name)"')
IFS=$'\t' read -r pane state tab <<<"$helix" || true

held() {
  zellij action list-panes -j -s | jq -e --argjson id "$1" \
    '.[] | select((.is_plugin | not) and .id == $id) | (.exited or .is_held)' >/dev/null
}

case "$state" in
  run | held)
    if [ "$state" = held ]; then
      # Enter starts a held command pane in place: same tab, same cwd
      # (the project root), same `direnv exec . hx`. Then give Helix a
      # moment to take the terminal before typing into it.
      zellij action write -p "terminal_$pane" 13
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        held "$pane" || break
        sleep 0.1
      done
      sleep 0.5
    fi
    # From the CLI, focus-pane-id moves focus within a tab but does not
    # switch the client's tab; go-to-tab-name does.
    zellij action go-to-tab-name "$tab"
    zellij action focus-pane-id "terminal_$pane"
    # Esc first: Helix may be in insert mode. %q gives shellwords-style
    # escapes that Helix's command line understands.
    zellij action write -p "terminal_$pane" 27
    zellij action write-chars -p "terminal_$pane" ":open $(printf '%q ' "$@")"
    zellij action write -p "terminal_$pane" 13
    ;;
  *)
    if [ -n "$overlay" ]; then
      zellij action hide-floating-panes
    fi
    zellij run --name hx --close-on-exit -- hx "$@"
    ;;
esac

if [ -n "$overlay" ]; then
  zellij action close-pane -p "terminal_$overlay"
fi
