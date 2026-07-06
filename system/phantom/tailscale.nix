# Phantom USB - System-level Tailscale auto-connect
# Uses auth key embedded on /persist during USB creation
# No runtime YubiKey needed - LUKS encryption protects the key at rest
{ config, lib, pkgs, ... }:

{
  # Override the base tailscale-autoconnect from system/network/tailscale.nix
  # Use mkForce to replace the empty stub with actual auto-connect logic
  systemd.services.tailscale-autoconnect = {
    description = lib.mkForce "Automatic Tailscale connection on boot";
    after = lib.mkForce [ "network-online.target" "tailscaled.service" ];
    wants = lib.mkForce [ "network-online.target" "tailscaled.service" ];

    serviceConfig = {
      RemainAfterExit = true;
    };

    script = lib.mkForce ''
      sleep 2

      status=$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null | \
               ${pkgs.jq}/bin/jq -r '.BackendState' 2>/dev/null || echo "Unknown")

      if [ "$status" = "Running" ]; then
        echo "Tailscale already connected"
        exit 0
      fi

      AUTH_KEY_FILE="/persist/secrets/tailscale-authkey"

      if [ ! -f "$AUTH_KEY_FILE" ]; then
        echo "ERROR: Tailscale auth key not found at $AUTH_KEY_FILE"
        exit 1
      fi

      AUTH_KEY=$(cat "$AUTH_KEY_FILE")
      HOSTNAME="phantom-$(date +%m%d-%H%M)"

      echo "Connecting to Tailscale as $HOSTNAME..."
      ${pkgs.tailscale}/bin/tailscale up \
        --authkey="$AUTH_KEY" \
        --hostname="$HOSTNAME" \
        --accept-routes \
        --reset

      echo "Tailscale connected as $HOSTNAME"
    '';
  };
}
