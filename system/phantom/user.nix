# Phantom USB - User and auth configuration
# Extends base user with phantom-specific settings
{ config, lib, pkgs, ... }:

{
  # Extend base bogdan user with phantom-specific groups
  users.users.bogdan = {
    extraGroups = [ "video" "audio" ];  # Added to base groups
    initialHashedPassword = "";  # Empty password - use YubiKey for auth
  };

  # YubiKey PAM authentication for login and sudo
  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
    greetd.u2fAuth = true;
  };

  security.pam.u2f = {
    enable = true;
    settings.cue = true;  # Prompt "Please touch your YubiKey"
    control = "sufficient";  # Allow password OR YubiKey
  };

  # SSH with key-based auth only (more secure for portable device)
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
