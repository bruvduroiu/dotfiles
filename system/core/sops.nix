{ ... }:

{
  # Global SOPS configuration for system-level secrets
  # Uses host-specific age key for unattended boot/service startup
  sops.age.keyFile = "/home/bogdan/.config/sops/age/keys.txt";
}
