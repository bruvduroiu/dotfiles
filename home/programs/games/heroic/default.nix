# Heroic Games Launcher — the Epic/GOG/Amazon client, added here to run Rocket League.
#
# Why a launcher and not a package
#   Rocket League cannot be a nixpkgs derivation. Psyonix dropped the native Linux
#   build in March 2020 and delisted the game from Steam that September; it now
#   exists only as a free-to-play, Windows-only title on the Epic Games Store.
#   So the store path holds the *client*, and the game itself is runtime state that
#   Heroic downloads into ~/Games/Heroic (or wherever you point it — an SD card
#   works). Same split as ../openrct2, which packages the engine but leaves the
#   RCT2 game data to a first-launch prompt.
#
#   Epic has never shipped an Epic Games Launcher for Linux, so an Epic-owned copy
#   needs a third-party client regardless. Epic's own support page saying no such
#   software is needed on SteamOS is scoped to the *Steam*-owned copy ("You can do
#   the launch via Steam if you own it there") — Steam supplies Proton itself.
#   Heroic (which drives Legendary underneath) is what speaks Epic's API here.
#
# `heroic`, NOT `heroic-unwrapped`
#   These are two different packages and picking the wrong one breaks at runtime,
#   not at build time. `heroic` is `steam.buildRuntimeEnv` wrapping
#   `heroic-unwrapped` — i.e. the Steam FHS sandbox. That matters because Heroic's
#   whole job is executing foreign, dynamically-linked binaries: the Windows game,
#   and any Wine/Proton build it downloads itself. Outside an FHS environment those
#   fail with the usual misleading "No such file or directory" (the missing path is
#   /lib64/ld-linux-x86-64.so.2, not the binary) — exactly the trap in CLAUDE.md.
#   heroic-unwrapped launches fine and then cannot run a single game.
#
# Anti-cheat — supported, not merely tolerated
#   Psyonix shipped Easy Anti-Cheat on 2026-04-28 and explicitly enabled EAC's
#   Linux/Proton path; Epic's support pages name Steam Deck and Linux as supported
#   platforms. EAC is opt-out (there is a "Play without Easy Anti-Cheat" launch
#   option) but online matchmaking requires it on, which also means BakkesMod and
#   other mods are offline/LAN-only now. ProtonDB rates the game Platinum (0.88
#   over ~864 reports, trending Platinum), and GamingOnLinux's 2026-04-30 test of
#   the post-EAC build was made through Heroic specifically.
#
#   heroic-unwrapped also puts `umu-launcher` on Heroic's PATH on x86_64-linux
#   (see its makeWrapper call). umu is the Proton runtime shim that reproduces
#   Steam's environment for non-Steam launches, including the EAC bits. Nothing to
#   configure; it just has to be reachable, and nixpkgs handles that.
#
#   The EOS Overlay is NOT supported on Linux/Steam Deck per Epic's own EOS docs,
#   and will not load however it is toggled. It is cosmetic — unrelated to EAC —
#   so this is not a problem to chase.
#
# Proton
#   Heroic's own Rocket League wiki page says the game "should work just fine out
#   of the box with GE-Proton". Get that from Heroic's built-in Wine Manager tab
#   rather than adding pkgs.protonup-qt: Heroic downloads GE-Proton into
#   ~/.config/heroic/tools, and because this package IS the Steam FHS runtime (see
#   above), that downloaded build executes correctly — the one case where pulling a
#   prebuilt binary from the internet is fine on NixOS, since it never leaves the
#   sandbox. protonup-qt only becomes worth adding if you also want GE-Proton
#   registered for Steam itself.
#
# Adding it to Gaming Mode
#   heroic-unwrapped ships com.heroicgameslauncher.hgl.desktop (Exec=heroic) and the
#   FHS wrapper symlinks share/applications + share/icons through, so Desktop Mode
#   sees it without a hand-written xdg.desktopEntry.
#
#   When adding it via Steam's "Add a Non-Steam Game", point the shortcut at
#     /home/deck/.nix-profile/bin/heroic
#   and NOT at the /nix/store/<hash>-heroic/bin/heroic that the file browser will
#   land on. Steam bakes the absolute path into shortcuts.vdf, and a store path is
#   invalidated by the next rebuild that bumps Heroic — the shortcut then dies on
#   the following GC, from Gaming Mode, with no useful error. ~/.nix-profile/bin is
#   the stable indirection: this host runs Home Manager with useUserPackages = false
#   (see hosts/default.nix — the steamdeck system does not import
#   system/programs/home-manager.nix), so HM installs into the user profile there.
#
#   Heroic can also write the Steam shortcut itself ("Add to Steam" per game), which
#   avoids hand-picking a path.
{ pkgs, ... }:

{
  home.packages = [ pkgs.heroic ];
}
