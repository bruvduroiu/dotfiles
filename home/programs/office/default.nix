{ pkgs, ... }:

{
  imports = [
    ./thunar.nix
    ./zathura.nix
    ./obsidian
    ./thunderbird.nix
  ];

  home.packages = with pkgs; [
    invoice
    libreoffice
    onlyoffice-desktopeditors
    papers
    gnucash
    pinta
    slack
    sheets
    zulip-term
    xournalpp
  ];
}
