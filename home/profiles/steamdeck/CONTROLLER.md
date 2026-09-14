# Steam Input desktop controls

The Steam Deck profile declares Kando 2.3.1's menu/configuration, a Niri-only
startup service, Thunar, and Steam's extest
Wayland input compatibility. Steam starts silently with Niri to supply Desktop
Layout mappings. Gaming Mode keeps its per-game layouts.

## One-time Steam Input layout setup

In Desktop Mode, open Steam Settings → Controller → Desktop Layout → Edit.
Start from a desktop layout with right trackpad mouse and R2 left click. Save
the result as a personal layout called **Niri + Kando Desktop**.

1. Create an action-set layer named **App wheel**.
2. In the base layout, assign L2 soft pull to **Hold Action Set Layer → App wheel**.
   Remove its old right-click binding and any full-pull command. Use L1 for
   right click instead. Avoid toggle or repeated activation on L2.
3. Add commands to that same L2 soft pull for **Left Ctrl**, **Left Alt**, and
   **F12**. They must be held for the duration of the pull, with turbo disabled.
   Set F12's Fire Start Delay to 0.1 seconds so the modifiers arrive first.
   Do not override L2 inside the App wheel layer: it must retain the base
   layer's hold/release behaviour.
4. In App wheel, set right trackpad to Mouse, with trackball disabled. Set
   right stick to Joystick Mouse. Start with moderate sensitivity and adjust
   on the Deck. Keep R2 as left click. Set B to Escape.
5. Test **Ctrl+Alt+F12** on a keyboard first. Then hold L2, point towards an
   entry with the pad or stick, and release L2 to select. B cancels. Opening
   with a quick tap also allows ordinary point-and-click selection with R2.

The opening shortcut is reserved in the Deck's Niri configuration. Kando's
Turbo Mode uses the held Ctrl/Alt state to select on release. The exact Steam
Input timing and modifier handoff require testing on the Deck; if release
selection does not work, use the tap-and-click path while diagnosing it.
Do not add a release-time mouse click: it could click the newly launched app.

Steam owns its live controller files. This repository does not overwrite
account-specific Steam userdata or claim a layout has already been installed.
After hardware verification, export the personal layout from Steam and retain
the actual exported VDF alongside this document for reproducible re-import.

## Menu

Clockwise from the top: Firefox, Steam, Kodi, Files (Thunar), Terminal (Ghostty),
Desktop controls. Controls contains Overview, Settings, Audio, Network,
Gaming Mode, and All apps (Noctalia). Menu positions and commands are declared
in `controller-desktop.nix`; editing Kando's GUI does not persist those changes.

The menu opens centred, with anchored submenus and enlarged directional targets.
Kando's direct gamepad reader is disabled because Steam Input supplies pointer
events. Noctalia and existing keyboard bindings remain available.

## Verify on the Deck after activation

- Native Firefox and Thunar accept trackpad motion, R2 clicks and keyboard
  input while Steam is running. Verify again after suspend/resume.
- Hold L2: one menu opens; no repeated opening, accidental right click, or
  stuck Ctrl/Alt after selection or cancellation. Check both pad and stick.
- Each of the six entries launches; submenu actions affect the previous
  desktop window after Kando closes.
- Gaming Mode returns through `steamosctl switch-to-game-mode`; the Kando
  service stops when Niri exits and is absent from the Gaming Mode session.
- Test handheld and docked menu placement. Upstream describes Niri support as
  having some flaws, so evaluation alone does not verify window placement.

Steam supplies the only on-screen keyboard. The Deck disables
Noctalia's lockscreen, startup lock, idle lock, and lock-before-suspend. Jovian's
automatic login enters Desktop Mode without a password prompt. SSH remains
key-authenticated; this does not assign a blank Unix account password.

## Access without a physical keyboard

Kando opens **Deck Apps** when Desktop Mode starts. To reopen it, click or tap
**Apps** at the left of the Noctalia bar. The Deck bar is 42 pixels tall to make
this control easier to hit. This button does not require a custom Steam
Input layout or opening Noctalia settings.

References: [Kando navigation](https://kando.menu/usage/),
[Niri integration](https://kando.menu/installation-on-linux/),
[configuration](https://kando.menu/config-files/).
