# OCI image, no Dockerfile. Linux only: it wraps the host-built binary, so
# flake.nix only exposes it on Linux systems. Secrets are never baked in;
# the runtime (k8s Secret, systemd, …) injects them as env.
{
  lib,
  dockerTools,
  cacert,
  package,
}:

dockerTools.buildLayeredImage {
  name = "myapp";
  tag = lib.getVersion package;
  contents = [ cacert ];
  config = {
    Entrypoint = [ (lib.getExe package) ];
    User = "65534:65534";
    Env = [ "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt" ];
  };
}
