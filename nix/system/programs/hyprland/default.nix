{ inputs, pkgs, ... }:

{
  imports = [
    inputs.hyprland.nixosModules.default

    ./binds.nix
    ./rules.nix
    ./settings.nix
  ];

  environment.pathsToLink = ["/share/icons"];

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  environment.variables.NIXOS_OZONE_WL = "1";
}
