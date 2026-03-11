{ inputs, pkgs, lib, ... }:

{
  imports = [
    inputs.hyprland.nixosModules.default

    ./binds.nix
    ./rules.nix
    ./settings.nix
  ];

  environment = {
    pathsToLink = ["/share/icons"];
    systemPackages = [
      inputs.hyprland-contrib.packages.${pkgs.stdenv.hostPlatform.system}.grimblast
      pkgs.rose-pine-hyprcursor
    ];
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  environment.variables = {
    NIXOS_OZONE_WL = "1";
    XMODIFIERS = "@im=fcitx";
  };
}
