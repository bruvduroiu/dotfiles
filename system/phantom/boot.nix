# Phantom USB - Portable EFI boot configuration
# Works on any UEFI machine without modifying its EFI variables
{ config, lib, pkgs, ... }:

{
  boot = {
    # Universal kernel for maximum hardware compatibility
    kernelPackages = pkgs.linuxPackages_latest;

    loader = {
      # Don't touch the host machine's EFI variables
      efi.canTouchEfiVariables = false;

      grub = {
        enable = true;
        efiSupport = true;
        # Install as removable media - works on ANY UEFI machine
        efiInstallAsRemovable = true;
        device = "nodev";
        # Don't probe the host's drives - we only boot from USB
        useOSProber = false;
      };

      timeout = 3;
    };

    # LUKS device configuration for systemd-cryptsetup
    # Note: Disko creates the partition label as "disk-{diskName}-{partitionName}"
    initrd.luks.devices."phantom-crypt" = {
      device = "/dev/disk/by-partlabel/disk-phantom-cryptroot";
      preLVM = true;
      allowDiscards = true;
      # FIDO2 unlock with YubiKey - just touch, no password needed
      crypttabExtraOpts = [ "fido2-device=auto" ];
    };

    # Use systemd in initrd for FIDO2 support
    initrd.systemd.enable = true;

    # Broad initrd module support - boot on any x86_64 machine
    initrd.availableKernelModules = [
      # USB (essential for USB boot)
      "xhci_pci" "xhci_hcd" "ehci_pci" "ohci_pci" "uhci_hcd"
      "usb_storage" "usbhid" "uas" "sd_mod"

      # Storage controllers
      "ahci" "nvme" "sata_nv" "sata_sil" "sata_sis"

      # Filesystems
      "ext4" "btrfs" "vfat" "iso9660"

      # Crypto (for LUKS)
      "dm_crypt" "dm_mod" "encrypted_keys" "aesni_intel" "cryptd"

      # HID for YubiKey FIDO2 in initrd
      "hid_generic" "usbhid"

      # Common laptop hardware
      "thunderbolt" "sdhci_pci" "mmc_block"
    ];

    kernelModules = [ "kvm-intel" "kvm-amd" ];

    # Security-focused kernel parameters
    kernelParams = [
      # Memory forensics protection
      "lockdown=confidentiality"
      "init_on_alloc=1"
      "init_on_free=1"

      # Additional hardening
      "slab_nomerge"
      "page_alloc.shuffle=1"
    ];
  };

  # Kernel hardening sysctls
  boot.kernel.sysctl = {
    "kernel.core_pattern" = "|/bin/false";  # Disable core dumps
    "kernel.kptr_restrict" = 2;              # Hide kernel pointers
    "kernel.dmesg_restrict" = 1;             # Restrict dmesg to root
    "kernel.sysrq" = 0;                      # Disable magic sysrq
  };
}
