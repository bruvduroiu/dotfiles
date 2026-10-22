# zj-edit: yazi's `edit` opener. Outside zellij it is plain hx. Inside a
# session it sends `:open <files>` to the Helix pane of the current tab, so
# the Alt+y yazi overlay behaves like an IDE file picker for the editor you
# already have open instead of starting a second hx.

[ "$#" -gt 0 ] || exit 0

if [ -z "${ZELLIJ:-}" ]; then
  exec hx "$@"
fi

# From the floating overlay: hide the layer so focus lands on the tiled pane
# underneath (zellij restores the previously focused tiled pane).
floating=$(zellij action are-floating-panes-visible 2>/dev/null || echo false)
if [ "$floating" = true ]; then
  zellij action hide-floating-panes
fi

# list-clients: "CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND..."; the command
# column is the rest of the line ("direnv exec . hx" for the workbench pane).
focused=$(zellij action list-clients | awk 'NR == 2 { for (i = 3; i <= NF; i++) printf "%s ", $i; print "" }')

case " $focused" in
  *" hx "* | *"/hx "*)
    # Esc first: Helix may be in insert mode. %q gives shellwords-style
    # escapes that Helix's command line understands.
    zellij action write 27
    zellij action write-chars ":open $(printf '%q ' "$@")"
    zellij action write 13
    ;;
  *)
    # No Helix in focus (agent pane, shell, tiled yazi): open one.
    zellij run --close-on-exit -- hx "$@"
    ;;
esac

if [ "$floating" = true ]; then
  # Bring the layer back (focus returns to yazi) and close it.
  zellij action show-floating-panes
  zellij action close-pane
fi
