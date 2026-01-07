{ config, pkgs, self, ... }:

let
  secretsFile = "${self}/secrets/framework13/tailsnitch.yaml";

  # Wrap tailsnitch to load OAuth credentials from sops secrets at runtime
  wrappedTailsnitch = pkgs.writeShellScriptBin "tailsnitch" ''
    export TS_OAUTH_CLIENT_ID="$(cat "${config.sops.secrets.ts_oauth_client_id.path}")"
    export TS_OAUTH_CLIENT_SECRET="$(cat "${config.sops.secrets.ts_oauth_client_secret.path}")"
    exec ${pkgs.tailsnitch}/bin/tailsnitch "$@"
  '';
in {
  # SOPS secrets configuration for Tailsnitch OAuth credentials
  sops = {
    age.keyFile = "/home/bogdan/.config/sops/age/keys.txt";
    secrets = {
      ts_oauth_client_id = {
        sopsFile = secretsFile;
      };
      ts_oauth_client_secret = {
        sopsFile = secretsFile;
      };
    };
  };

  # Install wrapped tailsnitch that automatically loads credentials
  home.packages = [ wrappedTailsnitch ];
}
