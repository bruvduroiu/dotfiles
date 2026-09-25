{ lib, pkgs, self, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./transmission.nix
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    inputs.secrets.nixosModules.default
  ];

  # dotool (the typing driver behind push-to-talk dictation,
  # home/programs/wayland/voxtype.nix) writes to /dev/uinput, which
  # hardware.uinput.enable (system/hardware) leaves group-owned by `uinput`.
  # Lists merge with system/core/users.nix. Takes effect at the next login,
  # not at switch: group membership is read when the session starts.
  users.users.bogdan.extraGroups = [ "uinput" ];

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

  # Noctalia owns runtime dark/light switching; Stylix remains the static
  # baseline for applications without a native Noctalia integration.
  services.power-profiles-daemon.enable = true;
  i18n.inputMethod.fcitx5.settings.addons.classicui.globalSection = {
    Theme = lib.mkForce "noctalia";
    DarkTheme = lib.mkForce "noctalia";
  };

  # Noctalia uses login for passwords and fprintd directly for biometrics.
  # Keep PAM from claiming the same reader (also makes TTY login password-only).
  security.pam.services.login.fprintAuth = false;

  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  boot = {
    kernelPackages = lib.mkForce inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackages_latest;

    # The nixos-hardware framework-amd-ai-300-series module sets
    # amdgpu.dcdebugmask=0x10 (disable PSR) against panel flicker, but the
    # BOE 2.8K panel negotiates eDP Panel Replay, which 0x10 doesn't cover —
    # its selective-update rectangles flash on screen. 0x410 also disables
    # Replay (0x400); mkAfter puts it after the module's 0x10 on the
    # cmdline, and the last assignment of a module param wins.
    #
    # 0x410 alone didn't clear the rectangles (2026-09-01), so also disable
    # scatter-gather display: with sg_display on auto the APU scans the
    # framebuffer out of scattered system-RAM pages, and bandwidth hiccups
    # show as exactly these transient rectangles. Next rung if it persists:
    # dcdebugmask 0xC10 (adds IPS, 0x800).
    kernelParams = lib.mkAfter [
      "amdgpu.dcdebugmask=0x410"
      "amdgpu.sg_display=0"
    ];
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
