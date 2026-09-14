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
in {
  home.packages = [ pkgs.kando pkgs.thunar ];

  # Accessible before any Steam Input custom layout has been configured.
  programs.noctalia.settings = {
    bar.default.thickness = lib.mkForce 42;
    bar.default.start = lib.mkBefore [ "deck-apps" ];
    widget.deck-apps = {
      type = "custom_button";
      glyph = "apps";
      label = "Apps";
      tooltip = "Open Deck Apps";
      actions.left = "exec ${pkgs.kando}/bin/kando --menu 'Deck Apps'";
    };
  };

  xdg.configFile."kando/config.json".text = builtins.toJSON {
    version = pkgs.kando.version;
    ignoreWriteProtectedConfigFiles = true;
    enableVersionCheck = false;
    showIntroductionDialog = false;
    enableAchievements = false;
    enableAchievementNotifications = false;
    enableTurboMode = true;
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

  # Niri owns startup and teardown. Do not register Kando's XDG autostart:
  # graphical-session.target is also used by Jovian's Gaming Mode.
  desktop.niri.extraBinds = ''
    Ctrl+Alt+F12 repeat=false hotkey-overlay-title="Deck app wheel" {
        spawn "${pkgs.kando}/bin/kando" "--menu" "Deck Apps";
    }
  '';
  desktop.niri.extraConfig = ''
    spawn-at-startup "steam" "-silent"
    spawn-at-startup "${pkgs.systemd}/bin/systemctl" "--user" "start" "deck-kando.service"

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

}
