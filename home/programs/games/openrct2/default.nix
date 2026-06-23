# Declarative OpenRCT2 Configuration for Steam Deck
#
# OpenRCT2 is an open-source re-implementation of RollerCoaster Tycoon 2.
# The original RCT2 game data is REQUIRED to play.
#
# This module provides:
# - The OpenRCT2 package (from nixpkgs-unstable, since the steamdeck host is
#   built with inputs.nixpkgs-unstable.lib.nixosSystem)
# - A desktop entry so Steam can discover it ("Add a Non-Steam Game")
# - A helper script with instructions for adding it to Gaming Mode
#
# RCT2 game data:
#   No build-time path is hardcoded. On first launch OpenRCT2 prompts for the
#   RCT2 install directory. This works whether RCT2 lives on the internal disk
#   or an SD card. The Steam install is typically at:
#     ~/.steam/steam/steamapps/common/RollerCoaster Tycoon 2 Triple Thrill Pack
#
#   To pin it at build time instead, override the package below:
#     openrct2 = pkgs.openrct2.override {
#       rct2Path = "/path/to/rct2";
#     };
#
{ config, pkgs, lib, ... }:

let
  openrct2 = pkgs.openrct2;

  # Steam integration helper
  addToSteamScript = pkgs.writeShellScriptBin "openrct2-add-to-steam" ''
    echo "============================================"
    echo "  Add OpenRCT2 to Steam Gaming Mode"
    echo "============================================"
    echo ""
    echo "To add OpenRCT2 to Steam:"
    echo ""
    echo "1. Switch to Desktop Mode"
    echo "2. Open Steam"
    echo "3. Games -> Add a Non-Steam Game"
    echo "4. Browse to: ${openrct2}/bin/openrct2"
    echo "5. Click 'Add Selected Programs'"
    echo ""
    echo "Or select 'OpenRCT2' from the list."
    echo ""
    echo "On first launch, point OpenRCT2 at your RCT2 data, e.g.:"
    echo "  ~/.steam/steam/steamapps/common/RollerCoaster Tycoon 2 Triple Thrill Pack"
    echo ""
    echo "The game will appear in Gaming Mode!"
  '';

in {
  home.packages = [
    openrct2
    addToSteamScript
  ];

  # Desktop entry for Steam discovery
  xdg.desktopEntries.openrct2 = {
    name = "OpenRCT2";
    genericName = "RollerCoaster Tycoon 2";
    comment = "Open source re-implementation of RollerCoaster Tycoon 2";
    exec = "${openrct2}/bin/openrct2";
    icon = "openrct2";
    categories = [ "Game" "Simulation" ];
    terminal = false;
    settings = {
      StartupWMClass = "openrct2";
      Keywords = "rct;rollercoaster;tycoon;game;gaming;";
    };
  };
}
