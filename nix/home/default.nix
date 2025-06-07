{ config, pkgs, ... }:

{
  imports = [
    ./shell.nix
    ./terminal.nix
    ./development.nix
  ];

  home.username = "bogdan";
  home.homeDirectory = "/home/bogdan";
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
