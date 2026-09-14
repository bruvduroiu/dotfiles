{ config, lib, pkgs, ... }:

let
  cfg = config.desktop.greetd;
  sessionCommand = cfg.sessionCommand;
in {
  options.desktop.greetd = {
    sessionCommand = lib.mkOption {
      type = lib.types.str;
      default = "${pkgs.niri}/bin/niri-session";
      description = ''
        Command greetd runs to start the Wayland session. Defaults to Niri;
        the Hyprland module overrides it for hosts using that compositor.
      '';
    };

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
