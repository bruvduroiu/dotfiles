{ config, lib, ... }:

{
  services.greetd = let
    hyprlandDesktop = "${config.programs.hyprland.package}/share/wayland-sessions/hyprland.desktop";
    session = {
      command = "${lib.getExe config.programs.uwsm.package} start -eD Hyprland ${hyprlandDesktop}";
      user = "bogdan";
    };
  in {
    enable = true;
    settings = {
      terminal.vt = 1;
      default_session = session;
      initial_session = session;
    };
  };
}
