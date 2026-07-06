{ config, lib, pkgs, ... }:

let
  cfg = config.desktop.greetd;
  hyprlandDesktop = "${config.programs.hyprland.package}/share/wayland-sessions/hyprland.desktop";
  sessionCommand = "${lib.getExe config.programs.uwsm.package} start -eD Hyprland ${hyprlandDesktop}";
in {
  options.desktop.greetd = {
    user = lib.mkOption {
      type = lib.types.str;
      default = "bogdan";
      description = "User for greetd sessions";
    };

    autoLogin = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to auto-login on boot (skip greeter)";
    };

    greeterCommand = lib.mkOption {
      type = lib.types.str;
      default = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd '${sessionCommand}'";
      description = "Command to run for the greeter (when autoLogin is false)";
    };
  };

  config = {
    services.greetd = {
      enable = true;
      settings = {
        terminal.vt = 1;
        default_session = if cfg.autoLogin then {
          # Auto-login mode: both sessions are the same (direct login)
          command = sessionCommand;
          user = cfg.user;
        } else {
          # Manual login mode: show greeter
          command = cfg.greeterCommand;
          user = "greeter";
        };
        initial_session = lib.mkIf cfg.autoLogin {
          command = sessionCommand;
          user = cfg.user;
        };
      };
    };
  };
}
