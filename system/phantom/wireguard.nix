# The LUKS volume protects the boot-time key; no runtime token is needed for wg0.
{ inputs, lib, ... }:
let
  peer = inputs.secrets.vars.hosts.phantom.wireguard or null;
in {
  # Do not borrow another host's identity or invent an address. Once the
  # dedicated peer is provisioned in the private flake, use the shared routing.
  imports = lib.optional (peer != null) ../network/wireguard.nix;

  config = lib.mkMerge [
    {
      warnings = lib.optional (peer == null) ''
        Phantom's WireGuard peer is not provisioned. Add
        vars.hosts.phantom.wireguard.overlayIP in the private flake, register
        its public key on the home hub, and install its root-only private key
        at /persist/secrets/wg-private-key. The home overlay is disabled until then.
      '';
    }
    (lib.optionalAttrs (peer != null) {
      network.wireguard = {
        inherit (peer) overlayIP;
        privateKeyFile = "/persist/secrets/wg-private-key";
        mullvad.enable = false;
      };
      systemd.services.wg-quick-wg0 = {
        # The removable system may boot before Wi-Fi is available. Retry
        # endpoint DNS resolution until the uplink comes up.
        unitConfig.RequiresMountsFor = [ "/persist" ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "10s";
        };
      };
    })
  ];
}
