{ config, pkgs, lib, ... }:

let
  hasStylix = config ? lib && config.lib ? stylix;
  c = lib.optionalAttrs hasStylix config.lib.stylix.colors;
  active   = if hasStylix then "rgba(${c.base05}cc)" else "rgba(ffffffcc)";
  inactive = if hasStylix then "rgba(${c.base04}44)" else "rgba(ffffff44)";
in {
  programs.hyprland.settings = {
    "$mod" = "SUPER";
    "$menu" = "walker";
    "$terminal" = "uwsm app -- ghostty";
    "$fileManager" = "uwsm app -- yazi";
    "$browser" = "uwsm app -- firefox";
    "$webapp"  = "$browser --new-tab";
    env = [
      "HYPRCURSOR_THEME,rose-pine-hyprcursor"
      "HYPRCURSOR_SIZE,${toString 24}"
      "GRIMBLAST_NO_CURSOR,1"
    ];

    exec-once = [
      # Finalize startup
      "uwsm finalize"
      "walker --gapplication-service"
      "nm-applet --indicator"
      "waybar"
      "wl-paste --type text --watch cliphist store"
      "wl-paste --type image --watch cliphist store"
      "hyprlock"
      "mako"
      "fcitx5 -d --replace"
    ];

    general = {
      gaps_in = 1;
      gaps_out = 0;

      border_size = 1;

      "col.active_border" = active;
      "col.inactive_border" = inactive;

      # Set to true enable resizing windows by clicking and dragging on borders and gaps
      resize_on_border = false;

      # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
      allow_tearing = false;

      layout = "dwindle";

    };

    decoration = {
      rounding = 0;

      shadow = {
        enabled = true;
        range = 4;
        render_power = 3;
        color = "rgba(00000055)";
      };

      # https://wiki.hyprland.org/Configuring/Variables/#blur
      blur = {
        enabled = true;
        size = 6;
        passes = 1;
        ignore_opacity = true;
        new_optimizations = true;
        special = true;
        popups = true;

        vibrancy = 0.1696;
      };
    };

    cursor = {
      no_hardware_cursors = true;
      hide_on_key_press = true;
    };

    master = {
      mfact = 0.60;
      new_status = "slave";
      new_on_top = false;
      allow_small_split = true;
      orientation = "center";
      slave_count_for_center_master = 2;
      center_master_fallback = "left";
    };

    dwindle = {
      pseudotile = true;
      preserve_split = true;
      force_split = 2;
      smart_split = true;
    };

    scrolling = {
      column_width = 0.5;
      fullscreen_on_one_column = true;
      follow_focus = true;
      wrap_focus = true;
      explicit_column_widths = "0.333, 0.5, 0.667, 1.0";
    };

    gesture = [
      "3, left, dispatcher, layoutmsg, move +col"
      "3, right, dispatcher, layoutmsg, move -col"
    ];

    misc = {
      force_default_wallpaper = 0;
    };

    input = {
      kb_layout = "us";

      follow_mouse = 1;
      sensitivity = 0;

      touchpad = {
        natural_scroll = true;
        disable_while_typing = true;
      };
    };

    group = {
      auto_group = true;

      groupbar = {
        enabled = true;
        font_size = 10;
        height = 18;
        rounding = 0;
        render_titles = true;
        scrolling = true;

        "col.active" = active;
        "col.inactive" = inactive;
        "col.locked_active" = active;
        "col.locked_inactive" = inactive;
      };

      "col.border_active" = active;
      "col.border_inactive" = inactive;
      "col.border_locked_active" = active;
      "col.border_locked_inactive" = inactive;
    };

    binds = {
      window_direction_monitor_fallback = false;
    };

    animations = {
      enabled = false;
    };
  };
}
