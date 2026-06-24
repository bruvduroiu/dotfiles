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
    ];

    exec-once = [
      # Finalize startup
      "uwsm finalize"
      # walker is NOT started here: home-manager's walker.service owns it.
      # Launching it from exec-once too races the unit for the GApplication
      # dbus name and crash-loops whichever loses.
      # No nm-applet / tray applets: waybar has no tray module; network is
      # handled via the network module (click -> nmtui).
      "uwsm app -- waybar"
      "uwsm app -- wl-paste --type text --watch cliphist store"
      "uwsm app -- wl-paste --type image --watch cliphist store"
      "hyprlock"
      "uwsm app -- mako"
      "fcitx5 -d --replace"

      # boot straight into the ws1 notes layout (rules give firefox 0.667 /
      # obsidian 0.333 columns); silent = no focus steal during startup
      "[workspace 1 silent] uwsm app -- firefox"
      "[workspace 1 silent] uwsm app -- obsidian -disable-gpu"
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
        enabled = false;
        range = 4;
        render_power = 3;
        color = "rgba(00000055)";
      };

      # https://wiki.hyprland.org/Configuring/Variables/#blur
      blur = {
        enabled = false;
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
      no_hardware_cursors = false;
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
      preserve_split = true;
      force_split = 2;
      # smart_split picks split direction from cursor position, overriding
      # force_split — mouse-dependent, so off for deterministic keyboard use
      smart_split = false;
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

      # window swallowing: GUI launched from terminal replaces it until closed
      enable_swallow = true;
      swallow_regex = "^(com.mitchellh.ghostty)$";
    };

    input = {
      # must match the fcitx input-method group (it can't push layouts to
      # wlroots compositors — both sides must agree)
      kb_layout = "us";

      follow_mouse = 1;
      sensitivity = 0;

      touchpad = {
        natural_scroll = true;
        disable_while_typing = true;
      };
    };

    group = {
      # auto_group OFF: Hyprland 0.55.0 has a bounds bug in CGroup::remove /
      # CGroup::destroy (out-of-range -> SIGABRT/SIGSEGV that kills the whole
      # compositor). Auto-grouping firefox+obsidian on ws1 meant a firefox
      # crash unmapped a grouped window and took hyprland down with it. Group
      # manually with $mod+G instead. Re-enable once upstream fixes the bounds.
      auto_group = false;

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
      # makes "workspace previous" a true back-and-forth toggle
      allow_workspace_cycles = true;
    };

    animations = {
      enabled = false;
    };
  };
}
