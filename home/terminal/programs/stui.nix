{ pkgs, ... }:

{
  home.packages = with pkgs; [ s-tui ];
}
