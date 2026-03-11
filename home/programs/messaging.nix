{ pkgs, inputs, ... }:

let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  home.packages = with pkgs; [
    pkgs-unstable.telegram-desktop
    discord-ptb
    signal-desktop
    element-desktop
  ];
}
