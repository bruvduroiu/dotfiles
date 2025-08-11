{ pkgs, ... }:

{
  imports = [
    ./thunar.nix
    ./zathura.nix
  ];

  home.packages = with pkgs; [
    libreoffice
    obsidian
    papers
    pinta
    slack
    thunderbird
    xournalpp
  ];
}
