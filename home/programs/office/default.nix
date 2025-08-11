{ pkgs, ... }:

{
  imports = [
    ./thunar.nix
    ./zathura.nix
  ];

  home.packages = with pkgs; [
    libreoffice
    thunderbird
    obsidian
    slack
  ];
}
