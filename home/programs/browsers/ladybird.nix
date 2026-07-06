{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ladybird
  ];
}
