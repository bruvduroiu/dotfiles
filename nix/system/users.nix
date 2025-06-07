{ config, pkgs, ... }:

{
  users.users.bogdan = {
    isNormalUser = true;
    description = "Bogdan";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.fish;
  };

  # Enable fish shell system-wide
  programs.fish.enable = true;
}
