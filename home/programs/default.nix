{
  imports = [
    ./browsers/firefox.nix
    ./wayland
    ./messaging.nix
    ./office
    ./development.nix
    ./media
    ./media/rss
  ];

  programs.rssguard.enable = true;
}
