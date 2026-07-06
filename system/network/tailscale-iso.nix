# Tailscale ISO system-level configuration
# The actual auth happens in home-manager after graphical login
# This just disables the empty tailscale-autoconnect from base tailscale.nix
{ lib, ... }:

{
  # Disable the base tailscale-autoconnect service
  # Authentication will be handled by a user service after graphical login
  # This allows pinentry-qt to prompt for the YubiKey PIN
  systemd.services.tailscale-autoconnect = {
    enable = lib.mkForce false;
  };
}
