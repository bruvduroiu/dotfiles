{ config, pkgs, ... }:

{
  users = {
    defaultUserShell = pkgs.fish;

    users.bogdan = {
      isNormalUser = true;
      description = "Bogdan";
      extraGroups = [ "networkmanager" "wheel" "docker" ];
    };
  };

  # Enable fish shell system-wide
  programs.fish.enable = true;
}
