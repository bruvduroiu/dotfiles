{ pkgs, ... }:

{
  imports = [
    ./zathura.nix
  ];

  home.packages = with pkgs; [
    thunderbird
    libreoffice
    obsidian
    slack
  ];
}
