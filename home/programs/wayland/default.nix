{ pkgs, lib, ... }:

{
  imports = [
    ./walker.nix
    ./waybar
    ./hyprlock.nix
    ./hypridle.nix
  ];

  home.packages = with pkgs; [
    # screenshot
    grim
    slurp

    wl-clipboard
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    XDG_SESSION_TYPE = "wayland";
  };

  systemd.user.targets.tray.Unit.Requires = lib.mkForce ["graphical-session.target"];

}
