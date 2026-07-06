{ config, lib, pkgs, ... }:

let
  mediaPaths = {
    # Transmission lands completed files here (hosts/steamdeck/transmission.nix).
    # The deck user's primary group is `users`, which owns this 0775 dir, so
    # Kodi can read it. Previously pointed at ~/torrents — nothing was there.
    torrents = "/srv/torrents/downloads";
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

  # Hardware-friendly defaults plus a large read-ahead cache. buffermode=1
  # buffers all local + network sources, so playing a file that Transmission is
  # still writing to (or off a NAS later) doesn't stutter on the Deck's storage.
  kodiAdvancedSettings = pkgs.writeText "advancedsettings.xml" ''
    <advancedsettings version="1.0">
      <videoplayer>
        <usestagingbuffer>true</usestagingbuffer>
      </videoplayer>
      <cache>
        <buffermode>1</buffermode>
        <memorysize>209715200</memorysize>
        <readfactor>4</readfactor>
      </cache>
    </advancedsettings>
  '';

  # Seed for the web remote (Kore/Yatse phone apps, browser UI on :8080).
  # NOT symlinked into place: Kodi rewrites guisettings.xml on every exit, so a
  # read-only store symlink would break it. The activation script below copies
  # this once, only if no guisettings exists yet, then Kodi owns the file.
  kodiGuiSettings = pkgs.writeText "guisettings.xml" ''
    <settings version="2">
      <setting id="services.webserver" default="false">true</setting>
      <setting id="services.webserverport" default="false">8080</setting>
      <setting id="services.webserverusername" default="false">kodi</setting>
      <setting id="services.esallinterfaces" default="false">true</setting>
    </settings>
  '';
in
{
  home.packages = [
    pkgs.kodi
  ];

  # Read-only declarative config (Kodi only reads these)
  home.file = {
    ".kodi/userdata/sources.xml".source = kodiSources;
    ".kodi/userdata/advancedsettings.xml".source = kodiAdvancedSettings;
  };

  # Writable seed for guisettings — copy once, leave Kodi to manage afterwards.
  home.activation.kodiGuiSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    guifile="$HOME/.kodi/userdata/guisettings.xml"
    if [ ! -f "$guifile" ]; then
      run mkdir -p "$HOME/.kodi/userdata"
      run cp ${kodiGuiSettings} "$guifile"
      run chmod u+w "$guifile"
    fi
  '';

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
