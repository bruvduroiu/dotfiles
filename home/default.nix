{ config, pkgs, ... }:

{
  imports = [
    ./terminal
    ./terminal/emulators/ghostty.nix
  ];

  home = {
    username = "bogdan";
    homeDirectory = "/home/bogdan";
    stateVersion = "25.05";
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
