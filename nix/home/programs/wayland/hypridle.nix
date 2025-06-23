{ pkgs, lib, config, inputs, ... }: let
  lock = "${pkgs.systemd}/bin/loginctl lock-session";

  timeout = 300;
in 
{ 
  services.hypridle = {
    enable = true;

    package = inputs.hypridle.packages.${pkgs.system}.hypridle;

    settings = {
      general = {
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        lock_cmd = "pgrep hyprlock || ${lib.getExe config.programs.hyprlock.package}";
      };

      listener = [
        {
          inherit timeout;

          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          on-timeout = lock;
        }
      ];
    };
  };
}
