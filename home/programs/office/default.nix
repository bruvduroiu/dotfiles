{ pkgs, ... }:

{
  imports = [
    ./thunar.nix
    ./zathura.nix
    ./md2pdf
    ./obsidian
    ./thunderbird.nix
  ];

  home.packages = with pkgs; [
    invoice
    libreoffice
    gimp
    pinta
    slack
    sheets
    zulip-term
    xournalpp
  ];
}
