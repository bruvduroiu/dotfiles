{ config, lib, pkgs, ... }:

# Niri config lives in ./niri.kdl — hand-written KDL, the native format.
# This module only wires it up: it ships the file verbatim plus a small
# generated stylix.kdl include carrying the only values Nix knows better
# than KDL does (stylix border/tab colours). Same split as the Hyprland
# lua setup (hyprland.{nix,lua}), which stays alongside, dormant.
#
# `niri validate` runs inside the derivation, so a broken config can never
# reach a session. niri watches both files (includes too) and live-reloads
# on change — a theme-switch specialisation flip recolours borders without
# restarting the compositor.
#
# Split: the NixOS module (system/programs/niri) owns the session, portals
# and helper scripts and emits NO config; HM owns the KDL.

let
  # stylix colours at HM level (framework13 has stylix; fall back to greys).
  hasStylix = config ? lib && config.lib ? stylix;
  c = lib.optionalAttrs hasStylix config.lib.stylix.colors;
  pick = slot: fallback: if hasStylix then c.${slot} else fallback;

  # Window borders + tab indicator: foreground slots read as accents
  # against whatever is behind them, so base05/base04 are right here
  # (same reasoning as the Hyprland setup).
  active = "#${pick "base05" "ffffff"}cc";
  inactive = "#${pick "base04" "ffffff"}44";

  stylixFragment = ''
    // generated from stylix (niri.nix) — everything else is hand-written
    // KDL in niri.kdl. Included sections merge per-property, so this
    // fragment only touches colours.
    layout {
        border {
            active-color "${active}"
            inactive-color "${inactive}"
        }
        tab-indicator {
            active-color "${active}"
            inactive-color "${inactive}"
        }
    }
  '';

  # Validate the assembled config (main file + include) at build time.
  configDir = pkgs.runCommand "niri-config" {
    nativeBuildInputs = [ pkgs.niri ];
    stylixKdl = stylixFragment;
    passAsFile = [ "stylixKdl" ];
  } ''
    mkdir -p $out
    cp ${./niri.kdl} $out/config.kdl
    cp "$stylixKdlPath" $out/stylix.kdl
    niri validate -c $out/config.kdl
  '';
in {
  xdg.configFile."niri/config.kdl".source = "${configDir}/config.kdl";
  xdg.configFile."niri/stylix.kdl".source = "${configDir}/stylix.kdl";
}
