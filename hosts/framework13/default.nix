{ lib, pkgs, self, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./transmission.nix
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    inputs.secrets.nixosModules.default
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

    opacity.terminal = 0.9;
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
    kernelPackages = lib.mkForce inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackages_latest;

    # The nixos-hardware framework-amd-ai-300-series module sets
    # amdgpu.dcdebugmask=0x10 (disable PSR) against panel flicker, but the
    # BOE 2.8K panel negotiates eDP Panel Replay, which 0x10 doesn't cover —
    # its selective-update rectangles flash on screen. 0x410 also disables
    # Replay (0x400); mkAfter puts it after the module's 0x10 on the
    # cmdline, and the last assignment of a module param wins. If rectangles
    # persist, the next escalation is 0x610 (adds PSR-SU, 0x200).
    kernelParams = lib.mkAfter [ "amdgpu.dcdebugmask=0x410" ];
  };

  # System configuration
  networking.hostName = "framework13";

  # OpenCode web UI, bound to all interfaces for LAN and WireGuard access.
  networking.firewall.allowedTCPPorts = [ 4096 ];

  # WireGuard peer identity (see system/network/wireguard.nix).
  # Addresses live in the private flake's vars.
  network.wireguard = inputs.secrets.vars.hosts.framework13.wireguard;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;
}
