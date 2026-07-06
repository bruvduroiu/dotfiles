{ pkgs, lib, ... }:

{
  imports = [
    ./walker.nix
    ./waybar
    ./hyprlock.nix
    ./hypridle.nix
    ./wf-recorder.nix
  ];

  home.packages = with pkgs; [
    # screenshot: grim captures, satty annotates (wayland-native — no
    # fractional-scale jank like flameshot's Qt overlay)
    grim
    slurp
    satty

    wl-clipboard

    # standalone bluetooth TUI (deliberately no waybar module / tray)
    bluetui
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    XDG_SESSION_TYPE = "wayland";
  };

  systemd.user.targets.tray.Unit.Requires = lib.mkForce ["graphical-session.target"];

}
