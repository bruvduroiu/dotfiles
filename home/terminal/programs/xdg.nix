{ config, pkgs, ... }: let
  browser = ["firefox"];
  textEditor = ["nvim"];
  imageViewer = ["org.gnome.Loupe"];
  videoPlayer = ["io.github.celluloid_player.Celluloid"];
  audioPlayer = ["io.bassi.Amberol"];
  officeEditor = ["onlyoffice-desktopeditors.desktop"];

  xdgAssociations = type: program: list:
    builtins.listToAttrs (map (e: {
        name = "${type}/${e}";
        value = program;
      })
      list);

  text = xdgAssociations "text" textEditor ["english" "html" "plain" "x-log" "x-makefile" "xml" "markdown"];
  applicationText = xdgAssociations "application" textEditor ["rtf" "vnd.mozilla.xul+xml" "xhtml+xml" "xml" "x-shellscript" "x-wine-extension-ini" "zip"];
  image = xdgAssociations "image" imageViewer ["png" "svg" "jpeg" "gif"];
  video = xdgAssociations "video" videoPlayer ["mp4" "avi" "mkv"];
  audio = xdgAssociations "audio" audioPlayer ["mp3" "flac" "wav" "aac"];
  browserTypes =
    (xdgAssociations "application" browser [
      "json"
      "x-extension-htm"
      "x-extension-html"
      "x-extension-shtml"
      "x-extension-xht"
      "x-extension-xhtml"
      "xhtml+xml"
    ]);
  office = 
    (xdgAssociations "application" officeEditor [
      "vnd.openxmlformats-officedocument.wordprocessingml.document"
      "vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      "vnd.openxmlformats-officedocument.presentationml.presentation"
      "vnd.oasis.opendocument.text"
      "vnd.oasis.opendocument.spreadsheet"
      "vnd.oasis.opendocument.presentation"
      "msword"
      "vnd.ms-excel"
      "vnd.ms-powerpoint"
    ]);

  # XDG MIME types
  associations = builtins.mapAttrs (_: v: (map (e: "${e}.desktop") v)) ({
      "application/epub+zip" = ["org.pwmt.zathura"];
      "application/pdf" = ["org.pwmt.zathura"];
      "text/plain" = ["nvim"];
      "inode/directory" = ["thunar.desktop"];
      "x-scheme-handler/magnet" = ["transmission-gtk"];
      # Full entry is org.telegram.desktop.desktop
      "x-scheme-handler/tg" = ["org.telegram.desktop"];
      "x-scheme-handler/tonsite" = ["org.telegram.desktop"];
    }
    image
    video
    audio
    browserTypes
    text
    office
    applicationText
  );
in 

{
  xdg = {
    enable = true;

    userDirs = {
      enable = true;
      createDirectories = true;
      extraConfig = {
        XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/Screenshots";
      };
    };
  };

  home.packages = with pkgs; [
    xdg-utils
  ];
}
