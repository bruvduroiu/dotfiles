# Phantom USB - Impermanence configuration
# Defines what state persists across reboots
{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  # The magic: root is tmpfs, everything vanishes on poweroff
  # This is defined here (not in disko.nix) so nixos-install can write to /mnt
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=8G" "mode=755" ];
  };

  # Ensure /persist is available before anything tries to use it
  fileSystems."/persist".neededForBoot = true;

  # System-level persistence
  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      "/var/lib/nixos"                         # User/group uid/gid mappings
      "/var/lib/tailscale"
      "/var/lib/bluetooth"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
    ];

    files = [
      "/etc/machine-id"
    ];

    users.bogdan = {
      directories = [
        ".gnupg"
        ".ssh"
        ".local/share/keyrings"
      ];
      files = [
        ".bash_history"
      ];
    };
  };

  # Create necessary directories on boot
  systemd.tmpfiles.rules = [
    "d /home/bogdan 0700 bogdan users -"
    "d /home/bogdan/.config 0700 bogdan users -"
    "d /home/bogdan/.local 0700 bogdan users -"
    "d /home/bogdan/.local/share 0700 bogdan users -"
    "d /home/bogdan/.cache 0700 bogdan users -"
    "d /persist 0755 root root -"
    "d /persist/home 0755 root root -"
    "d /persist/home/bogdan 0700 bogdan users -"
    "d /persist/secrets 0700 root root -"
  ];
}
