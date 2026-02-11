{
  imports = [
    ./browsers/firefox.nix
    ./browsers/ladybird.nix
    ./wayland
    ./messaging.nix
    ./office
    ./hister.nix
    ./development.nix
    ./media
    ./media/rss
    ./media/audacious
  ];

  programs.rssguard.enable = true;
}
