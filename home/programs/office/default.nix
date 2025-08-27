{ pkgs, ... }:

{
  imports = [
    ./thunar.nix
    ./zathura.nix
    ./invoice.nix
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
