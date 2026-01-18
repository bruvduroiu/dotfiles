# Phantom USB - Declarative disk layout with Disko
# LUKS-encrypted BTRFS with ephemeral tmpfs root
#
# Partition layout:
#   ESP (1GB)     - FAT32, EFI bootloader (works on any UEFI machine)
#   LUKS (rest)   - Encrypted container, unlocked via YubiKey FIDO2
#     └── BTRFS
#         ├── @nix       - Nix store (compressed, read-heavy)
#         ├── @persist   - Persistent state (secrets, tailscale, etc.)
#         └── @snapshots - Optional BTRFS snapshots
#
# Root (/) is tmpfs - everything not in /nix or /persist vanishes on reboot
{ lib, ... }:

{
  disko.devices = {
    disk = {
      phantom = {
        type = "disk";
        # IMPORTANT: This targets ONLY this specific USB drive by serial number
        # It will NOT accidentally wipe your SSD or any other drive
        device = "/dev/disk/by-id/usb-_USB_DISK_3.0_070D48E289013A26-0:0";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              name = "ESP";
              size = "1G";
              type = "EF00";  # EFI System Partition
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" "noatime" ];
              };
            };
            luks = {
              name = "cryptroot";
              size = "100%";
              content = {
                type = "luks";
                name = "phantom-crypt";
                settings = {
                  allowDiscards = true;   # TRIM support for SSD-based USB drives
                  bypassWorkqueues = true; # Better performance on modern drives
                };
                # For initial setup, provide password via /tmp/disk-password
                # After setup, enroll YubiKey with:
                #   sudo systemd-cryptenroll /dev/disk/by-partlabel/cryptroot --fido2-device=auto
                passwordFile = "/tmp/disk-password";
                extraFormatArgs = [
                  "--type" "luks2"
                  "--cipher" "aes-xts-plain64"
                  "--key-size" "512"
                  "--hash" "sha512"
                  "--pbkdf" "argon2id"
                  "--label" "phantom-luks"
                ];
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" "-L" "phantom-btrfs" ];
                  subvolumes = {
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd:3" "noatime" "ssd" ];
                    };
                    "@persist" = {
                      mountpoint = "/persist";
                      mountOptions = [ "compress=zstd:3" "noatime" "ssd" ];
                    };
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = [ "compress=zstd:3" "noatime" "ssd" ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
