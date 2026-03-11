{ config, pkgs, ... }:

{
  imports = [
    ./terminal
    ./terminal/emulators/ghostty.nix
  ];

  home = {
    username = "bogdan";
    homeDirectory = "/home/bogdan";
    stateVersion = "25.11";

    packages = [ pkgs.rose-pine-hyprcursor ];

    pointerCursor = {
      name = "rose-pine-cursor";
      package = pkgs.rose-pine-cursor;
      size = 24;
      gtk.enable = true;
    };
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
