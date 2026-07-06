{ pkgs, ... }:

{
  # Install ClamAV antivirus scanner for on-demand scanning
  environment.systemPackages = with pkgs; [
    clamav
  ];

  # Keep virus definitions updated automatically
  # No daemon needed - use 'clamscan' command for on-demand scanning
  services.clamav = {
    daemon.enable = false;  # Daemon uses 1GB RAM and socket doesn't work
    updater = {
      enable = true;
      interval = "hourly";
      frequency = 24;  # Check for updates once per day
    };
  };
}
