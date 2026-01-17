let laptop = [
  ./core
  ./core/boot.nix

  ./hardware/fwupd.nix
  ./hardware/uinput.nix
  ./hardware/graphics.nix
  ./hardware/bluetooth.nix
  ./hardware/keyboard.nix

  ./network
  ./network/tailscale.nix
  ./network/syncthing.nix
  ./network/qbittorrent.nix

  ./nix

  ./programs
  ./programs/ranger.nix
  ./programs/timewarrior.nix
  ./programs/wireshark.nix
  ./programs/kdeconnect.nix

  ./services/backlight.nix
  ./services/brightnessctl.nix
  ./services/greetd.nix
  ./services/kanata
  ./services/opensnitch.nix
  ./services/pipewire.nix
  ./services/podman.nix
  ./services/power.nix
  ./services/rental-bot.nix
  ./services/restic.nix
  ./services/yubikey.nix
  ./services/fprintd.nix
];

# Live ISO - portable system with most Framework13 functionality
# Boots into Hyprland with your familiar environment
iso = [
  ./core
  # Note: boot.nix excluded - ISO uses its own boot configuration

  # Hardware support (generic, works on most x86_64 machines)
  ./hardware/graphics.nix
  ./hardware/bluetooth.nix
  ./hardware/uinput.nix

  # Network (essential for live environment)
  ./network
  ./network/tailscale.nix      # Base Tailscale service
  ./network/tailscale-iso.nix  # Auto-auth with sops-encrypted key

  # Nix configuration
  ./nix

  # Programs and desktop
  ./programs
  ./programs/ranger.nix

  # Services
  ./services/pipewire.nix
  ./services/power.nix
  ./services/yubikey.nix  # For sops decryption with age-plugin-yubikey
];

# Steam Deck - minimal system modules
# Hardware and Gaming Mode handled by Jovian-NixOS
steamdeck = [
  ./core
  ./core/boot.nix

  ./hardware/bluetooth.nix

  ./network
  ./network/tailscale.nix
  ./network/qbittorrent.nix

  ./nix

  ./programs
  ./programs/kdeconnect.nix

  ./services/pipewire.nix
];
in {
  inherit laptop steamdeck iso;
}
