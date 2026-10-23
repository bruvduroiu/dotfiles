# Zellij workbench

## The model

A **session** is a server process that outlives its terminal window. One
session per project, named after the repo directory (`dotfiles`,
`dotfiles:review` for a second one on the same tree). Closing the ghostty
window detaches; `zj dotfiles` reattaches. After a reboot the session is
"dead" but resurrectable: attaching rebuilds its tabs and panes with each
command waiting for Enter.

niri still owns windows. Zellij owns what happens *inside* one ghostty window
for one project: Helix beside the agent, jjui on the next tab, yazi as an
overlay that feeds files into the Helix you already have open.

```
┌ main ─ vcs ────────────────────────┐
│ hx                  │ agent        │   Alt+y  yazi overlay → :open in hx
│ 60%                 │ (picker)     │   Alt+2  jjui
│                     │              │   Alt+z  session manager
└────────────────────────────────────┘
```

## Old reflexes that no longer apply

- **Mod+Y / `y` for a second editor.** Inside a session press Alt+y: yazi
  floats over the tab and Enter on a file lands in the running Helix pane.
  Pressing it from the agent pane opens a new hx pane instead, because yazi
  writes to whatever tiled pane is focused.
- **Opening another ghostty for the agent.** The agent pane is the picker:
  `claude`, `claude-work`, `--continue`, `--resume`, `codex`, `opencode`, or
  type any command. When the agent exits, the picker returns. Alt+Shift+a
  adds a second agent pane.
- **`zellij -s name`.** Use `zj`: it checks live and dead sessions first, so
  you never get "session already exists", and it puts the cwd at the project
  root so the layout's `direnv exec .` sees the right `.envrc`. Reach for
  raw `zellij` only to build something `zj` does not guess (below).
- **Ctrl-anything for the multiplexer.** Every zellij key is on Alt. Helix
  keeps C-hjkl, C-p, C-f, C-o; fish keeps C-p, C-o, Alt+O, Alt+V, Alt+E.
- **Looking for the "press Ctrl+g" hint.** There is no locked-by-default. If
  an app needs an Alt key zellij owns, Alt+Shift+g locks (and unlocks).
- **Helix keys in scroll mode.** Scroll mode is zellij's own viewer: j/k,
  d/u, PageUp/Down, `/` search, no selections. For Helix over the
  scrollback press Alt+Shift+e (or `e` inside scroll mode): the buffer opens
  in a real hx pane, `:q` returns.

## Entry points

| Where | Key / command | Does |
|---|---|---|
| fish | `zj` | picker: ● live, ○ dead, + project dirs under `~/development` (or `$ZJ_PROJECT_ROOTS`) |
| fish | `zj NAME` / `zj DIR` / `zj NAME:TAG` | attach, resurrect, or create |
| fish | `zj -l agent NAME` | create with another layout (`workbench` default, `agent`, `shell`) |
| fish | Tab | completes `zj` targets (sessions, projects, directories) and `-l` layouts; for `zellij` adds session names to `attach`/`kill-session`/`delete-session`/`-s` and layout names to `-l`/`-n`/`new-tab -l` |
| picker | Ctrl-l | choose the layout before creating |
| niri | Mod+Shift+Return | ghostty window running the picker |
| yazi | `W` | workbench for the hovered directory in a new window |
| launcher | "Workbench" | same as Mod+Shift+Return |

From inside a session, `zj` always opens a new ghostty window (one window per
project, no nesting).

## Sessions by hand

A session is three separable things: a **name** (`-s`), a **cwd** (inherited
from the shell that starts it, or set in the layout) and a **layout** (a name
from `layouts/`, a file, or raw KDL). Persistence is not a fourth thing to
add: every session is serialised to disk, so it survives a reboot as a dead
session from the moment it exists, and `zj NAME` finds it from then on, live
or dead, because `zj` checks sessions before directories.

Two things to read carefully. `-l LAYOUT` and `--layout-string KDL` mean
"append these tabs to the session `-s` names" when that session exists;
only `-n LAYOUT` always starts a new session. `-n` takes a layout name or a
file, never a string, and the file name must end in `.kdl`: anything else is
taken for a layout name and zellij silently falls back to its default
layout. In the KDL itself every node needs a newline or `;` after it, so
`{ pane; }` on one line parses and `{ pane }` does not.

Worked example: from `~`, a session on `~/development/dotfiles` named
`steamdeck`, jjui beside claude.

**One shot, nothing saved.** The top-level `cwd` cascades to every tab and
pane; `psub -s .kdl` turns the string into the file `-n` wants:

```fish
zellij -s steamdeck -n (echo '
layout {
    cwd "/home/bogdan/development/dotfiles"
    default_tab_template {
        children
        pane size=1 borderless=true {
            plugin location="compact-bar"
        }
    }
    tab name="vcs" {
        pane split_direction="vertical" {
            pane name="jjui" command="direnv" {
                args "exec" "." "jjui"
            }
            pane name="claude" command="direnv" {
                args "exec" "." "claude"
            }
        }
    }
}' | psub -s .kdl)
```

`command=` panes exec the binary directly, with no shell and no direnv hook,
which is why the layouts route through `direnv exec .`. Drop it for a
directory without an `.envrc`.

**Build it live, then capture.** Start with one shell pane and add to it,
from the keyboard (Alt+Return, type the command) or from any other terminal:

```fish
cd ~/development/dotfiles && zellij -s steamdeck          # default "shell" layout
zellij -s steamdeck run --cwd ~/development/dotfiles -- jjui
zellij -s steamdeck run -d right --cwd ~/development/dotfiles -- claude
zellij -s steamdeck -l agent                              # a stored layout, appended as tabs
zellij -s steamdeck action new-tab -l agent               # same, one tab
zellij -s steamdeck action dump-layout > vcs.kdl          # keep a sketch of it
```

`dump-layout` records what is running right now: binaries as resolved store
paths, `direnv exec` already replaced by its target, swap-layout tables
appended. Treat it as a sketch to rewrite into a clean layout, not a file to
ship.

**Make it a layout.** Save the `layout { … }` body from the one-shot, minus
the `cwd` line, as `layouts/vcs.kdl`, register `vcs = ./layouts/vcs.kdl;` in
`default.nix`, rebuild, then:

```fish
zj -l vcs dotfiles:steamdeck                  # zj names from the directory: "dotfiles:steamdeck"
cd ~/development/dotfiles && zellij -s steamdeck -n vcs   # the bare name
```

**Living with sessions**

| Command | Does |
|---|---|
| `zellij ls` | `●` live, `(EXITED)` dead |
| `zellij attach NAME` | live or dead; a dead session's panes wait for Enter before running |
| `zellij attach -f NAME` | dead: run every pane's command immediately |
| `zellij attach -c NAME` | attach, or create an empty session if missing |
| `zellij kill-session NAME` | stop it, keep it resurrectable |
| `zellij delete-session NAME` | forget it |
| Alt+z | the same list as a picker, inside a session |
| Alt+Shift+d | detach; closing the ghostty window does the same |

## Keys (all Alt, niri-shaped)

| Key | Action | niri twin |
|---|---|---|
| Alt+h/j/k/l | focus pane (h/l continue into the next tab at the edge) | Mod+H/J/K/L |
| Alt+Return / Alt+Shift+Return | new pane / split down | Mod+Return |
| Alt+q / Alt+Shift+q | close pane / close tab | Mod+Q |
| Alt+t, Alt+1..9, Alt+[ Alt+], Alt+Esc | new tab, go to tab, prev/next, last | Mod+1..9, Mod+[ ], Mod+Esc |
| Alt+{ / Alt+} | move tab left/right | |
| Alt+Shift+t / Alt+Shift+p | rename tab / pane | |
| Alt+f / Alt+Shift+f / Alt+g | show-hide floating layer / fullscreen / float-embed this pane | Mod+F, Mod+Shift+F, Mod+G |
| Alt+y / Alt+z / Alt+Shift+a | yazi overlay / session manager / another agent pane | Mod+Y |
| Alt+r → hjkl, =, - | resize mode (Esc/Enter leaves) | Mod+R |
| Alt+m → hjkl | move mode | Mod+Shift+hjkl |
| Alt+Shift+r | next swap layout | Mod+R |
| Alt+w, Alt+PageUp / Alt+/ / Alt+Shift+e | scroll mode / search / scrollback in hx | |
| Alt+Shift+d / Alt+Shift+g | detach / lock-unlock | |

Alt letters left free because Helix 25.07 or fish bind them: a b c d e i n
o p s u v x and the punctuation `. , ; : - _ ( ) \``.

## Theme and notifications

The theme is ANSI-16 palette indices, so ghostty's Mod+F5 light/dark switch
restyles zellij immediately. A BEL from any pane (claude-code's
`terminal_bell` channel) is forwarded to ghostty, so the urgent-window path
(Mod+D) works unchanged; OSC 9/99 desktop notifications from a pane are
downgraded to the same BEL.

## Files

- `config.kdl` — keybinds, theme, options (appended via `extraConfig`)
- `layouts/{workbench,agent,shell}.kdl`
- `zj.sh`, `agent.sh`, `zj-edit.sh` — built into PATH by `default.nix`
- `zj.fish` — fish completions for `zj` (autoloaded from `~/.config/fish/completions`)
- `zellij-completions.fish` — session and layout names for `zellij`, loaded
  from `conf.d` so it stacks on the package's own completion file
- `../yazi/default.nix` — `edit` opener = `zj-edit`, `W` = workbench
- `../../../programs/wayland/niri.kdl` — Mod+Shift+Return
