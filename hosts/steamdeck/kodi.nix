{ config, lib, pkgs, ... }:

let
  # Standalone Kodi wrapped in gamescope — same compositor Gaming Mode uses,
  # so it inherits the Deck's HDR/VRR/scaling pipeline instead of grabbing DRM
  # master directly (which fights Jovian's session). Runs as the deck user, so
  # it reads the same ~/.kodi config seeded by the home-manager profile.
  kodiSession = pkgs.writeShellScriptBin "kodi-session" ''
    exec ${pkgs.gamescope}/bin/gamescope -- ${pkgs.kodi}/bin/kodi --standalone
  '';

  # Register Kodi as a selectable Wayland session. Shows up in the desktop-mode
  # session switcher alongside Plasma; Gaming Mode stays the autostart default.
  # sessionPackages validates each entry against a "package with provided
  # sessions" type: the derivation must expose `providedSessions`, and each
  # name must match a share/wayland-sessions/<name>.desktop file it ships.
  sessionDesktop = (pkgs.writeTextFile {
    name = "kodi-wayland-session";
    destination = "/share/wayland-sessions/kodi.desktop";
    text = ''
      [Desktop Entry]
      Name=Kodi Media Center
      Comment=Standalone Kodi for couch/TV use
      Exec=kodi-session
      Type=Application
      DesktopNames=Kodi
    '';
  }) // { providedSessions = [ "kodi" ]; };
in
{
  environment.systemPackages = [
    pkgs.libcec       # cec-client for testing HDMI-CEC; Kodi's peripheral.libcec
                      # addon auto-enables when an adapter is detected
    kodiSession
    sessionDesktop
  ];

  services.displayManager.sessionPackages = [ sessionDesktop ];

  # CEC adapters (Pulse-Eight / dock bridges) expose a serial tty — deck needs
  # dialout to talk to it. extraGroups lists merge, so this appends to the set
  # defined in default.nix.
  users.users.deck.extraGroups = [ "dialout" ];
}
