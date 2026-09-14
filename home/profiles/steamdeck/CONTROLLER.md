# Steam Input desktop controls

Niri has no gamepad support of its own. On the Deck every controller press
reaches the desktop through Steam Input's Desktop Layout, which emits X11 fake
input; the `extest` shim (`programs.steam.extest`) turns that into a uinput
device (`extest fake device`) that libinput and Niri read like a keyboard and
mouse. That path was verified working on 2026-09-14: the 64-bit client loads
the shim, the kernel creates the device, and native Wayland windows receive it.
The `wrong ELF class: ELFCLASS32` journal lines come from Steam's 32-bit
helpers and are harmless.

What was broken was the mapping. Steam loaded its stock `desktop_neptune.vdf`,
which can only produce arrows, Enter, Escape, Space, Tab and mouse clicks.
No Niri chord was reachable, and windows opened at half width on a 1280×800
panel, so the focused column sat off-screen where the pointer could not reach.

## Layout: one app per screen

The Deck profile appends a catch-all Niri window rule with
`open-maximized true`, so every tiled window opens as a maximized column and
fills the panel. `open-maximized` touches tiled columns only; a
`default-column-width` rule would also stretch floating Steam dialogs, which
is why it is not used. Navigating the scrolling layout collapses to
"previous / next column" and "previous / next workspace". Noctalia's Settings
window is tiled rather than floated on the Deck: the shared 1080×920 float is
taller than the panel. Everything else in `home/programs/wayland/niri.kdl` is
untouched; the Framework and Phantom configurations do not see these rules.

## Steam Input layout: stock desktop + a held Niri layer

`controller_neptune_niri_desktop.vdf` is Valve's `desktop_neptune.vdf` with one
addition: an action layer named **Niri** that is active while the **L5** back
grip is held. The stock layout bound L5 to a bare Super key, which does nothing
on its own; everything else in the base layer is unchanged (right pad mouse,
R2/L2 clicks, A Enter, B Escape, X Steam keyboard, Y Space, D-pad arrows,
Steam-button chords).

While L5 is held:

| Input | Sends | Niri action |
| --- | --- | --- |
| D-pad left / right | Super+H / Super+L | Focus column left / right (wraps) |
| D-pad up / down | Super+K / Super+J | Focus workspace up / down |
| A | Super+Space | Noctalia launcher |
| B | Super+Q | Close window |
| X | Super+O | Overview |
| Y | Super+Alt+K | Toggle on-screen keyboard (wvkbd) |
| L1 / R1 | Super+Shift+H / L | Move column left / right |
| Start (≡) | Super+A | Deck app wheel (Kando) |
| Select (⧉) | Super+Ctrl+Space | Noctalia control center |
| L4 | Super+Ctrl+G | Return to Gaming Mode |
| R4 | Super+Escape | Previous workspace |
| R5 | Super+Shift+F | Fullscreen window |

Super+A, Super+Ctrl+G and Super+Alt+K are Deck-only binds declared in
`controller-desktop.nix`; every other chord is a shared binding from
`niri.kdl`. The layer never rebinds L5 itself, so release always drops it.
A raw capture of the extest device on 2026-09-14 showed every chord arriving
with its modifiers held (for example LEFTSHIFT+LEFTMETA+H), so Steam's
repeated-`binding` chord encoding is confirmed on hardware.

## On-screen keyboard

Steam's keyboard (X in the base layer) is an override-redirect X11 surface.
Niri never lists it, cannot apply rules to it, and it ends up covering the
field being typed into. It still works for Steam's own windows, but the
desktop keyboard is **wvkbd**: a Wayland layer-shell keyboard that requests
an exclusive zone, so the focused window shrinks above it rather than being
overlapped, and types through the virtual-keyboard protocol into any client.

`deck-wvkbd.service` starts it hidden with Niri (280px landscape height,
static Rosé Pine colours). Toggle it with L5+Y, with the **Keyboard** button
next to **Apps** in the bar, or by tapping the panel and using it as a touch
keyboard. The toggle is `systemctl --user kill --signal=SIGRTMIN
deck-wvkbd.service`; SIGUSR1 hides and SIGUSR2 shows if a script needs a
definite state.

### Installing the layout

Home Manager activation installs the file into Steam's template directory,
`~/.local/share/Steam/controller_base/templates/`, which is where Steam looks
for additional layouts and lists them under **Templates** in its picker (the
same mechanism RetroDECK uses). The copy is repeated on every activation, so a
Steam client update that prunes the directory is undone by the next rebuild.
If Steam has not been bootstrapped yet the step is skipped with a message.

Selecting it is a one-time Steam GUI step, because Steam owns the per-account
selection file and rewrites it:

1. Desktop Mode → Steam → Settings → Controller → **Desktop Layout** → Edit.
2. Open the layout picker, choose the **Templates** tab, select **Niri Desktop**.
3. Confirm. `~/.local/share/Steam/logs/controller_ui.txt` should then report
   the desktop config path as the template instead of
   `controller_base/desktop_neptune.vdf`.

Steam's action-layer ordinal is positional: Default = 1, the stock Gamepad set
= 2, the Niri layer = 3. `hold_layer 3 0 0` in the base L5 binding refers to
that ordinal, the same numbering the stock `CHANGE_PRESET 2 1 1` uses. Adding
another action set before the layer would renumber it.

### Regenerating the file

The VDF is a static asset; do not hand-edit Steam's live copy. To rebuild it
from a newer stock layout, copy `controller_base/desktop_neptune.vdf` off the
Deck and re-run the generator used on 2026-09-14 (it replaces the L5 binding,
adds the layer, three groups with `"layer" "1"`, and the layer preset). Keep
the derived file in this directory so the repository is the source of truth.

## Menu (Kando)

Clockwise from the top: Firefox, Steam, Kodi, Files (Thunar), Terminal (Ghostty),
Desktop controls. Controls contains Overview, Settings, Audio, Network,
Gaming Mode, and All apps (Noctalia). Menu positions and commands are declared
in `controller-desktop.nix`; editing Kando's GUI does not persist those changes.

Kando opens on **Super+A** (L5 + Start) or by tapping **Apps** at the left of
the 42px Noctalia bar. Point with the right pad or stick, select with R2,
cancel with B. Turbo Mode is off: the earlier design opened the wheel on a
timed Ctrl+Alt+F12 hold and selected on modifier release, which depended on
Steam Input's modifier hand-off timing and was never made to work.

## Verify on the Deck after activation

- `ls ~/.local/share/Steam/controller_base/templates/ | grep niri` shows the file;
  Steam's Templates tab lists **Niri Desktop**; select it once.
- Without L5: stock behaviour, nothing new. Hold L5 and press D-pad
  left/right: Firefox, Steam and Heroic swap places one at a time, each filling
  the panel. Release L5: D-pad is arrows again, no stuck Super.
- L5+A opens the launcher. L5+Y raises wvkbd along the bottom edge and the
  launcher shrinks above it; type with pad clicks or touch, L5+Y hides it.
  L5+B closes the focused window. L5+X shows the overview; pad-click a window.
- L5+Start opens the wheel; each of the six entries launches; R2 selects.
- L5+L4 returns to Gaming Mode; the Kando service is absent there.
- Retest after suspend/resume and after a Steam client update.

The Deck disables
Noctalia's lockscreen, startup lock, idle lock, and lock-before-suspend. Jovian's
automatic login enters Desktop Mode without a password prompt. SSH remains
key-authenticated; this does not assign a blank Unix account password.

## Steam menus and dialogs

Steam's menu bar, context menus and the friends-list menus are X11
override-redirect popups. xwayland-satellite 0.8.2 reports the pointer leaving
them right after they map, so they flicker shut and anything behind them
(Games → Add a Non-Steam Game) cannot be reached. The Deck pins 0.8.1 through
Niri's `xwayland-satellite { path }` option in `xwayland-satellite-pin.nix`;
Niri spawns that binary on demand, so a fresh session picks it up. If a menu
still misbehaves, `steam steam://AddNonSteamGame` opens the dialog directly.

Known follow-ups, not addressed here: Framework's five named workspaces still
appear on the Deck strip; Steam starts with `-pipewire` and its recording
feature raises a "Share Screen" portal dialog on sign-in; wvkbd colours do not
follow Mod+F5 (no runtime reload).

References: [Kando navigation](https://kando.menu/usage/),
[Niri integration](https://kando.menu/installation-on-linux/),
[Kando configuration](https://kando.menu/config-files/),
[RetroDECK layout install via templates](https://github.com/RetroDECK/RetroDECK/wiki/Controllers:-Steam-Deck),
[VDF action-layer syntax example](https://github.com/jsantorek/steamdeck-gw2-layout/blob/main/controller_neptune.vdf).
