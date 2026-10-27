# WireGuard peer module: home hub + optional Mullvad split tunnel (NO kill switch).
#
# Design: docs/superpowers/specs/2026-07-05-wireguard-mullvad-design.md
#
# A mobile peer runs up to two interfaces:
#   wg0          → home hub (OpenWRT) for LAN/overlay access   [always]
#   wg-mullvad   → Mullvad relay for internet egress           [opt-in]
#
# Per-host values (overlay IP, Mullvad addresses) are set in
# hosts/<host>/default.nix via the network.wireguard options below.
#
# Hosts that only want the home overlay set `network.wireguard.mullvad.enable
# = false` (steamdeck). That is not merely cosmetic: it also stops the module
# declaring `mullvad-private-key`. sops-install-secrets is all-or-nothing, so a
# key named here but missing from the host's YAML fails the whole activation
# and wg0's key never reaches /run/secrets either — the host drops off the
# overlay because of a tunnel it was never meant to run.
#
# Split tunnel — pure policy routing, no packet marking, FAILS OPEN:
#   Both WG sockets carry fwmark 51820 (wg-quick's standard full-tunnel
#   mechanism). Three RPDB rules, added by wg-mullvad's own postUp (torn
#   down by preDown), placed after Tailscale's legacy range:
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
#                                         (metric 50, added by postUp).
#
#   NO fail-closed fallback: when wg-mullvad goes down (clean or crash) its
#   routes/rules disappear, table 2468 empties, and traffic falls through to
#   the physical default route — i.e. it LEAKS your real IP/DNS. This is
#   deliberate: tunnel availability is not enforced. Captive portals therefore "just work" with the tunnel down.
#
# Relay selection — symbolic, resolved at every interface start:
#   Mullvad retires relays and rotates their keys, so a pinned endpoint+key is
#   a value that decays. Combined with fail-open that is the nastiest failure
#   available: the interface comes up, handshakes with nobody, and traffic
#   quietly takes the physical default route. What is stored instead is a
#   relay-hostname PREFIX ("se", "se-got", "se-got-wg-001") — in
#   /var/lib/mullvad-jump/pin, or `vars.wireguard.mullvad.relay` as the
#   per-host default — which postUp resolves against the live catalog via
#   `mullvad-jump apply`, trying successive relays until one handshakes.
#   Switch and persist with `mullvad-jump <prefix>` (or `pick`); inspect with
#   `mullvad-jump status`, which names a retired relay explicitly.
#
# Required secrets (inputs.secrets: secrets/<hostname>/wireguard.yaml, via sops):
#   wg-private-key:        <WireGuard private key for wg0>
#   mullvad-private-key:   <Mullvad WireGuard private key>

{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.network.wireguard;
  mullvadEnabled = cfg.mullvad.enable;

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

  # The hub's resolver (the router's dnsmasq), reached through wg0 — optional
  # in the private flake. It is bound to the wg0 LINK for the private
  # subdomain alone, as a routing-only domain, so every other name keeps
  # resolving exactly as before (Quad9 / Mullvad). `local.buduroiu.com` is
  # NXDOMAIN publicly: it exists only in the router's dnsmasq (homelab repo,
  # modules/local-ingress.nix), so away from home the tunnel is the only path
  # to an answer. resolved prefers the longest matching routing domain, so
  # `~local.buduroiu.com` here beats the dispatcher's `~buduroiu.com` on the
  # uplinks and Mullvad's `~.`.
  hubDNS = pvars.hub.dns or null;
  hubDNSDomains = [ "~local.buduroiu.com" ];

  # ── Mullvad config ──────────────────────────────────────────────────────────
  # OPTIONAL, AND BETTER LEFT UNSET. A relay's endpoint and public key are
  # Mullvad's to change: keys rotate while the IP stays put, so a pinned pair
  # can be half-correct and permanently dead. Declaring them here also means
  # every relay change costs two commits across two repos. Omit both and the
  # interface starts with NO peer at all, leaving `mullvad-jump apply` in
  # postUp as the single source of peer identity — switching exits is then one
  # command, no commit and no rebuild.
  mullvadEndpoint = pvars.mullvad.endpoint or null;
  mullvadPublicKey = pvars.mullvad.publicKey or null;

  # Symbolic relay preference — a relay-hostname prefix at country ("se"),
  # city ("se-got") or exact ("se-got-wg-001") granularity, resolved against
  # Mullvad's live catalog at every interface start. Optional in the private
  # flake: without it the pin in /var/lib/mullvad-jump/pin (written by
  # `mullvad-jump <prefix>`) is the only source, and failing that the bootstrap
  # peer above is left in place.
  defaultRelay = pvars.mullvad.relay or "";

  mullvadJump = "${pkgs.mullvad-jump}/bin/mullvad-jump";
  # In-tunnel resolver: no specific route in main → rule 5403 → tunnel.
  mullvadDNS = pvars.mullvad.dns;

  # ── Split tunnel constants ──────────────────────────────────────────────────
  wgFwmark = 51820;       # on both WG sockets; matched by rule 5401
  tableId = 2468;         # Mullvad egress table (default + unreachable)
  ip = "${pkgs.iproute2}/bin/ip";
  resolvectl = "${config.systemd.package}/bin/resolvectl";
in {
  options.network.wireguard = {
    privateKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Runtime home-overlay key path; null uses SOPS, a custom path skips its key declaration.";
    };
    overlayIP = lib.mkOption {
      type = lib.types.str;
      example = "10.99.0.2";
      description = "This host's address on the 10.99.0.0/24 home overlay.";
    };
    backend = lib.mkOption {
      type = lib.types.enum [ "wg-quick" "networkmanager" ];
      default = "wg-quick";
      description = ''
        Which stack owns wg0. Only wg0 — wg-mullvad is always wg-quick,
        because its peer identity is resolved at runtime by `mullvad-jump`
        and a NetworkManager profile can only carry a pinned endpoint+key
        (see the relay-selection note in this file's header).

        "networkmanager" exists for one reason: a NetworkManager *profile* is
        the only form of tunnel that shows up in `nmcli connection show`, and
        therefore the only form the Steam Deck's Gaming Mode VPN plugin
        (TunnelDeck) can list or toggle. wg-quick creates the kernel device
        directly, so NM sees a device with no connection and the plugin's
        `['vpn','wireguard'].includes(type)` filter matches nothing.

        The two backends are not stackable: both would try to create wg0.
      '';
    };
    mullvad.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to bring up the wg-mullvad egress tunnel alongside wg0.

        Off means the host keeps ONLY the home overlay: no wg-mullvad
        interface, no egress policy routing, and — the part that matters
        operationally — no `mullvad-private-key` sops secret, so the host's
        wireguard.yaml is not required to carry one.
      '';
    };
    mullvadAddressV4 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "10.72.215.171/32";
      description = ''
        Mullvad in-tunnel IPv4 address (CIDR). Bound to this host's Mullvad
        device key — update together with the key when rotating. Required
        only when mullvad.enable is on.
      '';
    };
    mullvadAddressV6 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "fc00:bbbb:bbbb:bb01::9:d7aa/128";
      description = "Mullvad in-tunnel IPv6 address (CIDR). Key-bound, like V4.";
    };
  };

  config = {
    # A half-configured Mullvad tunnel is the worst outcome available here:
    # the address is key-bound, so a placeholder handshakes fine and then
    # silently drops every packet (this exact fault cost an evening during the
    # 2026-07-05 rotation). Fail at eval instead.
    assertions = [
      {
        assertion = mullvadEnabled ->
          (cfg.mullvadAddressV4 != null && cfg.mullvadAddressV6 != null);
        message = ''
          network.wireguard.mullvad.enable is on for ${hostName} but
          mullvadAddressV4/mullvadAddressV6 are unset. Take both from this
          host's own Mullvad device config (they are bound to its device key),
          or set network.wireguard.mullvad.enable = false for a host that only
          needs the home overlay.
        '';
      }
      {
        # The NM backend feeds the key through a sops *template* (an env file
        # consumed by envsubst), not through a key path handed to wg-quick.
        # A host that supplies its own privateKeyFile — phantom, whose key
        # lives on /persist rather than in sops — has no placeholder to render.
        assertion = (cfg.backend == "networkmanager") -> (cfg.privateKeyFile == null);
        message = ''
          network.wireguard.backend = "networkmanager" on ${hostName} requires
          the sops-provided key: the profile is rendered by envsubst from a
          sops template, so there is nothing to substitute when
          network.wireguard.privateKeyFile points at a file instead.
        '';
      }
      {
        assertion = (cfg.backend == "networkmanager")
          -> config.networking.networkmanager.enable;
        message = ''
          network.wireguard.backend = "networkmanager" on ${hostName} but
          networking.networkmanager.enable is off — nothing would create wg0.
        '';
      }
    ];

    # ── Secrets ──────────────────────────────────────────────────────────────
    # Declared per enabled interface, never unconditionally: see the header
    # note on sops-install-secrets being all-or-nothing.
    sops.secrets = lib.optionalAttrs (cfg.privateKeyFile == null) {
      ${wgSecret} = {
        inherit sopsFile;
        mode = "0400";
        owner = "root";
      };
    } // lib.optionalAttrs mullvadEnabled {
      ${mullvadSecret} = {
        inherit sopsFile;
        mode = "0400";
        owner = "root";
      };
    };

    # ── Firewall ─────────────────────────────────────────────────────────────
    networking.firewall = {
      # rp_filter stays OFF: kernel reverse-path validation does its FIB
      # lookup with iif=lo, so it hits the egress rules (pref 5403 → table
      # 2468) and can see an asymmetric path for the Mullvad tunnel, dropping
      # legitimate inbound wg0 replies. WireGuard authenticates sources
      # cryptographically, which is stronger than route symmetry anyway.
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
    networking.wg-quick.interfaces = lib.optionalAttrs (cfg.backend == "wg-quick") {
      # Home hub overlay
      wg0 = {
        address = [ "${cfg.overlayIP}/32" ];
        privateKeyFile = if cfg.privateKeyFile == null
          then config.sops.secrets.${wgSecret}.path else cfg.privateKeyFile;
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
        '' + lib.optionalString (hubDNS != null) ''
          ${resolvectl} dns wg0 ${hubDNS}
          ${resolvectl} domain wg0 ${lib.concatStringsSep " " hubDNSDomains}
        '';
        preDown = lib.optionalString (hubDNS != null) ''
          ${resolvectl} revert wg0 2>/dev/null || true
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
    } // lib.optionalAttrs mullvadEnabled {

      # Mullvad internet egress
      "wg-mullvad" = {
        address = [ cfg.mullvadAddressV4 cfg.mullvadAddressV6 ];
        privateKeyFile = config.sops.secrets.${mullvadSecret}.path;
        mtu = 1280;
        # Never touch the main routing table — egress is owned by the policy
        # rules below. NetworkManager keeps the physical default route, which
        # is what traffic falls back to (leaks) when this interface is down.
        table = "off";
        # postUp installs the egress policy: fwmark on the socket, the three
        # RPDB rules, and the tunnel default in table 2468 (metric 50, sole
        # entry — no unreachable fallback, so the table empties when the
        # interface dies and traffic fails open). Rules are del-then-add so
        # restarts don't stack duplicates.
        postUp = ''
          ${pkgs.wireguard-tools}/bin/wg set wg-mullvad fwmark ${toString wgFwmark}

          # Stale-rule teardown runs BEFORE the resolver, not paired with each
          # add below, and the order is load-bearing: `mullvad-jump apply` has
          # to reach api.mullvad.net, and if rules from a crashed run survived,
          # pref 5403 would route its fetch into the very tunnel it is trying
          # to configure — a deadlock that resolves only by timeout. Clearing
          # first guarantees the resolver always sees the physical uplink.
          for fam in -4 -6; do
            ${ip} $fam rule del pref 5401 2>/dev/null || true
            ${ip} $fam rule del pref 5402 2>/dev/null || true
            ${ip} $fam rule del pref 5403 2>/dev/null || true
          done

          # Replace the bootstrap peer with one resolved from Mullvad's live
          # catalog, so a retired relay or rotated key self-heals on restart.
          #
          # The exit status GATES everything below, and that gate is the whole
          # point: rules 5401-5403 pull every route into this interface, so
          # installing them around a peer that cannot handshake does not "fail
          # open" — it blackholes the machine completely. Fail-open has to mean
          # "no verified relay ⇒ no egress policy", not merely "no interface ⇒
          # no egress policy". Guarding with `if` also keeps a nonzero status
          # from tripping wg-quick's `set -e` and tearing the interface down.
          if ${mullvadJump} apply ${lib.escapeShellArg defaultRelay}; then
            for fam in -4 -6; do
              ${ip} $fam rule add pref 5401 fwmark ${toString wgFwmark} lookup main
              ${ip} $fam rule add pref 5402 lookup main suppress_prefixlength 0
              ${ip} $fam rule add pref 5403 iif lo lookup ${toString tableId}
            done
            ${ip} route replace default dev wg-mullvad metric 50 table ${toString tableId}
            ${ip} -6 route replace default dev wg-mullvad metric 50 table ${toString tableId}
            # DNS: pin the Mullvad resolver to THIS link and claim the ~.
            # routing domain. resolved routes each query to the scope with the
            # best matching domain; ~. outranks the NM uplinks' bare
            # DefaultRoute flag, so their DHCP (ISP) resolvers stop receiving
            # queries while the tunnel is up. Without ~., resolved fans every
            # query out to ALL default-route scopes in parallel — global DNS=
            # does not exclude per-link servers, which is exactly the leak.
            # Per-link resolved state dies with the interface (crash included),
            # so DNS fails open together with the routes above.
            ${resolvectl} dns wg-mullvad ${mullvadDNS}
            ${resolvectl} domain wg-mullvad "~."
          else
            echo "wg-mullvad: no verified relay — egress policy NOT installed;" >&2
            echo "traffic stays on the physical uplink. Fix: mullvad-jump <prefix>" >&2
          fi
        '';
        preDown = ''
          ${resolvectl} revert wg-mullvad 2>/dev/null || true
          for fam in -4 -6; do
            ${ip} $fam rule del pref 5401 2>/dev/null || true
            ${ip} $fam rule del pref 5402 2>/dev/null || true
            ${ip} $fam rule del pref 5403 2>/dev/null || true
            ${ip} $fam route flush table ${toString tableId} 2>/dev/null || true
          done
        '';
        # Empty unless the private flake still pins a relay. An interface with
        # no peers comes up fine and simply carries nothing until postUp
        # resolves one — which is strictly better than starting with a peer
        # that is probably stale, because "no peer" cannot masquerade as a
        # working tunnel.
        peers = lib.optional (mullvadEndpoint != null && mullvadPublicKey != null) {
          publicKey = mullvadPublicKey;
          allowedIPs = [ "0.0.0.0/0" "::/0" ];
          endpoint = mullvadEndpoint;
          # Without a keepalive the tunnel only handshakes once something
          # routes into it, so "idle" and "dead relay" look identical — both
          # to mullvad-jump's post-configure verification.
          # 25s also keeps the NAT mapping open. mullvad-jump sets the same
          # value on every peer it installs.
          persistentKeepalive = 25;
        };
      };
    };

    # ── Boot ordering against YubiKey-backed sops ────────────────────────────
    # The initrd cannot decrypt (no pcscd — see system/core/sops.nix), so at
    # boot the keys only appear once sops-install-secrets-yubikey succeeds.
    # Without this, wg-quick starts first, `wg set … private-key` fails inside
    # postUp, and the unit still reports active: routes installed, no
    # identity, every packet to the hub silently dropped. Registering as a
    # consumer orders each tunnel after the decrypt, skips it while its key
    # is missing, and starts it once a late decrypt succeeds.
    yubikeySops.consumers = lib.mapAttrs'
      (name: iface: lib.nameValuePair "wg-quick-${name}" iface.privateKeyFile)
      config.networking.wg-quick.interfaces;

    # ── wg0 as a NetworkManager profile (backend = "networkmanager") ─────────
    # Same tunnel as the wg-quick wg0 above, expressed as an NM keyfile so it
    # appears in `nmcli connection show` — see the `backend` option's docs.
    #
    # The key never reaches persistent storage. NixOS renders these profiles
    # from a systemd unit that runs envsubst into
    # /run/NetworkManager/system-connections (tmpfs, UMask 0177), substituting
    # from EnvironmentFile; that file is itself a sops template under
    # /run/secrets. So the chain is sops → tmpfs env file → tmpfs keyfile.
    #
    # DO NOT edit this profile with `nmcli connection modify` (TunnelDeck's
    # "Disable IPv6" button does exactly that): NM responds by copying the
    # profile — substituted private key and all — into
    # /etc/NetworkManager/system-connections, which both defeats the tmpfs
    # property above and leaves two same-named profiles behind. ipv6 is pinned
    # to `disabled` below so there is no reason to press it.
    sops.templates = lib.optionalAttrs (cfg.backend == "networkmanager") {
      "wg0-nm.env" = {
        content = "WG0_PRIVATE_KEY=${config.sops.placeholder.${wgSecret}}";
        mode = "0400";
        owner = "root";
      };
    };

    networking.networkmanager.ensureProfiles =
      lib.mkIf (cfg.backend == "networkmanager") {
        environmentFiles = [ config.sops.templates."wg0-nm.env".path ];
        profiles.wg0 = {
          connection = {
            id = "wg0";
            type = "wireguard";
            interface-name = "wg0";
            # The overlay is this host's reason to be reachable; bring it up
            # unattended. The Gaming Mode plugin can still take it down.
            autoconnect = true;
          };
          wireguard = {
            private-key = "$WG0_PRIVATE_KEY";
            # 0 = the key is stored in the profile (no agent, no prompt).
            # Gaming Mode has no secret agent to answer one.
            private-key-flags = 0;
            fwmark = wgFwmark;
            mtu = 1360;
          };
          "wireguard-peer.${hubPublicKey}" = {
            endpoint = hubEndpoint;
            allowed-ips = lib.concatMapStrings (net: "${net};") hubNetworks;
            persistent-keepalive = 25;
          };
          ipv4 = {
            method = "manual";
            address1 = "${cfg.overlayIP}/32";
            # Replaces wg-quick's `table = "off"` + manual metric-4000 routes:
            # NM derives routes from allowed-ips, so the metric is all that is
            # needed for the connected LAN and DHCP option-121 routes to win at
            # home. never-default is belt to the braces — none of hubNetworks
            # is a default route, and neither backend should ever install one.
            route-metric = 4000;
            never-default = true;
            # The overlay must not gate NetworkManager-wait-online: the hub is
            # unreachable until the physical uplink is up.
            may-fail = true;
          } // lib.optionalAttrs (hubDNS != null) {
            # Same split DNS as the wg-quick postUp: NM hands both to resolved
            # as this link's server and routing-only domain.
            dns = "${hubDNS};";
            dns-search = lib.concatMapStrings (d: "${d};") hubDNSDomains;
          };
          # v4-only overlay. Also removes the one setting TunnelDeck offers to
          # change, which is what would clone this profile into /etc.
          ipv6.method = "disabled";
        };
      };

    # ── DNS ──────────────────────────────────────────────────────────────────
    # Mullvad DNS for everything (when enabled), replacing Tailscale's MagicDNS.
    # Local hostnames resolved via /etc/hosts (networking.hosts).
    #
    # Every overlay host also gets its bare label as an alias. The search
    # domain below does NOT cover this: search-domain expansion is a *DNS*
    # mechanism, and nsswitch consults `files` (plain /etc/hosts, literal
    # match on name + aliases) before ever reaching a resolver. So with FQDNs
    # alone, `ping steamdeck.home.arpa` works while `ssh steamdeck` fails to
    # resolve — which reads like the host being down rather than a naming gap.
    networking.hosts = lib.mapAttrs
      (_addr: names: lib.unique (names ++ map (lib.removeSuffix ".home.arpa")
        (lib.filter (lib.hasSuffix ".home.arpa") names)))
      pvars.overlayHosts;

    # Push .home.arpa as a search domain so bare labels also resolve through
    # resolved for anything not pinned in /etc/hosts above.
    networking.search = [ "home.arpa" ];

    # systemd-resolved: the Mullvad in-tunnel resolver (plain :53 — already
    # encrypted by the WG tunnel) is bound to the wg-mullvad LINK in postUp
    # above, together with the ~. routing domain. Deliberately NOT a global
    # DNS= entry here: global servers only join the parallel fan-out next to
    # the uplinks' DHCP servers — they never preempt them, so the ISP still
    # sees every query (the leak this replaces). NB: with no kill switch,
    # when the tunnel is down the uplinks' DHCP resolvers take over — DNS
    # leaks along with the rest of the traffic (by design; check tunnel health explicitly).
    # With mullvad.enable = false none of that applies: there is no in-tunnel
    # resolver to bind, so DNS is whatever system/network/default.nix sets
    # (Quad9 over DoT) and these fallbacks stay as the last resort.
    services.resolved.settings.Resolve = {
      FallbackDNS = [
        "1.1.1.1#cloudflare-dns.com"
        "8.8.8.8#dns.google"
      ];
      DNSOverTLS = "opportunistic";
    };
  };
}
