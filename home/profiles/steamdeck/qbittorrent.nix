{ config, lib, pkgs, self, ... }:

let
  secretsFile = "${self}/secrets/steamdeck/qbittorrent.yaml";
in {
  # SOPS secrets configuration for qBittorrent WebUI authentication
  sops = {
    age.keyFile = "/home/deck/.config/sops/age/keys.txt";
    secrets = {
      qbittorrent_webui_password = {
        sopsFile = secretsFile;
      };
    };
  };

  # Override qBittorrent config to use SOPS secret for password
  # Note: qBittorrent requires a PBKDF2 hash, not plaintext
  # Generate hash with: qbittorrent-nox --webui-port=9091 (then check config for hash)
  # Or use Python: from hashlib import pbkdf2_hmac; import base64; ...

  systemd.user.services.qbittorrent = {
    Unit = {
      After = [ "sops-nix.service" ];
      Wants = [ "sops-nix.service" ];
    };

    Service = {
      # Script to inject password from SOPS secret into config before starting
      ExecStartPre = let
        injectPassword = pkgs.writeShellScript "qbittorrent-inject-password" ''
          set -e
          CONFIG_DIR="$HOME/.config/qBittorrent"
          CONFIG_FILE="$CONFIG_DIR/qBittorrent.conf"
          PASSWORD_FILE="${config.sops.secrets.qbittorrent_webui_password.path}"

          # Wait for config file to exist (home-manager creates it)
          while [ ! -f "$CONFIG_FILE" ]; do
            sleep 0.1
          done

          # Read password hash from secret
          PASSWORD_HASH=$(cat "$PASSWORD_FILE")

          # Update config with password hash using sed
          sed -i "s|^WebUI\\\\Password_PBKDF2=.*|WebUI\\\\Password_PBKDF2=\"$PASSWORD_HASH\"|" "$CONFIG_FILE"
        '';
      in "+${injectPassword}";
    };
  };
}
