{ config, lib, pkgs, ... }:

# Hyprland config lives in ./hyprland.lua — a real Lua file, the native
# 0.55+ format. This module only wires it up: home-manager's lua backend
# (configType = "lua") writes ~/.config/hypr/hyprland.lua, with a tiny
# generated `host` prelude carrying the only values Nix knows better than
# Lua does (stylix border colours).
#
# The previous iteration encoded every hl.* call as `settings` attrsets
# (_args / _var / mkLuaInline) — most leaf values were raw-Lua escape
# hatches, so the attrset layer was pure ceremony. Hand-written Lua gets
# syntax highlighting, lua-language-server (see ./.luarc.json), and
# `hyprctl eval` REPL testing instead.
#
# Split: the NixOS module (system/programs/hyprland) keeps the UWSM session,
# portals and helper scripts and emits NO config; HM owns the lua file.

let
  # stylix colours at HM level (framework13 has stylix; fall back to greys).
  hasStylix = config ? lib && config.lib ? stylix;
  c = lib.optionalAttrs hasStylix config.lib.stylix.colors;
  pick = slot: fallback: if hasStylix then c.${slot} else fallback;

  # Window / group borders: foreground slots read as accents against whatever
  # is behind them, so base05/base04 are right here.
  active = "rgba(${pick "base05" "ffffff"}cc)";
  inactive = "rgba(${pick "base04" "ffffff"}44)";

  # Groupbar titles. Hyprland's default title colour is a hardcoded white,
  # which vanishes against a light wallpaper in light mode. Titles are drawn
  # straight onto the desktop (groupbar gradients stay off — no tab fill), so
  # they take the foreground slots: base16 keeps base03-05 on the readable
  # side of the wallpaper in both polarities, giving light text in dark mode
  # and dark text in light mode with no polarity branch.
  barText = "rgb(${pick "base05" "ffffff"})";
  barTextInactive = "rgb(${pick "base04" "aaaaaa"})";

  prelude = ''
    -- host values injected from Nix (hyprland.nix) — everything else is
    -- hand-written Lua in hyprland.lua.
    local host = {
      active = "${active}",
      inactive = "${inactive}",
      bar_text = "${barText}",
      bar_text_inactive = "${barTextInactive}",
    }
  '';
in {
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;
    configType = "lua";
    extraConfig = prelude + builtins.readFile ./hyprland.lua;
  };
}
