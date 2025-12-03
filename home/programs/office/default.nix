{ pkgs, ... }:

{
  imports = [
    ./thunar.nix
    ./zathura.nix
    ./invoice.nix
    ./obsidian
  ];

  home.packages = with pkgs; [
    libreoffice
    papers
    pinta
    slack
    thunderbird
    xournalpp
  ];
}
