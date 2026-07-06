{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.devenv
  ];
}
