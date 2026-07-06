{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ./nixpkgs.nix
    ./substituters.nix
  ];
}
