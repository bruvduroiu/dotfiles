{ config, inputs, lib, pkgs, ... }:

let
  # Host-specific plugin modules declare these named widgets when available.
  pluginWidgets = names: builtins.filter
    (name: builtins.hasAttr name config.programs.noctalia.settings.widget)
    names;
  wallpaperFor = mode: file: pkgs.linkFarm "noctalia-wallpapers-${mode}" [
    { name = "taipei.png"; path = file; }
  ];
  island = id: members: {
    inherit id members;
    fill = "surface";
    padding = 10.0;
    radius = 15.0;
    opacity = 0.9;
    widget_spacing = 6;
  };
in

{
  imports = [
    inputs.noctalia.homeModules.default
    ../../editors/helix/noctalia.nix
    ../../terminal/programs/jj-noctalia.nix
    ../../terminal/programs/btop-noctalia.nix
  ];

  programs.noctalia = {
    enable = true;
    # 5.0.1 supports fixed output lists only. Resolve our "focused" selector
    # through its native compositor backend, without an external polling daemon.
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./noctalia-focused-notifications.patch ];
    });
    systemd.enable = true;
    # The upstream module runs `noctalia config validate` at build time.
    checkConfig = true;
    settings = {
      shell = {
        font_family = "Hack Nerd Font Mono";
        corner_radius_scale = 0.0;
        animation.enabled = false;
        popup_shadows = false;
        panel.shadow = false;
        launch_apps_as_systemd_services = true;
        setup_wizard_enabled = false;
        telemetry_enabled = false;
        clipboard_enabled = true;
        # Preserve Niri's native keyboard navigation in overview.
        niri_overview_type_to_launch_enabled = false;
      };

      theme = {
        source = "builtin";
        builtin = "Rosé Pine";
        mode = "dark";
        templates = {
          enable_builtin_templates = true;
          builtin_ids = [ "gtk3" "gtk4" "ghostty" "niri" ];
        };
      };

      bar.default = {
        position = "top";
        thickness = 26;
        margin_ends = 10;
        margin_edge = 5;
        padding = 0;
        widget_spacing = 6;
        radius = 0;
        concave_edge_corners = false;
        shadow = false;
        capsule = false;
        background_opacity = 0.0;
        capsule_thickness = 1.0;
        start = [ "group:time" ];
        center = [ "group:workspaces" ];
        end = [ "group:status" ];
        capsule_group = [
          (island "time" ([ "clock" "weather" ] ++ pluginWidgets [ "world-clock" "timer" ]))
          (island "workspaces" [ "workspaces" ])
          (island "status" ([ "volume" "battery" "network" ]
            ++ pluginWidgets [ "phone-connect" "syncthing" ]
            ++ [ "caffeine" "notifications" "privacy" "control-center" ]))
        ];
      };
      widget.workspaces = {
        style = "minimal";
        label_source = "name";
        max_label_chars = 8;
        hide_when_empty = true;
      };
      # A fixed city avoids locating the VPN exit instead of the laptop.
      location = { auto_locate = false; address = "Taipei, Taiwan"; };
      weather = { enabled = true; unit = "metric"; effects = false; };
      widget.weather = { show_condition = false; show_temperature = true; };
      control_center = { sidebar = "compact"; sidebar_section = "compact"; };
      # Alt keeps h/j/k/l available for ordinary text entry in search fields.
      keybinds = {
        left = [ "left" "alt+h" ];
        down = [ "down" "alt+j" ];
        up = [ "up" "alt+k" ];
        right = [ "right" "alt+l" ];
        tab_next = [ "tab" ];
        tab_previous = [ "shift+tab" "iso_left_tab" ];
        validate = [ "return" "kp_enter" ];
        cancel = [ "escape" ];
      };
      dock.enabled = false;
      desktop_widgets.enabled = false;
      # Flat Niri overview; 5.0.1 calls this section [backdrop].
      backdrop.enabled = false;

      wallpaper = {
        enabled = true;
        default.path = "${../../wallpapers/taipei-toner-4k-negative.png}";
        directory = "${../../wallpapers}";
        directory_dark = "${wallpaperFor "dark" ../../wallpapers/taipei-toner-4k-negative.png}";
        directory_light = "${wallpaperFor "light" ../../wallpapers/taipei-toner-4k-positive.png}";
        transition_duration = 0;
      };
      audio.enable_sounds = false;
      notification = {
        enable_daemon = true;
        monitors = [ "focused" ];
      };
      lockscreen = {
        enabled = true;
        lock_before_suspend = true;
        fingerprint = true;
        blurred_desktop = false;
      };
      # Also locks after a shell restart, once IPC is ready.
      hooks.started = [ "noctalia msg session lock" "noctalia msg wallpaper-next" ];
      # Mode-specific folders alone only affect the picker, not the active image.
      hooks.theme_mode_changed = "noctalia msg wallpaper-next";
      idle = {
        pre_action_fade_seconds = 0;
        behavior_order = [ "lock" "screen-off" "suspend" ];
        behavior = {
          lock = { enabled = true; timeout = 300; action = "lock"; };
          screen-off = { enabled = true; timeout = 330; action = "screen_off"; };
          suspend = { enabled = true; timeout = 1800; action = "lock_and_suspend"; };
        };
      };
    };
  };

  # Declare integrations once. Noctalia writes only its generated theme files;
  # its native apply hooks then find these imports already in place.
  gtk = {
    theme = { name = "adw-gtk3-dark"; package = pkgs.adw-gtk3; };
    gtk3.extraCss = ''@import url("noctalia.css");'';
    gtk4.theme = null;
    gtk4.extraCss = ''@import url("noctalia.css");'';
  };
  programs.ghostty.settings.theme = lib.mkForce "noctalia";

  # Native GTK template hooks need gsettings/dconf in the service environment.
  home.packages = [ pkgs.glib pkgs.dconf ];
  home.sessionVariables.TERMINAL = "ghostty";

  # Retry if graphical-session.target precedes Niri's environment import.
  systemd.user.services.noctalia = {
    Unit.StartLimitIntervalSec = 0;
    Service.RestartSec = 2;
  };
}
