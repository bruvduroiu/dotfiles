# System module collections for different hosts
# Each host imports a collection that provides the appropriate modules
#
# Inheritance structure:
#   base → desktop → laptop
#                  → iso
#   base → steamdeck (uses Jovian-NixOS for desktop)

let
  # Shared across all hosts - core system functionality
  base = [
    ./core
    ./nix
    ./network
  ];

  # Desktop environment (Hyprland-based systems)
  # Extends base with graphics, audio, and Hyprland
  desktop = base ++ [
    ./hardware/graphics.nix
    ./hardware/bluetooth.nix
    ./hardware/uinput.nix

    ./programs
    ./programs/ranger.nix

    ./services/greetd.nix
    ./services/pipewire.nix
    ./services/power.nix
  ];

  # Full laptop configuration (Framework 13)
  # Extends desktop with laptop-specific hardware and services
  laptop = desktop ++ [
    ./core/boot.nix

    ./hardware/fwupd.nix
    ./hardware/keyboard.nix

    ./network/tailscale.nix
    ./network/syncthing.nix
    ./network/qbittorrent.nix

    ./programs/timewarrior.nix
    ./programs/wireshark.nix
    ./programs/kdeconnect.nix

    ./services/backlight.nix
    ./services/brightnessctl.nix
    ./services/kanata
    ./services/opensnitch.nix
    ./services/podman.nix
    ./services/rental-bot.nix
    ./services/restic.nix
    ./services/yubikey.nix
    ./services/fprintd.nix
  ];

  # Live ISO - portable system with Hyprland environment
  # Extends desktop with network auth and YubiKey support
  # Note: boot.nix excluded - ISO uses its own boot configuration
  iso = desktop ++ [
    ./network/tailscale.nix      # Base Tailscale service
    ./network/tailscale-iso.nix  # Auto-auth with sops-encrypted key

    ./services/yubikey.nix  # For sops decryption with age-plugin-yubikey
  ];

  # Steam Deck - minimal system modules
  # Hardware and Gaming Mode handled by Jovian-NixOS
  # Does not extend desktop (uses Jovian's Plasma/Gaming Mode)
  steamdeck = base ++ [
    ./core/boot.nix

    ./hardware/bluetooth.nix

    ./network/tailscale.nix
    ./network/qbittorrent.nix

    ./programs/kdeconnect.nix

    ./services/pipewire.nix
  ];

in {
  inherit laptop steamdeck iso;
}
