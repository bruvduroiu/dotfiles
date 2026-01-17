# Tailscale auto-authentication for live ISO (user session)
# Runs after graphical login so pinentry-qt can prompt for YubiKey PIN
{ config, pkgs, self, ... }:

let
  secretsFile = "${self}/secrets/iso/tailscale.yaml";
in {
  # Systemd user service to authenticate Tailscale after graphical login
  systemd.user.services.tailscale-autoconnect = {
    Unit = {
      Description = "Authenticate to Tailscale with YubiKey-decrypted auth key";
      # Run after graphical session is ready (pinentry-qt needs display)
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      RemainAfterExit = true;

      # Environment for pinentry and age-plugin-yubikey
      Environment = [
        "PINENTRY_PROGRAM=${pkgs.pinentry-qt}/bin/pinentry-qt"
      ];

      ExecStart = pkgs.writeShellScript "tailscale-autoconnect" ''
        set -euo pipefail

        echo "Tailscale auto-connect: checking status..."

        # Check if already authenticated
        status="$(${pkgs.tailscale}/bin/tailscale status -json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.BackendState' 2>/dev/null || echo 'Unknown')"

        if [ "$status" = "Running" ]; then
          echo "Tailscale already running, skipping authentication"
          exit 0
        fi

        echo "Tailscale auto-connect: decrypting auth key..."
        echo "You may be prompted for your YubiKey PIN..."

        # Decrypt the auth key using sops
        # This will trigger pinentry-qt for the YubiKey PIV PIN
        AUTH_KEY="$(${pkgs.sops}/bin/sops -d --extract '["tailscale_auth_key"]' ${secretsFile} 2>/dev/null)" || {
          echo "ERROR: Failed to decrypt Tailscale auth key"
          echo "Make sure your YubiKey is connected and try: tailscale up"
          # Send desktop notification
          ${pkgs.libnotify}/bin/notify-send -u critical "Tailscale" "Failed to decrypt auth key. Run 'tailscale up' manually."
          exit 1
        }

        if [ -z "$AUTH_KEY" ]; then
          echo "ERROR: Auth key is empty"
          exit 1
        fi

        echo "Tailscale auto-connect: authenticating..."
        ${pkgs.tailscale}/bin/tailscale up --authkey="$AUTH_KEY" --operator=nixos

        echo "Tailscale authenticated successfully!"
        ${pkgs.libnotify}/bin/notify-send -u normal "Tailscale" "Connected to Tailscale network"
      '';
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Ensure required packages are available
  home.packages = with pkgs; [
    age-plugin-yubikey
    sops
    libnotify
  ];
}
