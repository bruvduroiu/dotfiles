{ config, pkgs, inputs, ... }:

{
  imports = [
    ./syncthing.nix
    ../../programs/keepassxc.nix
    ../../programs/games/minecraft
  ];

  home = {
    username = "deck";
    homeDirectory = "/home/deck";
    stateVersion = "25.11";
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
