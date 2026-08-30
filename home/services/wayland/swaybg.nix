{ config, pkgs, ... }:

# Wallpaper for the niri session (hyprpaper.nix stays alongside for the
# Hyprland hosts). Same trick as hyprpaper: the image follows
# config.stylix.image, which changes per NixOS specialisation —
# switch-to-configuration restarts this unit with the correct wallpaper.
{
  systemd.user.services.swaybg = {
    Unit = {
      Description = "Wallpaper (swaybg)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      # graphical-session.target can fire before niri finishes exporting
      # WAYLAND_DISPLAY into the user manager; the default 100ms restart
      # burst exhausted all 5 attempts inside that race window. Retry
      # calmly forever instead.
      StartLimitIntervalSec = 0;
    };
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -m fill -i ${builtins.toString config.stylix.image}";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
