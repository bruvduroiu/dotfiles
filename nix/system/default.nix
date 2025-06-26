let laptop = [
  ./core
  ./core/boot.nix

  ./hardware/fwupd.nix
  ./hardware/uinput.nix
  ./hardware/graphics.nix
  ./hardware/bluetooth.nix

  ./network
  ./network/tailscale.nix
  ./network/syncthing.nix

  ./nix

  ./programs
  ./programs/ranger.nix
  ./programs/timewarrior.nix

  ./services/kanata
  ./services/greetd.nix
  ./services/pipewire.nix
  ./services/backlight.nix
  ./services/power.nix
  ./services/podman.nix
  ./services/brightnessctl.nix
];
in {
  inherit laptop;
}
