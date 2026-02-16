{ config, pkgs, ... }:

let
  mediaPaths = {
    torrents = "/home/deck/torrents";
  };

  # Pre-configure Kodi media sources so it's ready on first launch
  kodiSources = pkgs.writeText "sources.xml" ''
    <sources>
      <video>
        <default pathversion="1"></default>
        <source>
          <name>Torrents</name>
          <path pathversion="1">${mediaPaths.torrents}/</path>
          <allowsharing>true</allowsharing>
        </source>
      </video>
      <music>
        <default pathversion="1"></default>
        <source>
          <name>Torrents</name>
          <path pathversion="1">${mediaPaths.torrents}/</path>
          <allowsharing>true</allowsharing>
        </source>
      </music>
    </sources>
  '';

  # Enable hardware acceleration and set Steam Deck-friendly defaults
  kodiAdvancedSettings = pkgs.writeText "advancedsettings.xml" ''
    <advancedsettings version="1.0">
      <videoplayer>
        <usestagingbuffer>true</usestagingbuffer>
      </videoplayer>
    </advancedsettings>
  '';
in
{
  home.packages = [
    pkgs.kodi
  ];

  # Declarative Kodi configuration
  home.file = {
    ".kodi/userdata/sources.xml".source = kodiSources;
    ".kodi/userdata/advancedsettings.xml".source = kodiAdvancedSettings;
  };

  # XDG desktop entry for Kodi - add to Steam via "Add a Non-Steam Game" in Desktop Mode
  xdg.desktopEntries = {
    kodi-gamemode = {
      name = "Kodi";
      genericName = "Media Center";
      comment = "Browse and play local media";
      exec = "${pkgs.kodi}/bin/kodi --standalone";
      icon = "kodi";
      categories = [ "AudioVideo" "Video" "Player" ];
      terminal = false;
      settings = {
        StartupWMClass = "Kodi";
      };
    };
  };
}
