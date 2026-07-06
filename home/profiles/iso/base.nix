{ config, pkgs, ... }:

{
  home = {
    username = "nixos";
    homeDirectory = "/home/nixos";
    stateVersion = "25.11";
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
