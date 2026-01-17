{ config, lib, pkgs, inputs, self, ... }:

{
  # Set the system architecture
  nixpkgs.hostPlatform = "x86_64-linux";

  imports = [
    # NixOS live CD base - provides squashfs root, ISO boot, live user
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-base.nix"
    # Note: channel.nix removed to save ~500MB+ (use network for packages)
  ];

  # ISO image configuration - optimized for size (FAT32 4GB limit)
  image.fileName = lib.mkForce "nixos-live-${config.system.nixos.label}-x86_64.iso";
  isoImage = {
    volumeID = "NIXOS_LIVE";
    # Use maximum xz compression for smallest size
    # Trade-off: ~4x longer build time, but significantly smaller ISO
    squashfsCompression = "xz -Xdict-size 100%";
    # Don't include build dependencies in the ISO
    includeSystemBuildDependencies = false;
  };

  # Override default graphical target (GNOME) with Hyprland
  services.desktopManager.gnome.enable = lib.mkForce false;
  services.displayManager.defaultSession = lib.mkForce null;

  # Greetd configuration for ISO (uses shared module with different user)
  desktop.greetd.user = "nixos";

  # YubiKey configuration for ISO user
  # The identity string is NOT a secret - it just tells age which YubiKey slot to use
  # The private key never leaves the YubiKey hardware
  security.yubikey = {
    user = "nixos";
    identity = "AGE-PLUGIN-YUBIKEY-1LV5W7QVZFC7RZDQ6KZZEW";
  };

  # Live user configuration (nixos is the default live user)
  # The installer CD module already creates this user, so we extend it
  users.users.nixos = {
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    # Override the empty password with a known one for sudo
    initialPassword = lib.mkForce "nixos";
    initialHashedPassword = lib.mkForce null;
    shell = pkgs.fish;
  };

  users.users.root = {
    initialPassword = lib.mkForce "nixos";
    initialHashedPassword = lib.mkForce null;
  };

  # Enable fish shell
  programs.fish.enable = true;

  # Hardware support - only redistributable firmware to save space
  # enableAllFirmware adds ~1GB+ of proprietary blobs
  hardware.enableAllFirmware = false;
  hardware.enableRedistributableFirmware = true;
  nixpkgs.config.allowUnfree = true;

  # Broader hardware compatibility
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
  boot.initrd.availableKernelModules = [
    "nvme" "xhci_pci" "ahci" "usb_storage" "sd_mod" "sdhci_pci"
    "thunderbolt" "uas"
  ];

  # SSH for remote access (useful for debugging)
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };
  # Start SSH on boot
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];

  # Essential packages for live environment (minimized for ISO size)
  # Note: networkmanagerapplet now comes from system/network module
  environment.systemPackages = with pkgs; [
    # System utilities
    git
    htop
    file
    unzip

    # Disk management (parted is CLI-only, much smaller than gparted)
    parted
    ntfs3g

    # Network tools
    wget
    curl

    # Terminal and editing (neovim comes via home-manager)
    ripgrep
    fd
    fzf
    bat
    eza

    # Sops and age for secret decryption
    sops
    age
    age-plugin-yubikey

    # Screenshot and clipboard (for Hyprland)
    inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
    wl-clipboard
    slurp
    grim

    # File manager (yazi is terminal-based, much lighter than nautilus)
    inputs.yazi.packages.${pkgs.system}.default

    # Browser - install via nix-shell when needed to save ~500MB
    # Run: nix-shell -p firefox
  ];

  # Networking
  networking = {
    hostName = "nixos-live";
    networkmanager.enable = true;
    wireless.enable = lib.mkForce false;  # Use NetworkManager instead
  };

  # Power management for laptops
  services.upower.enable = true;
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "ignore";
  };

  # Disable some heavy services not needed for live environment
  documentation.nixos.enable = lib.mkForce false;

  # System state version
  system.stateVersion = "25.11";
}
