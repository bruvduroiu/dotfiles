{ pkgs, ... }:

{
  home.packages = with pkgs; [
    thunderbird
    libreoffice
    obsidian
    slack
  ];
}
