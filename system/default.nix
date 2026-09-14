# System module collections for different hosts
# Each host imports a collection that provides the appropriate modules
#
# Inheritance structure:
#   base → desktop → laptop
#                  → phantom (ephemeral USB with impermanence)
#   base → steamdeck (uses Jovian-NixOS for desktop)

let
  # Shared across all hosts - core system functionality
  base = [
    ./core
    ./nix
    ./network
  ];

  # Desktop services; each host selects its compositor.
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

    ./network/wireguard.nix
    ./network/syncthing.nix
    ./network/transmission.nix

    ./programs/timewarrior.nix
    ./programs/wireshark.nix
    ./programs/kdeconnect.nix
    ./programs/devenv.nix

    ./services/backlight.nix
    ./services/brightnessctl.nix
    ./services/clamav.nix
    ./services/kanata
    ./services/podman.nix
    ./services/restic.nix
    ./services/yubikey.nix
    ./services/fprintd.nix
  ];

  # Phantom USB - ephemeral system with impermanence
  # Extends desktop with LUKS boot, impermanence, and paranoid security
  # Root is tmpfs - only /persist survives reboot
  phantom = desktop ++ [
    ./phantom/boot.nix           # Portable EFI boot with LUKS/FIDO2
    ./phantom/hardware.nix       # Universal hardware support
    ./phantom/impermanence.nix   # Ephemeral root with selective persistence
    ./phantom/paranoid.nix       # Memory cleanup on shutdown
    ./phantom/wireguard.nix      # Boot-time home overlay (key on /persist)
    ./phantom/user.nix           # bogdan user with YubiKey auth
    ./phantom/packages.nix       # Portable hacking station tools

    ./services/yubikey.nix       # For runtime sops decryption
  ];

  # Steam Deck - minimal system modules
  # Hardware and Gaming Mode handled by Jovian-NixOS
  # Does not extend desktop (Jovian owns Gaming Mode and Niri session switching)
  steamdeck = base ++ [
    ./core/boot.nix

    ./hardware/bluetooth.nix

    ./network/wireguard.nix
    ./network/transmission.nix

    ./programs/kdeconnect.nix

    ./services/pipewire.nix
  ];

in {
  inherit laptop steamdeck phantom;
}
