{ pkgs, ... }:

{
  imports = [
    ./thunar.nix
    ./zathura.nix
  ];

  home.packages = with pkgs; [
    papers
    xournalpp
    libreoffice
    thunderbird
    obsidian
    slack
  ];
}
