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
    onlyoffice-desktopeditors
    papers
    pinta
    slack
    thunderbird
    xournalpp
  ];
}
