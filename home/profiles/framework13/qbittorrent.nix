{ config, lib, pkgs, self, ... }:

let
  secretsFile = "${self}/secrets/framework13/qbittorrent.yaml";
in {
  # Install qBittorrent package
  home.packages = [ pkgs.qbittorrent-nox ];

  # SOPS secrets configuration for qBittorrent WebUI authentication
  sops = {
    age.keyFile = "/home/bogdan/.config/sops/age/keys.txt";
    secrets = {
      qbittorrent_webui_password = {
        sopsFile = secretsFile;
      };
    };
  };

  # qBittorrent systemd service with SOPS secret injection
  # Note: qBittorrent requires a PBKDF2 hash, not plaintext
  # Generate hash with: qbittorrent-nox --webui-port=9091 (then check config for hash)
  # Or use Python: from hashlib import pbkdf2_hmac; import base64; ...

  systemd.user.services.qbittorrent = {
    Unit = {
      Description = "qBittorrent-nox BitTorrent Client";
      After = [ "network.target" "sops-nix.service" ];
      Wants = [ "sops-nix.service" ];
    };

    Service = {
      Type = "simple";

      # Script to inject password from SOPS secret into config before starting
      ExecStartPre = let
        injectPassword = pkgs.writeShellScript "qbittorrent-inject-password" ''
          set -e
          CONFIG_DIR="$HOME/.config/qBittorrent"
          CONFIG_FILE="$CONFIG_DIR/qBittorrent.conf"
          PASSWORD_FILE="${config.sops.secrets.qbittorrent_webui_password.path}"

          # Create config directory if it doesn't exist
          mkdir -p "$CONFIG_DIR"

          # Wait for config file to exist or create minimal one
          if [ ! -f "$CONFIG_FILE" ]; then
            cat > "$CONFIG_FILE" << 'EOF'
[Preferences]
WebUI\Port=9091
EOF
          fi

          # Read password hash from secret
          PASSWORD_HASH=$(cat "$PASSWORD_FILE")

          # Update config with password hash using sed
          sed -i "s|^WebUI\\\\Password_PBKDF2=.*|WebUI\\\\Password_PBKDF2=\"$PASSWORD_HASH\"|" "$CONFIG_FILE"
        '';
      in "+${injectPassword}";

      ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --confirm-legal-notice";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
