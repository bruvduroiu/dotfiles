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
  root so the layout's `direnv exec .` sees the right `.envrc`.
- **Ctrl-anything for the multiplexer.** Every zellij key is on Alt. Helix
  keeps C-hjkl, C-p, C-f, C-o; fish keeps C-p, C-o, Alt+O, Alt+V, Alt+E.
- **Looking for the "press Ctrl+g" hint.** There is no locked-by-default. If
  an app needs an Alt key zellij owns, Alt+Shift+g locks (and unlocks).

## Entry points

| Where | Key / command | Does |
|---|---|---|
| fish | `zj` | picker: ● live, ○ dead, + project dirs under `~/development` (or `$ZJ_PROJECT_ROOTS`) |
| fish | `zj NAME` / `zj DIR` / `zj NAME:TAG` | attach, resurrect, or create |
| fish | `zj -l agent NAME` | create with another layout (`workbench` default, `agent`, `shell`) |
| picker | Ctrl-l | choose the layout before creating |
| niri | Mod+Shift+Return | ghostty window running the picker |
| yazi | `W` | workbench for the hovered directory in a new window |
| launcher | "Workbench" | same as Mod+Shift+Return |

From inside a session, `zj` always opens a new ghostty window (one window per
project, no nesting).

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
- `../yazi/default.nix` — `edit` opener = `zj-edit`, `W` = workbench
- `../../../programs/wayland/niri.kdl` — Mod+Shift+Return
