{ pkgs, ... }:

{
  home.sessionVariables = {
    DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
  };

  # `docker` is podman (dockerCompat), so registry logins go through
  # containers/image. By default `podman login` writes them base64-encoded to
  # $XDG_RUNTIME_DIR/containers/auth.json, which is plaintext and lost at
  # reboot. Store them in the KeePassXC Secret Service instead (docs/secrets.md).
  # Only the helper is listed, so nothing falls back to auth.json: with the
  # database locked, login and pulls from private registries fail until you
  # unlock. Public pulls need no credentials and keep working.
  home.packages = [ pkgs.docker-credential-helpers ];
  xdg.configFile."containers/registries.conf.d/50-credential-helpers.conf".text = ''
    credential-helpers = ["secretservice"]
  '';
}
