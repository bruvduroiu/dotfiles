{ config, lib, pkgs, ... }:

let
  command = name: icon: angle: argv: {
    inherit name icon angle;
    iconTheme = "material-symbols-rounded";
    type = "command";
    data = {
      command = lib.escapeShellArgs argv;
      detached = true;
      isolated = false;
      # Restore focus before executing workspace and overview actions.
      delayed = true;
    };
  };

  # Steam Input Desktop Layout: Valve's desktop_neptune.vdf plus an action
  # layer held on the L5 grip that sends Super chords for the shared Niri
  # binds (see CONTROLLER.md for the table). Steam lists any *.vdf found in
  # controller_base/templates under "Templates" in its layout picker; the file
  # name only has to be unique there.
  layoutFile = ./controller_neptune_niri_desktop.vdf;
  layoutTarget = "${config.home.homeDirectory}/.local/share/Steam/controller_base/templates/controller_neptune_niri_desktop.vdf";

  # Steam's own on-screen keyboard is an override-redirect X11 surface: Niri
  # never lists it, cannot place it, and it lands on top of whatever field is
  # being filled. wvkbd is a layer-shell keyboard that requests an exclusive
  # zone, so the focused window shrinks above it instead of being covered,
  # and it types through the virtual-keyboard protocol into any Wayland
  # client. SIGRTMIN toggles it; it starts hidden.
  wvkbdToggle = [ "${pkgs.systemd}/bin/systemctl" "--user" "kill" "--signal=SIGRTMIN" "deck-wvkbd.service" ];
in {
  home.packages = [ pkgs.kando pkgs.thunar pkgs.wvkbd ];

  # Accessible before any Steam Input custom layout has been configured.
  programs.noctalia.settings = {
    bar.default.thickness = lib.mkForce 42;
    bar.default.start = lib.mkBefore [ "deck-apps" "deck-keyboard" ];
    widget.deck-apps = {
      type = "custom_button";
      glyph = "apps";
      label = "Apps";
      tooltip = "Open Deck Apps";
      actions.left = "exec ${pkgs.kando}/bin/kando --menu 'Deck Apps'";
    };
    widget.deck-keyboard = {
      type = "custom_button";
      glyph = "keyboard";
      label = "Keyboard";
      tooltip = "Toggle on-screen keyboard";
      actions.left = "exec ${lib.escapeShellArgs wvkbdToggle}";
    };
  };

  xdg.configFile."kando/config.json".text = builtins.toJSON {
    version = pkgs.kando.version;
    ignoreWriteProtectedConfigFiles = true;
    enableVersionCheck = false;
    showIntroductionDialog = false;
    enableAchievements = false;
    enableAchievementNotifications = false;
    # Turbo Mode selects on modifier release. The wheel now opens from a tap
    # (Super+A or the bar button), so there is no held modifier to release;
    # selection is point-and-click with R2, B cancels.
    enableTurboMode = false;
    enableGamepad = false; # Steam Input supplies pointer events; avoid double input.
    keepInputFocus = false;
    enableSelectionWedges = true;
    zoomFactor = 1.2;
    centerDeadZone = 60;
    soundTheme = "none";
  };
  xdg.configFile."kando/menus.json".text = builtins.toJSON {
    version = pkgs.kando.version;
    collections = [ ];
    menus = [{
      shortcutID = "deck-apps";
      centered = true;
      anchored = true;
      hoverMode = false;
      root = {
        name = "Deck Apps";
        type = "submenu";
        icon = "apps";
        iconTheme = "material-symbols-rounded";
        children = [
          (command "Firefox" "public" 0 [ "firefox" ])
          (command "Steam" "sports_esports" 60 [ "steam" "steam://open/main" ])
          (command "Kodi" "movie" 120 [ "${pkgs.kodi}/bin/kodi" ])
          (command "Files" "folder" 180 [ "${pkgs.thunar}/bin/thunar" config.home.homeDirectory ])
          (command "Terminal" "terminal" 240 [ "ghostty" "+new-window" ])
          {
            name = "Desktop controls";
            type = "submenu";
            icon = "tune";
            iconTheme = "material-symbols-rounded";
            angle = 300;
            children = [
              (command "Overview" "window" 0 [ "niri" "msg" "action" "toggle-overview" ])
              (command "Settings" "settings" 60 [ "noctalia" "msg" "settings-toggle" ])
              (command "Audio" "volume_up" 120 [ "noctalia" "msg" "panel-open" "control-center" "audio" ])
              (command "Network" "wifi" 180 [ "noctalia" "msg" "panel-open" "control-center" "network" ])
              # Jovian supplies steamosctl through the system package set.
              (command "Gaming Mode" "sports_esports" 240 [ "/run/current-system/sw/bin/steamosctl" "switch-to-game-mode" ])
              (command "All apps" "apps" 300 [ "noctalia" "msg" "panel-toggle" "launcher" ])
            ];
          }
        ];
      };
    }];
  };

  # Deck-only binds, inserted into the shared binds block for this host only.
  # Plain Super+letter chords: Steam Input sends them as two held sub-commands
  # (LEFT_WINDOWS + key), which is the most timing-tolerant shape it offers.
  # Every other chord the layout sends is an existing shared bind in niri.kdl.
  # Niri owns startup and teardown. Do not register Kando's XDG autostart:
  # graphical-session.target is also used by Jovian's Gaming Mode.
  desktop.niri.extraBinds = ''
    Mod+A repeat=false hotkey-overlay-title="Deck app wheel" {
        spawn "${pkgs.kando}/bin/kando" "--menu" "Deck Apps";
    }
    Mod+Ctrl+G hotkey-overlay-title="Return to Gaming Mode" {
        spawn "/run/current-system/sw/bin/steamosctl" "switch-to-game-mode";
    }
    Mod+Alt+K repeat=false hotkey-overlay-title="Toggle on-screen keyboard" {
        spawn ${lib.concatMapStringsSep " " (a: "\"${a}\"") wvkbdToggle};
    }
  '';
  desktop.niri.extraConfig = ''
    spawn-at-startup "steam" "-silent"
    spawn-at-startup "${pkgs.systemd}/bin/systemctl" "--user" "start" "deck-kando.service" "deck-wvkbd.service"

    // 1280x800 handheld: every tiled window opens as a maximized column, so
    // the focused app always fills the panel and the pointer can reach all
    // of it. Navigating the scrolling layout becomes previous/next column.
    // open-maximized only affects tiled columns; floating Steam dialogs keep
    // their own size (default-column-width would stretch those too).
    window-rule {
        open-maximized true
    }

    // The shared config floats Settings at 1080x920, taller than this panel.
    // Later rules win per property: tile it and let it maximize instead.
    window-rule {
        match app-id=r#"^dev\.noctalia\.Noctalia$"#
        open-floating false
    }

    window-rule {
        match title="^Kando Menu$"
        open-floating true
        focus-ring { off; }
        border { off; }
        shadow { off; }
        default-floating-position x=0 y=0
    }
  '';

  systemd.user.services.deck-kando = {
    Unit = {
      Description = "Steam Deck app wheel";
      PartOf = [ "niri.service" "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "NIRI_SOCKET";
    };
    Service = {
      ExecStart = "${pkgs.kando}/bin/kando --menu \"Deck Apps\"";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  systemd.user.services.deck-wvkbd = {
    Unit = {
      Description = "Steam Deck on-screen keyboard (wvkbd)";
      PartOf = [ "niri.service" "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      # Landscape height applies on the 1280x800 panel; colors are static
      # Rosé Pine (wvkbd has no runtime theme reload).
      ExecStart = lib.escapeShellArgs [
        "${pkgs.wvkbd}/bin/wvkbd-mobintl"
        "--hidden"
        "-L" "280"
        "-R" "6"
        "--fn" "Hack Nerd Font Mono 15"
        "--bg" "191724" "--fg" "26233a" "--fg-sp" "403d52"
        "--press" "524f67" "--press-sp" "6e6a86"
        "--swipe" "524f67" "--swipe-sp" "6e6a86"
        "--text" "e0def4" "--text-sp" "908caa"
      ];
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  # Steam owns controller_base; a client update may recreate it. Re-install
  # the template on every activation so the repository stays the source of
  # truth. Selecting it is a one-time GUI step: the per-account configset
  # file is Steam's, and it rewrites that file.
  home.activation.deckControllerLayout = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    templates="$(dirname ${lib.escapeShellArg layoutTarget})"
    if [ -d "$templates" ]; then
      run install -m 0644 ${layoutFile} ${lib.escapeShellArg layoutTarget}
    else
      echo "deck controller layout: $templates not found (Steam not bootstrapped yet); skipped"
    fi
  '';
}
