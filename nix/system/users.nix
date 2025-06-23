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
  # (if you disable this, you must disable the default fish shell)
  programs.fish.enable = true;
}
