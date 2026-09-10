{
  services.fprintd.enable = true;
  # Noctalia uses fprintd directly and PAM only for passwords.
  security.pam.services.login.fprintAuth = false;
}
