{ config, pkgs, ... }:

{
  # Media applications for Steam Deck TV setup
  home.packages = with pkgs; [
    # Jellyfin Media Player - Native Jellyfin client with controller support
    jellyfin-media-player

    # MPV - Lightweight video player (useful for direct file playback)
    mpv
  ];

  # Configure MPV for controller-friendly operation
  programs.mpv = {
    enable = true;
    config = {
      # Better quality settings for TV viewing
      profile = "gpu-hq";
      vo = "gpu";
      hwdec = "auto-safe";  # Hardware decoding for AMD GPU

      # Controller-friendly UI
      osd-level = 1;
      osd-duration = 2500;
      osd-font-size = 55;

      # Fullscreen by default (good for TV)
      fullscreen = true;

      # Keep player open after file ends
      keep-open = true;
    };

    bindings = {
      # Steam Deck controller bindings
      "GAMEPAD_DPAD_UP" = "seek 10";
      "GAMEPAD_DPAD_DOWN" = "seek -10";
      "GAMEPAD_DPAD_LEFT" = "seek -60";
      "GAMEPAD_DPAD_RIGHT" = "seek 60";
      "GAMEPAD_ACTION_DOWN" = "cycle pause";  # A button
      "GAMEPAD_BACK" = "quit";  # Select button
    };
  };

  # XDG desktop entry for Jellyfin - steam-rom-manager can detect and add to Gaming Mode
  xdg.desktopEntries = {
    jellyfin-gamemode = {
      name = "Jellyfin";
      genericName = "Media Player";
      comment = "Jellyfin Media Player for TV viewing";
      exec = "${pkgs.jellyfin-media-player}/bin/jellyfinmediaplayer --fullscreen --tv";
      icon = "com.github.iwalton3.jellyfin-media-player";
      categories = [ "AudioVideo" "Video" "Player" ];
      terminal = false;
    };
  };
}
