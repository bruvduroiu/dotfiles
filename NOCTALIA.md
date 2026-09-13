# Noctalia desktop

Noctalia 5.0.1 replaces Waybar, Walker/Elephant, Mako, swaylock/hyprlock,
swayidle/hypridle, swaybg/hyprpaper, meeting guard, and `theme-switch`.
Their modules, launcher/locker/wallpaper flake inputs, Walker cache, and
Waybar-specific passwordless WireGuard polling rules are removed.
Hyprland remains a compositor for the portable profiles; Framework uses Niri.

`home/programs/wayland/noctalia.nix` is imported by the shared Wayland profile.
`noctalia-templates.nix` adds community templates to the Framework-derived
profiles, and `noctalia-stylix.nix` assigns color ownership on Framework.
The community-template source is a pinned non-flake input: no runtime downloads
or automatic edits to Home Manager configuration are needed.

## Minimal design

- Three native capsule islands: clock/weather, occupied workspaces, system controls.
  Transparent surrounding bar, 26px thickness, 5px top and 10px side margins.
  Niri disables the bar's full-width compositor blur so the gaps stay clear.
- No dock, desktop widgets, animations, weather effects, or shadows.
- Niri uses a flat Rosé Pine overview without workspace shadows; Noctalia's
  separate backdrop and overview type-to-launch are disabled. Shell blur samples
  the content behind surfaces (`xray false`); the window switcher enables blur,
  while the bar keeps its explicit blur exception. Settings floats at 1080×920.
- Framework adds six pinned plugins: Timer, Translator, World Clock, Obsidian,
  Phone Connect, and Syncthing. Timer/world clock sit in the time island;
  phone/sync indicators sit in the status island. Translator and Obsidian are
  available through launcher prefixes.
- Rosé Pine light/dark colors. Mod+F5 also selects the matching Taipei wallpaper.
  Each mode has a singleton Nix-store wallpaper directory; the native theme-change
  hook calls `wallpaper-next`. A wallpaper chosen manually lasts until the next
  mode change or shell restart.
- Location defaults to Taipei, Taiwan. IP location is off because a VPN exit
  gives misleading weather. Change Location in Settings when travelling.
- Native launcher, clipboard history, window switcher, notifications, lock and idle.
  Notification toasts use the keyboard-focused screen when a new toast arrives.
  The toast stack follows the next notification to that screen; history remains shared.
  Lock at 300s, monitors off at 330s, lock and suspend at 1800s.
  Startup/restart also locks; Noctalia-launched apps run in separate systemd units.
- Fingerprints use fprintd directly; PAM login uses passwords to avoid contention.
  On Framework this also makes TTY login password-only.

The custom WireGuard handshake/relay display, Niri column dots, Timewarrior
indicator, Fcitx indicator, Walker todos/bookmarks, and automatic meeting DND
are gone. Use manual DND before a call. Niri still excludes notification toasts
from screencasts. The VPN's existing fail-open routing behavior is unchanged;
Noctalia's network icon does not replace the removed handshake-health display.

## Keyboard reference

Mod is Super. Direct tab shortcuts use `panel-open`: pressing a different
shortcut navigates to that tab even when Control Center is already open.
The general Control Center shortcut toggles it. Niri's Mod+/ overlay lists the
new shortcuts. The Hyprland config has the same mnemonic panel shortcuts.

| Shortcut | Action |
| --- | --- |
| Mod+Space | Launcher |
| Mod+Ctrl+Space | Toggle Control Center |
| Mod+Ctrl+A / B / N | Audio / Bluetooth / Network |
| Mod+Ctrl+M / P / I | Media / Power / System monitor |
| Mod+Ctrl+T / W | Calendar / Weather |
| Mod+Ctrl+D | Notification history |
| Mod+Shift+D | Toggle DND |
| Mod+Ctrl+Shift+D | Invoke latest notification's action |
| Mod+Ctrl+Shift+Backspace | Dismiss visible toasts; preserve history |
| Mod+Ctrl+Shift+I | Toggle caffeine (inhibit idle) |
| Mod+Ctrl+Comma | Settings |
| Mod+Ctrl+F5 | Wallpaper picker |
| Mod+F5 | Toggle dark/light and matching wallpaper |
| Mod+Ctrl+Shift+Q | Session menu |
| Mod+Ctrl+V | Clipboard history |
| Mod+Ctrl+Period | Emoji search |
| Mod+W | Window switcher |
| Mod+Ctrl+Q | Lock |
| Mod+Shift+Escape | Lock and suspend (Niri) |

Inside shell panels and Settings:

- Arrows or Alt+h/j/k/l move within the focused pane. Left/right adjust sliders.
- Tab / Shift+Tab move between sidebar and content, rather than each control.
- Enter activates the focused control; Escape dismisses the current operation.
- Ordinary h/j/k/l remain usable for typing search terms and passwords.
- The window switcher has its own navigation: Tab/Shift+Tab cycle, arrows move
  through its grid, Enter focuses, Escape cancels.

## Daily use

Start with Mod+Space: type an application's name and press Enter. Mod+W opens
the visual window switcher when you want an existing window. Launcher-started
applications get their own systemd units, so restarting the shell preserves them.
Your Niri workspace, tiling, monitor, screenshot and recording bindings still work.
Framework brightness keys explicitly target the laptop panel (`eDP-1`), including
when an external monitor has focus. Untargeted Noctalia brightness commands use
the focused monitor and fail if that monitor has no brightness backend.

Mod+Ctrl+V opens clipboard history. Select an entry with the keyboard and activate
it, then paste into your application. Mod+Ctrl+Period starts the launcher's emoji
search. Clipboard history is owned by Noctalia now; old Walker history is not imported.

Use Mod+Ctrl+Space as the desktop dashboard. The compact sidebar leads to each
service; the direct shortcuts in the table skip straight to your destination.
Audio includes output/input devices and individual application streams. Media
shows MPRIS players. Network manages Wi-Fi connections, while Bluetooth handles
pairing and connected devices. Power exposes battery information and available
power profiles. System shows resource usage; Calendar shows a month view.
Calendar account synchronization is not configured by this migration.

Before presenting, Mod+Shift+D enables Do Not Disturb. Notifications still collect
in Mod+Ctrl+D; DND does not destroy history. Mod+Ctrl+Shift+D invokes the latest
notification's action, and Mod+Ctrl+Shift+Backspace clears visible toasts.
There is no automatic meeting detector anymore.

Use Mod+Ctrl+Shift+I for caffeine during a presentation or long read. The bar icon
shows it is enabled. Turn it off afterward so the normal idle policy resumes.
Media applications that inhibit idle also prevent the configured idle actions.
Mod+Ctrl+Q locks immediately; Mod+Ctrl+Shift+Q opens the session action menu.
The session menu opens without preselecting an action: navigate before Enter.

Mod+F5 switches light/dark and the matching Taipei image. Mod+Ctrl+F5 opens the
wallpaper picker. Wallpaper selection is mode-scoped, so the deliberately tiny
default selection contains one image per mode. Add images to the Nix-declared
folders if you want more choices. Mod+Ctrl+Comma opens Settings for experimentation.

The three bar islands remain useful mouse entry points, but the main controls are
also accessible through these shortcuts. Plugin indicators open their own panels.

## Plugins (Framework)

`home/programs/wayland/noctalia-plugins.nix` pins the official and community source
revisions and hashes, packages only the six selected directories, and declares
them as a read-only path source. Remote plugin sources and automatic updates are
disabled. Update the Nix pins to update these plugins; no flake-lock change is
needed. The shell's pinned API range is 3–30, which covers all six manifests.
The build runs plugin lint as well as the normal configuration validation.

| Plugin | Access | Configuration |
| --- | --- | --- |
| Timer | Hourglass in the time island | Icon only when idle, countdown while running. Click for duration/start/pause/reset. Completion sends a notification. |
| Translator | Mod+Space, `/tr <text>` | Google Translate, English by default. `/tr ro hello` selects Romanian for that query; Enter copies the result. Query text is sent to Google. |
| World Clock | Globe in the time island | First-run list: London (`Europe/London`), Bucharest (`Europe/Bucharest`), Taipei (`Asia/Taipei`), in that order. IANA zones handle daylight-saving changes. |
| Obsidian | Mod+Space, `/ob` | Keep vault; `/ob daily` opens today's note and `/ob capture <text>` appends a timestamped line. Daily notes use `5 - Main Notes/Daily/YYYY-MM-DD.md`. |
| Phone Connect | Phone in the status island | Existing KDE Connect pairing; icon-only battery display and no charging animation. Click for devices and actions. File picker and SSHFS dependencies are declared. |
| Syncthing | Sync indicator in the status island | Existing user daemon at `http://127.0.0.1:8384`, all folders, 30-second polling. Routine event notifications are disabled; status/errors remain in the widget/panel. |

The Obsidian plugin's Git controls are separate from synchronization: Keep still
syncs through Syncthing. Installing the plugin neither initializes a Git repo nor
runs commits, pulls, or pushes. The Syncthing plugin reads its API key at runtime
from Syncthing's local `config.xml`; no credential is embedded in Nix. Its `/st`
launcher provider searches monitored folders and **rescans** the selected folder.
Pause/resume controls alter the running daemon; Home Manager still owns the
declared device/folder configuration.

World Clock has no upstream declarative timezone setting. The package customizes
its first-run defaults; the plugin writes `zones.json` in
`~/.local/state/noctalia/plugins/data/noctalia/world_clock/`. Existing lists and
subsequent panel edits are preserved across rebuilds.

Panels can also be opened directly:

```sh
noctalia msg panel-toggle noctalia/timer:panel
noctalia msg panel-toggle noctalia/world_clock:panel
noctalia msg panel-toggle davemhammer/obsidian:manager
noctalia msg panel-toggle icefish/phone-connect:details
noctalia msg panel-toggle rylos/syncthing:panel
```

After activation, check `noctalia msg plugins list`, the globe's three cities,
and a short timer. Try `/tr ro hello`, open `/ob daily` when ready to create a
daily note, and check phone and Syncthing status before trying their actions.
Plugin and bar overrides in `settings.toml` can still override the Nix defaults;
reset only the relevant GUI overrides if a plugin or indicator is missing.

## App themes

Home Manager owns app selections/imports; Noctalia owns generated theme files.
Do not point generated output at an immutable Home Manager symlink.

| App | Integration / first use |
| --- | --- |
| GTK3/4, Ghostty, Niri | Built-in templates with declared imports. |
| Helix | Corrected upstream template; transparent background and mode-aware diagnostic colors. Reloads open editors after rendering with SIGUSR1. |
| bat | `noctalia` selected; cache rebuilt after rendering. |
| btop | `color_theme = "noctalia"`. Stylix's target is off: it rendered from the build-time `stylix.polarity`, so btop stayed dark in light mode. Hot-reloads in place via SIGUSR2 (btop's own Ctrl+R path). `theme_background = false` is restated here, since it came from Stylix's opacity half. |
| yazi | `noctalia` flavor for both modes, including syntax colors. |
| Claude Code | Generated in personal and work profile theme directories. Select Noctalia with `/theme`; restart once if newly added. |
| Codex | `tui.theme = "noctalia"`; start a new session to pick up syntax colors. |
| Discord | Midnight community CSS generated for Vencord/Vesktop. Requires a compatible client/mod and enabling the theme; stock Discord cannot load it. |
| fcitx5 | Classic UI theme selected on Framework; native D-Bus reload hook. |
| fzf | Community color options read through `FZF_DEFAULT_OPTS_FILE` on each invocation. Open a fresh login shell after activation. |
| jjui | `ui.theme = "noctalia"` reading a generated `themes/noctalia.toml`. Stylix's target is off: its static `ui.colors` is jjui's highest-priority layer and masked every other one. A running jjui recolors when the terminal reports the new polarity; otherwise reopen it. |
| LibreOffice | Community extension generated in writable state. Close LibreOffice, run `noctalia msg templates-apply`, reopen. Applying while it is open skips installation. |
| Obsidian | Enabled CSS snippet generated directly into the declared Keep and Blog vaults. |
| OpenCode | Custom theme selected in `tui.json`. |
| Telegram | Import `~/.config/telegram-desktop/themes/noctalia.tdesktop-theme` in Telegram; re-import after changing colors if it retained its imported copy. |
| Zathura | Includes generated `noctaliarc`; restart the viewer to refresh. |

Stylix stays a static fallback for unintegrated apps. NvChad uses static Rosé Pine;
its old reads of `~/.config/theme/nvim-*` are removed. Live recoloring is app-specific.

### Empty notification history after migration

A Mako process from the old session can survive configuration removal, including
one launched through D-Bus rather than `mako.service`. Check the actual owner:

```sh
busctl --user status org.freedesktop.Notifications
busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications \
  org.freedesktop.Notifications GetServerInformation
```

The server should report `noctalia`. If it reports Mako, stop the exact `UserUnit`
shown by the status command, then run `systemctl --user restart noctalia`.
The restart locks the screen. Removing the package alone does not stop a surviving
process. Old Mako history is not imported into Noctalia.

Test with `notify-send "Notification history test"`, then open Mod+Ctrl+D.
External application notifications are retained by default. Noctalia's internal
shell/plugin toasts, including `noctalia msg notification-show`, are toast-only
and intentionally do not appear in history.

The pinned 5.0.1 release only supports fixed monitor lists. A small Nix package
patch adds `notification.monitors = [ "focused" ]`, resolving the screen through
Noctalia's existing compositor backend (keyboard focus on Niri), with one usable
screen as fallback during startup or unplugging. This requires a local Noctalia
build rather than its unmodified binary-cache package. Remove the patch when
upstream provides equivalent active-screen routing.

To test, focus a window on each monitor in turn and run `notify-send "Focus test"`.
Only the active screen should show the toast. Repeat after unplugging the external
monitor; notifications should continue on the laptop display.

### Ghostty starts dark after switching to light

Stylix's Fish target is disabled: its `base16-rose-pine` startup function sends
OSC palette/background overrides that undo Noctalia's colors in each new shell.
Noctalia now owns terminal colors through the generated Ghostty theme.

After activating this change, open a new terminal in each mode. Existing terminals
may retain earlier OSC overrides even after a config reload. In an affected terminal,
return to the shell prompt and reset only its color overrides once:

```sh
printf '\033]104\007\033]110\007\033]111\007\033]112\007'
```

This restores that terminal's current Ghostty defaults without closing its processes.
It is a one-time transition step, not a startup script or theme-switch hook.
`ghostty +show-config` shows the file-derived colors; it cannot show per-terminal
OSC overrides. A light background there with a dark terminal is a useful clue.

### Helix light/dark troubleshooting

The pinned upstream Helix template used an invalid `"ui.background" = "none"`
and did not reload running editors. `home/editors/helix/noctalia.nix` corrects
the template, writes `themes/noctalia-helix.toml`, and signals only your Helix
processes after rendering. It also replaces fixed pale diagnostic colors and
container-background colors used as syntax foregrounds. The editor omits an explicit background so Ghostty supplies its transparent
default; status lines, selections, and popups retain their contrast surfaces.
Selections and picker preview highlights use a subdued surface shade rather than
the saturated accent-container color, avoiding large bright-red highlighted regions.

After activation, keep an editor open and toggle Mod+F5 in both directions.
Text, gutter, selection, status line, diagnostics and background should switch
together. `:theme` should report `noctalia-helix`; `:config-reload` is a manual
fallback. If a project has `.helix/config.toml` with its own theme, that local
choice overrides the global one. Check `:log-open` for fresh theme warnings.

## Build and test

The migration now lives in the main repository. Build it with:

```sh
nix build --no-link --print-out-paths --no-write-lock-file \
  path:/home/bogdan/development/dotfiles#nixosConfigurations.framework13.config.system.build.toplevel
```

The build validates Noctalia's declarative TOML and the Niri config, including a
rendered Niri theme in both modes and first login without the optional include.
It does not exercise the live Wayland session, weather HTTP
requests, fingerprint hardware, or app theme reloads.

After reviewing the changes, apply a temporary system test yourself (an agent
must ask before running this command):

```sh
sudo nixos-rebuild test --flake path:/home/bogdan/development/dotfiles#framework13
```

1. Start a fresh graphical login so obsolete processes and old shell environment
   variables are gone. Verify password and fingerprint unlock, then open a terminal.
2. Run `noctalia config validate` to check the merged live configuration and inspect
   `journalctl --user -u noctalia -b --no-pager` for hook/template errors.
3. Press Mod+F5 twice. Check both wallpapers, bar contrast, GTK, a fresh Ghostty,
   bat, and yazi. Run `noctalia msg wallpaper-get` and
   `noctalia msg wallpaper-get eDP-1`; repeat for your external connector.
4. Open Control Center with Mod+Ctrl+Space. Tab into its sidebar, use arrows or
   Alt+j/k, and Enter. Tab into content and adjust a volume slider with left/right.
   Test direct tab shortcuts while the panel is already open.
5. Open Weather with Mod+Ctrl+W; verify Taipei and a forecast. Settings → Location
   exposes resolution errors. Disconnect/reconnect the network and check recovery.
6. Run `noctalia msg templates-apply` with LibreOffice closed. Check logs and the
   apps in the table above. Newly generated files should be writable regular files;
   app configs such as `~/.config/bat/config` should remain HM-owned symlinks.
7. Launch an app from Noctalia, then run `systemctl --user restart noctalia`.
   Expect the screen to lock, the app to survive, and the matching wallpaper to return.
8. Test idle locking, media inhibition, caffeine on/off, lid suspend, and resume
   with an external monitor. Use Settings to shorten timeouts temporarily and
   reset those individual overrides afterward.
9. Test DND, notification history/action/dismiss shortcuts, clipboard, emoji,
   window switching, screenshots, recording, audio devices, and Bluetooth pairing.

Noctalia GUI settings persist in `~/.local/state/noctalia/settings.toml` and override
the Nix defaults in `~/.config/noctalia/config.toml`. If islands, keys, or wallpapers
ignore a rebuild, inspect the corresponding runtime override and reset that setting
in the GUI. Do not delete the whole state file just to test one change.

`test` leaves the boot default unchanged, but Home Manager files and runtime state
persist across reboot. No activation is performed by the build command above.

## References

- [Noctalia keyboard navigation](https://docs.noctalia.dev/noctalia/configuration/shell/#keybinds)
- [Control Center tab contexts](https://docs.noctalia.dev/noctalia/control-center/)
- [Pinned community templates](https://github.com/noctalia-dev/community-templates/tree/cdb77210cd9c4fa9ccc5673523b57d2a6b76e804)
- [Codex configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference)
