# Phantom USB - Paranoid security measures
# Memory scrubbing, shutdown cleanup, and forensics resistance
{ config, lib, pkgs, ... }:

{
  # Memory scrub service - runs on shutdown to clear sensitive data
  systemd.services.memory-scrub = {
    description = "Scrub sensitive memory on shutdown";
    before = [ "shutdown.target" "reboot.target" "halt.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = pkgs.writeShellScript "scrub-memory" ''
        # Sync all filesystems
        sync
        # Drop page cache, dentries, and inodes
        echo 3 > /proc/sys/vm/drop_caches
      '';
    };
    script = "true";
  };

  # Tailscale logout on shutdown - immediately removes node from tailnet
  systemd.services.tailscale-logout = {
    description = "Logout from Tailscale on shutdown";
    before = [ "shutdown.target" "reboot.target" "halt.target" ];
    after = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.tailscale}/bin/tailscale logout";
    };
    script = "true";
  };

  # Lock LUKS volumes on suspend
  powerManagement.powerDownCommands = ''
    ${pkgs.cryptsetup}/bin/cryptsetup luksClose phantom-crypt || true
  '';

  # Crypto tools for LUKS operations
  environment.systemPackages = with pkgs; [
    cryptsetup
  ];

  # Disable swap - no secrets written to disk
  swapDevices = lib.mkForce [ ];

  # Disable hibernation - prevents memory image on disk
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
}
