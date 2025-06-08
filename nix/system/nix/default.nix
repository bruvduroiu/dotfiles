{ config, pkgs, input, lib, ... }:

{
  imports = [
    ./nixpkgs.nix
    ./substituters.nix
  ];
}
