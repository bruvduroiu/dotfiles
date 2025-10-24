{ config, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    claude-code
  ];
}
