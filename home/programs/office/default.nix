{ pkgs, ... }:

{
  imports = [
    ./thunar.nix
    ./zathura.nix
    ./invoice.nix
    ./obsidian
    ./thunderbird.nix
  ];

  home.packages = with pkgs; [
    libreoffice
    onlyoffice-desktopeditors
    papers
    gnucash
    pinta
    slack
    zulip-term
    xournalpp
  ];
}
