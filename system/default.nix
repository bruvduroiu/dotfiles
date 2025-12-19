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
];

# Steam Deck - minimal system modules
# Hardware and Gaming Mode handled by Jovian-NixOS
steamdeck = [
  ./core
  ./core/boot.nix

  ./hardware/bluetooth.nix

  ./network
  ./network/tailscale.nix

  ./nix

  ./programs
  ./programs/kdeconnect.nix

  ./services/pipewire.nix
];
in {
  inherit laptop steamdeck;
}
