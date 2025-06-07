{ self, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./hyprland.nix
  ];

  # System configuration
  networking.hostName = "framework13";

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services = {
    kanata.keyboards.io = {
      config = builtins.readFile "${self}/system/services/kanata/main.kbd";
      devices = [
        "/dev/input/by-path/platform-AMDI0010:01-event"
        "/dev/input/by-path/platform-i8042-serio-0-event-kbd"
      ];
    };
  };
}
