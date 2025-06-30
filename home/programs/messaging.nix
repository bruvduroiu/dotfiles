{ pkgs, ... }:

{
  home.packages = with pkgs; [
    telegram-desktop
    discord-ptb
    signal-desktop
  ];
}
