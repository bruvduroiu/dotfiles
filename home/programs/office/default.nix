{ pkgs, ... }:

{
  imports = [
    ./thunar.nix
    ./zathura.nix
  ];

  home.packages = with pkgs; [
    thunderbird
    libreoffice
    obsidian
    slack
  ];
}
