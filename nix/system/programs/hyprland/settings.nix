{ config, pkgs, lib, ... }:

{
  programs.hyprland.settings = {
    "$mod" = "SUPER";
    "$menu" = "walker";
    "$terminal" = "ghostty";
    env = [
      "XCURSOR_SIZE,${toString 16}"
      "HYPRCURSOR_SIZE,${toString 16}"
    ];

    exec-once = [
      # Finalize startup
      "uwsm finalize"
      "walker --gapplication-service"
      "fcitx5 -d -r"
      "nm-applet --indicator"
      "waybar"
      "wl-paste --type text --watch cliphist store"
      "wl-paste --type image --watch cliphist store"
      "hyprlock"
      "fcitx5 -d -r"
      "fcitx5-remote -r"
    ];

    general = {
      gaps_in = 5;
      gaps_out = 20;

      border_size = 2;

      "col.active_border" = "rgba(88888888)";
      "col.inactive_border" = "rgba(00000088)";

      # Set to true enable resizing windows by clicking and dragging on borders and gaps
      resize_on_border = false;

      # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
      allow_tearing = false;

    };

    decoration = {
      rounding = 0;
      rounding_power = 2;

      # Change transparency of focused and unfocused windows
      active_opacity = 1.0;
      inactive_opacity = 1.0;

      shadow = {
        enabled = true;
        range = 4;
        render_power = 3;
        color = "rgba(00000055)";
      };

      # https://wiki.hyprland.org/Configuring/Variables/#blur
      blur = {
        enabled = true;
        size = 3;
        passes = 1;

        vibrancy = 0.1696;
      };
    };

    dwindle = {
      pseudotile = true;
      preserve_split = true;
    };

    misc = {
      force_default_wallpaper = 0;
    };

    input = {
      kb_layout = "us";

      follow_mouse = 1;
      sensitivity = 0;

      touchpad.natural_scroll = true;
    };

    gestures = {
      workspace_swipe = false;
    };

    animations = {
      enabled = false;
    };
  };
}
