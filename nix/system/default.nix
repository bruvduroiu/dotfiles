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

  ./services/kanata
  ./services/greetd.nix
  ./services/pipewire.nix
  ./services/backlight.nix
  ./services/power.nix
];
in {
  inherit laptop;
}
