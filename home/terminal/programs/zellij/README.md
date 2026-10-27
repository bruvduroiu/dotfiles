# Zellij

Per-project sessions with tabs and scrollback. A session outlives its
ghostty window: closing the window detaches, and after a reboot a session is
"dead" but resurrectable (attach, then Enter in each waiting pane).

## Entry points

Sessions are managed by [lazy-zellij](https://github.com/Logos-Flux/lazy-zellij)
(`pkgs/lazy-zellij.nix`, units in `default.nix`). New sessions start in the
current directory with `default_layout`, which is `workbench`.

| | |
|---|---|
| `lzj` | picker with preview: enter attach, ^n new, ^l layout, ^d kill, ^x forget dead, ^u/⎇u systemd autostart on/off |
| `lzj NAME [-l LAYOUT]`, `zj NAME` | attach-or-create in the current dir; `zj` alone = session `main` |
| `zj new/kill/rm/up/down NAME`, `zj ls` | imperative: detached create, kill, forget, autostart (`zellij@NAME`) |
| niri `Mod+Shift+Return`, launcher "Workbench" | `lzj` in a new ghostty window |
| yazi `W` | `lzj <dirname>` in the hovered directory |

Layouts: **workbench** has three full-screen tabs: the agent picker on
`main`, Helix on `hx` and jjui on `vcs` (`Alt 1/2/3`). **agent** is the agent picker alone. **shell** is one shell. Command
panes run through `direnv exec .`.

## Keys (Alt, niri-shaped, no prefix)

| | |
|---|---|
| `Alt h/j/k/l` | focus (h/l continue into the next tab) |
| `Alt Enter` / `Alt Shift Enter` / `Alt q` | new pane right / down, close |
| `Alt t` / `Alt Shift q` / `Alt Shift t` | new tab, close tab, rename tab |
| `Alt 1-9`, `Alt [ ]`, `Alt Esc` | go to tab, prev/next, last |
| `Alt f` / `Alt Shift f` / `Alt g` | floating layer, fullscreen, float/embed |
| `Alt y` / `Alt z` / `Alt Shift a` | yazi overlay (opens into Helix), session manager, agent pane |
| `Alt r` / `Alt m` / `Alt Shift r` | resize mode, move mode, next swap layout |
| `Alt w` / `Alt /` / `Alt Shift e` | scrollback, search, scrollback in `$EDITOR` |
| `Alt Shift d` / `Alt Shift g` | detach, lock (passes every key through) |

Before binding a new Alt key, check it against Helix and fish (the list is
in `config.kdl`'s header).

## Files

- `config.kdl`: keybinds and the `ansi` theme. The theme is ANSI-16 only,
  so it follows ghostty's light/dark switch.
- `zj-edit.sh`: yazi's `edit` opener. `agent.sh`: the agent chooser.
- `zellij-completions.fish`: session and layout names for `zellij`.
