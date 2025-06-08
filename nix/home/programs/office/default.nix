{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libreoffice
    obsidian
  ]
}
