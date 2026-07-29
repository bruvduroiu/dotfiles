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
  # stylix border colours at HM level (framework13 has stylix; fall back to white).
  hasStylix = config ? lib && config.lib ? stylix;
  c = lib.optionalAttrs hasStylix config.lib.stylix.colors;
  active   = if hasStylix then "rgba(${c.base05}cc)" else "rgba(ffffffcc)";
  inactive = if hasStylix then "rgba(${c.base04}44)" else "rgba(ffffff44)";

  prelude = ''
    -- host values injected from Nix (hyprland.nix) — everything else is
    -- hand-written Lua in hyprland.lua.
    local host = {
      active = "${active}",
      inactive = "${inactive}",
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
