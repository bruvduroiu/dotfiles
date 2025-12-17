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
];
in {
  inherit laptop;
}
