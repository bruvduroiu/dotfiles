{ pkgs, ... }:

{
  home.packages = with pkgs; [
    icloudpd
  ];
}
