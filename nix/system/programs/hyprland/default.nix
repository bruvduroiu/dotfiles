{ inputs, pkgs, ... }:

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
      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
    ];
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  environment.variables = {
    NIXOS_OZONE_WL = "1";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };
}
