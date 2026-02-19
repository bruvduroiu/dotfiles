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
    gnucash
    pinta
    slack
    zulip-term
    thunderbird
    xournalpp
  ];
}
