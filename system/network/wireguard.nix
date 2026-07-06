# WireGuard peer module: home hub + Mullvad split tunnel with kill switch.
#
# Design: docs/superpowers/specs/2026-07-05-wireguard-mullvad-design.md
#
# Each mobile peer runs two interfaces:
#   wg0          → home hub (OpenWRT) for LAN/overlay access
#   wg-mullvad   → Mullvad relay for internet egress
#
# Per-host values (overlay IP, Mullvad addresses) are set in
# hosts/<host>/default.nix via the network.wireguard options below.
#
# Split tunnel / kill switch — pure policy routing, no packet marking:
#   Both WG sockets carry fwmark 51820 (wg-quick's standard full-tunnel
#   mechanism). Three RPDB rules, placed after Tailscale's legacy range:
#
#     pref 5401  fwmark 51820 → main      encapsulated tunnel packets take
#                                         the physical default route; makes
#                                         endpoint exclusion automatic (no
#                                         hardcoded relay/hub IPs)
#     pref 5402  main, suppress_prefixlength 0
#                                         any specific route wins: connected
#                                         LAN, wg0 nets (metric 4000), DHCP
#                                         option-121 routes. Only the default
#                                         route is suppressed.
#     pref 5403  → table 2468             everything else: wg-mullvad default
#                                         (metric 50, added by postUp) or the
#                                         permanent "unreachable" fallback
#                                         (metric 100) — fail closed when the
#                                         tunnel is down for ANY reason.
#
#   Captive portal escape hatch: `systemctl stop mullvad-killswitch`
#   (stop propagates to wg-quick-wg-mullvad via Requires=). Start
#   wg-quick-wg-mullvad again once authenticated.
#
# Required secrets (inputs.secrets: secrets/<hostname>/wireguard.yaml, via sops):
#   wg-private-key:        <WireGuard private key for wg0>
#   mullvad-private-key:   <Mullvad WireGuard private key>

{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.network.wireguard;

  hostName = config.networking.hostName;
  sopsFile = "${inputs.secrets}/secrets/${hostName}/wireguard.yaml";
  wgSecret = "wg-private-key";
  mullvadSecret = "mullvad-private-key";

  # Endpoints, keys, and network topology live in the private flake's vars
  pvars = inputs.secrets.vars.wireguard;

  # ── Hub config ──────────────────────────────────────────────────────────────
  hubEndpoint = pvars.hub.endpoint;
  hubPublicKey = pvars.hub.publicKey;

  # Networks reachable through the home hub via wg0
  hubNetworks = pvars.hub.networks;

  # ── Mullvad config ──────────────────────────────────────────────────────────
  # Pick a region from https://mullvad.net/en/servers/
  mullvadEndpoint = pvars.mullvad.endpoint;
  mullvadPublicKey = pvars.mullvad.publicKey;
  # In-tunnel resolver: no specific route in main → rule 5403 → tunnel.
  mullvadDNS = pvars.mullvad.dns;

  # ── Split tunnel constants ──────────────────────────────────────────────────
  wgFwmark = 51820;       # on both WG sockets; matched by rule 5401
  tableId = 2468;         # Mullvad egress table (default + unreachable)
  ip = "${pkgs.iproute2}/bin/ip";
in {
  options.network.wireguard = {
    overlayIP = lib.mkOption {
      type = lib.types.str;
      example = "10.99.0.2";
      description = "This host's address on the 10.99.0.0/24 home overlay.";
    };
    mullvadAddressV4 = lib.mkOption {
      type = lib.types.str;
      example = "10.72.215.171/32";
      description = ''
        Mullvad in-tunnel IPv4 address (CIDR). Bound to this host's Mullvad
        device key — update together with the key when rotating.
      '';
    };
    mullvadAddressV6 = lib.mkOption {
      type = lib.types.str;
      example = "fc00:bbbb:bbbb:bb01::9:d7aa/128";
      description = "Mullvad in-tunnel IPv6 address (CIDR). Key-bound, like V4.";
    };
  };

  config = {
    # ── Secrets ──────────────────────────────────────────────────────────────
    sops.secrets.${wgSecret} = {
      inherit sopsFile;
      mode = "0400";
      owner = "root";
    };
    sops.secrets.${mullvadSecret} = {
      inherit sopsFile;
      mode = "0400";
      owner = "root";
    };

    # ── Firewall ─────────────────────────────────────────────────────────────
    networking.firewall = {
      # rp_filter must be OFF entirely: kernel reverse-path validation does
      # its FIB lookup with iif=lo, so it hits the kill switch rule (pref
      # 5403) and sees "unreachable" for any non-LAN source while wg-mullvad
      # is down — silently dropping inbound wg0 replies (fail-closed egress
      # table and rp_filter are fundamentally incompatible). WireGuard
      # authenticates sources cryptographically, which is stronger than
      # route symmetry.
      checkReversePath = false;
      # Only the home overlay is trusted. wg-mullvad is an internet egress
      # path — inbound traffic from it goes through the normal firewall.
      trustedInterfaces = [ "wg0" ];
    };

    # Belt for checkReversePath=false: kernel takes max(all, per-interface),
    # and per-interface values inherit from `default` at interface creation —
    # stale 2s survive rebuilds on live interfaces (bit us on the USB dock
    # NIC). Pin both so every boot and every hotplugged interface starts at 0.
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.rp_filter" = 0;
      "net.ipv4.conf.default.rp_filter" = 0;
    };

    # ── WireGuard interfaces ─────────────────────────────────────────────────
    networking.wg-quick.interfaces = {
      # Home hub overlay
      wg0 = {
        address = [ "${cfg.overlayIP}/32" ];
        privateKeyFile = config.sops.secrets.${wgSecret}.path;
        mtu = 1360;
        # Routes are added manually with a high metric so that, at home, the
        # directly-connected LAN route (NM metric ~100-600) and the DHCP
        # option-121 routes win and traffic stays off the tunnel. Away from
        # home these are the only routes for hub networks, so wg0 is used.
        table = "off";
        postUp = ''
          ${pkgs.wireguard-tools}/bin/wg set wg0 fwmark ${toString wgFwmark}
          ${lib.concatMapStringsSep "\n"
            (net: "${ip} route replace ${net} dev wg0 metric 4000")
            hubNetworks}
        '';
        peers = [
          {
            publicKey = hubPublicKey;
            allowedIPs = hubNetworks;
            endpoint = hubEndpoint;
            persistentKeepalive = 25;
          }
        ];
      };

      # Mullvad internet egress
      "wg-mullvad" = {
        address = [ cfg.mullvadAddressV4 cfg.mullvadAddressV6 ];
        privateKeyFile = config.sops.secrets.${mullvadSecret}.path;
        mtu = 1280;
        # Never touch the main routing table — egress is owned by the policy
        # rules (mullvad-killswitch). NetworkManager keeps the default route.
        table = "off";
        # Tunnel default routes sit at metric 50, below the permanent
        # unreachable fallback (metric 100) installed by the kill switch.
        postUp = ''
          ${pkgs.wireguard-tools}/bin/wg set wg-mullvad fwmark ${toString wgFwmark}
          ${ip} route replace default dev wg-mullvad metric 50 table ${toString tableId}
          ${ip} -6 route replace default dev wg-mullvad metric 50 table ${toString tableId}
        '';
        preDown = ''
          ${ip} route del default dev wg-mullvad table ${toString tableId} 2>/dev/null || true
          ${ip} -6 route del default dev wg-mullvad table ${toString tableId} 2>/dev/null || true
        '';
        peers = [
          {
            publicKey = mullvadPublicKey;
            allowedIPs = [ "0.0.0.0/0" "::/0" ];
            endpoint = mullvadEndpoint;
          }
        ];
      };
    };

    # ── Kill switch (persistent, fail-closed) ────────────────────────────────
    # Pure RPDB — no nftables, no address lists, nothing to keep in sync.
    # Independent of the wg-quick unit lifecycle: rules and the unreachable
    # fallback survive tunnel crashes and restarts.
    systemd.services.mullvad-killswitch = {
      description = "Mullvad kill switch (policy routing, fail closed)";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-pre.target" ];
      before = [ "network-pre.target" ];
      path = [ pkgs.iproute2 ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        for fam in -4 -6; do
          # Encapsulated WG packets → physical default route
          ip $fam rule del pref 5401 2>/dev/null || true
          ip $fam rule add pref 5401 fwmark ${toString wgFwmark} lookup main
          # Specific routes (LAN, overlay, option-121) win; default suppressed
          ip $fam rule del pref 5402 2>/dev/null || true
          ip $fam rule add pref 5402 lookup main suppress_prefixlength 0
          # Everything else *locally generated*: Mullvad or fail closed.
          # `iif lo` matches output route lookups only — it does NOT exempt
          # kernel reverse-path lookups (those also use iif=lo), hence
          # checkReversePath=false above.
          ip $fam rule del pref 5403 2>/dev/null || true
          ip $fam rule add pref 5403 iif lo lookup ${toString tableId}
          ip $fam route replace unreachable default metric 100 table ${toString tableId}
        done
      '';
      # Stopping the unit restores normal routing (captive portal escape
      # hatch); Requires= below also stops the Mullvad tunnel with it.
      preStop = ''
        for fam in -4 -6; do
          ip $fam rule del pref 5401 2>/dev/null || true
          ip $fam rule del pref 5402 2>/dev/null || true
          ip $fam rule del pref 5403 2>/dev/null || true
          ip $fam route flush table ${toString tableId} 2>/dev/null || true
        done
      '';
    };

    # Never run the Mullvad tunnel without the kill switch: if the kill
    # switch fails to install, the tunnel does not come up (and traffic
    # visibly has no VPN) instead of silently egressing via the physical
    # uplink.
    systemd.services."wg-quick-wg-mullvad" = {
      requires = [ "mullvad-killswitch.service" ];
      after = [ "mullvad-killswitch.service" ];
    };

    # ── DNS ──────────────────────────────────────────────────────────────────
    # Mullvad DNS for everything, replacing Tailscale's MagicDNS.
    # Local hostnames resolved via /etc/hosts (networking.hosts).
    networking.hosts = pvars.overlayHosts;

    # Push .home.arpa as a search domain so `ssh openwrt` resolves.
    networking.search = [ "home.arpa" ];

    # systemd-resolved: Mullvad in-tunnel DNS (plain :53 — already encrypted
    # by the WG tunnel; it is not a DoT endpoint, so no hostname pin).
    # FallbackDNS stays as a safety net (queries will fail anyway via kill
    # switch if the tunnel is down — no leak).
    services.resolved.settings.Resolve = {
      DNS = [ mullvadDNS ];
      FallbackDNS = [
        "1.1.1.1#cloudflare-dns.com"
        "8.8.8.8#dns.google"
      ];
      DNSOverTLS = "opportunistic";
    };
  };
}
