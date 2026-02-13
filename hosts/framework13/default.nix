{ lib, pkgs, self, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./hyprland.nix
    ./transmission.nix
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
  ];

  # --- Stylix theming ---
  stylix = {
    enable = true;
    autoEnable = true;
    image = "${self}/home/wallpapers/taipei-toner-4k-negative.png";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
    polarity = "dark";

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.hack;
        name = "Hack Nerd Font Mono";
      };
      sizes.terminal = 13;
    };

    opacity.terminal = 0.8;
  };

  # Light mode specialisation — switch via:
  #   sudo /nix/var/nix/profiles/system/specialisation/light/bin/switch-to-configuration switch
  specialisation.light.configuration = {
    stylix = {
      image = lib.mkForce "${self}/home/wallpapers/taipei-toner-4k-positive.png";
      base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/rose-pine-dawn.yaml";
      polarity = lib.mkForce "light";
    };
  };

  # Allow passwordless theme switching
  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        { command = "/nix/var/nix/profiles/system/specialisation/light/bin/switch-to-configuration switch"; options = [ "NOPASSWD" ]; }
        { command = "/nix/var/nix/profiles/system/bin/switch-to-configuration switch"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_6_18;
  };

  # System configuration
  networking.hostName = "framework13";

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services = {
    kanata.keyboards.io = {
      config = builtins.readFile "${self}/system/services/kanata/main.kbd";
      devices = [
        "/dev/input/by-path/platform-AMDI0010:01-event"
        "/dev/input/by-path/platform-i8042-serio-0-event-kbd"
      ];
    };
  };
}
