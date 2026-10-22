# zj: attach-or-create Zellij project sessions.
#
#   zj                   picker over live sessions, dead (resurrectable)
#                        sessions and project directories
#   zj NAME              attach NAME (a dead one is resurrected); if no such
#                        session, create one from the project dir NAME under
#                        $ZJ_PROJECT_ROOTS
#   zj DIR|FILE          session named after the directory, cwd there
#   zj NAME:TAG          second session on the same project ("dotfiles:review")
#   zj -l LAYOUT ...     layout for a NEW session (default: workbench)
#
# From inside a session, anything that needs a new client opens in a new
# ghostty window: one window per project, no nesting.

usage() {
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
}

layout=workbench
while getopts 'l:h' opt; do
  case "$opt" in
    l) layout=$OPTARG ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done
shift $((OPTIND - 1))
target=${1:-}

roots=${ZJ_PROJECT_ROOTS:-$HOME/development}
layouts_dir=${XDG_CONFIG_HOME:-$HOME/.config}/zellij/layouts

# "name [Created ...] (EXITED - attach to resurrect)" per line; nothing on
# stdout (and exit 1) when there are no sessions at all.
sessions() {
  zellij list-sessions --no-formatting 2>/dev/null || true
}

# live | dead | (empty)
session_state() {
  sessions | awk -v n="$1" '$1 == n { print (index($0, "EXITED") ? "dead" : "live"); exit }'
}

project_dirs() {
  local IFS=:
  for root in $roots; do
    for dir in "$root"/*/; do
      [ -d "$dir" ] && printf '%s\n' "${dir%/}"
    done
  done
}

choose_layout() {
  local chosen
  chosen=$(for f in "$layouts_dir"/*.kdl; do
    [ -e "$f" ] && basename "$f" .kdl
  done | fzf --prompt='layout> ' --height=40% --layout=reverse) || return 1
  [ -n "$chosen" ] && layout=$chosen
}

# Picker rows: "<glyph>\t<name>\t<path>". Session rows first; a project dir
# whose name already has a session is dropped (attach it, or type name:tag).
pick() {
  local out query key row
  out=$({
    sessions | awk '{ printf "%s\t%s\t\n", (index($0, "EXITED") ? "○" : "●"), $1 }'
    project_dirs | awk -F/ '{ printf "+\t%s\t%s\n", $NF, $0 }'
  } | awk -F'\t' '!seen[$2]++' | fzf \
    --delimiter='\t' --with-nth=1,2 --nth=2 \
    --prompt='zj> ' \
    --header='● live  ○ dead  + new   ·   ctrl-l: pick layout   ·   type name[:tag] to create' \
    --header-first \
    --expect=ctrl-l \
    --print-query \
    --layout=reverse) || true
  query=$(printf '%s\n' "$out" | sed -n '1p')
  key=$(printf '%s\n' "$out" | sed -n '2p')
  row=$(printf '%s\n' "$out" | sed -n '3p')

  if [ "$key" = ctrl-l ]; then
    choose_layout || return 1
  fi
  if [ -n "$row" ]; then
    local path
    path=$(printf '%s' "$row" | cut -f3)
    if [ -n "$path" ]; then
      target=$path
    else
      target=$(printf '%s' "$row" | cut -f2)
    fi
  else
    target=$query
  fi
  [ -n "$target" ]
}

if [ -z "$target" ]; then
  if [ ! -t 0 ]; then
    usage >&2
    exit 2
  fi
  pick || exit 0
fi

# name[:tag] — the tag rides along into the session name unchanged.
base=${target%%:*}
tag=
case "$target" in *:*) tag=${target#*:} ;; esac

# 1. An existing session wins, live or dead.
name=$target
if [ -z "$(session_state "$name")" ]; then
  # 2. Otherwise resolve a project directory.
  dir=
  if [ -d "$base" ]; then
    dir=$base
  elif [ -f "$base" ]; then
    dir=$(dirname "$base")
  else
    IFS=: read -r -a root_list <<<"$roots"
    for root in "${root_list[@]}"; do
      if [ -d "$root/$base" ]; then
        dir=$root/$base
        break
      fi
    done
  fi
  if [ -z "$dir" ]; then
    printf 'zj: no session or project directory named %s\n' "$base" >&2
    exit 1
  fi
  dir=$(realpath "$dir")
  name=$(basename "$dir")${tag:+:$tag}
fi

# Inside a session already: hand off to a fresh ghostty window.
if [ -n "${ZELLIJ:-}" ]; then
  if command -v ghostty >/dev/null 2>&1; then
    exec ghostty +new-window -e zj -l "$layout" "$name"
  fi
  printf 'zj: already inside zellij and ghostty is not on PATH\n' >&2
  exit 1
fi

case "$(session_state "$name")" in
  live | dead) exec zellij attach "$name" ;;
esac

cd "$dir" || exit 1
exec zellij --session "$name" --new-session-with-layout "$layout"
