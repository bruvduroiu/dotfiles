{
  imports = [
    ./browsers/firefox.nix
    ./browsers/ladybird.nix
    ./browsers/lightpanda.nix
    ./wayland
    ./messaging.nix
    ./office
    ./development.nix
    ./media
    ./media/rss
  ];

  programs.rssguard.enable = true;
}
