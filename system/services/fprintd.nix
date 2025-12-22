{
  services.fprintd.enable = true;

  # Configure PAM for hyprlock to use fingerprint authentication
  security.pam.services.hyprlock = {
    fprintAuth = true;
  };
}
