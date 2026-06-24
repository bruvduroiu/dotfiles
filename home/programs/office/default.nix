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
    gimp
    pinta
    slack
    sheets
    zulip-term
    xournalpp
  ];
}
