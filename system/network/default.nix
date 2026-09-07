{ config, lib, pkgs, ... }:

let
  # ── Split-horizon zones ────────────────────────────────────────────────────
  # Names that must be answered by the resolver the *local* network hands out
  # (the homelab router at home), never by Quad9. `home.arpa` is RFC 8375
  # local-only; the two public zones are split-horizon — the authoritative
  # public answer points at the WAN, the LAN view points at the internal host.
  splitHorizonZones = [
    "home.arpa"
    "oolongtechnologies.io"
    "buduroiu.com"
  ];

  # A leading `~` marks a *routing-only* domain: it steers which resolver scope
  # answers the name, without adding the zone to the search list (so a bare
  # `foo` never becomes `foo.buduroiu.com`). resolved picks the scope whose
  # configured domain is the longest match, so `~buduroiu.com` on a link beats
  # the global scope's Quad9 servers for that subtree and nothing else.
  routingDomains = map (zone: "~${zone}") splitHorizonZones;

  # NetworkManager cannot express this declaratively: the `[connection]`
  # defaults section only honours the whitelist in NetworkManager.conf(5)
  # (`ipv4.dns-priority`, `ipv4.route-metric`, …) — `ipv4.dns-search` is not on
  # it, and per-connection profiles are runtime state, not Nix. So pin the
  # domains from a dispatcher hook, which fires on every activation and DHCP
  # renew and therefore survives reboots and roaming.
  pinSplitHorizonDns = pkgs.writeShellApplication {
    name = "pin-split-horizon-dns";
    runtimeInputs = [ pkgs.systemd pkgs.gnused ];
    text = ''
      action="''${2:-}"

      case "$action" in
        up | dhcp4-change | dhcp6-change) ;;
        *) exit 0 ;;
      esac

      # Deliberately re-pin EVERY link, not just "$1". NM's systemd-resolved
      # backend re-pushes SetLinkDomains for all links whenever its view of DNS
      # changes, so bringing up wifi silently wipes the domains pinned on
      # ethernet — and no dispatcher event fires for that link.
      #
      # The regex only matches links that already have at least one server: a
      # scope with routing domains but no resolver is a black hole, because
      # resolved sends matching names there and never falls back to the global
      # (Quad9) scope. Serverless links (wg0 when idle) are skipped.
      links=$(resolvectl dns \
        | sed -n 's/^Link [0-9]\+ (\([^)]\+\)): \+.\+$/\1/p') || true

      for link in $links; do
        current=$(resolvectl domain "$link" | sed 's/^[^:]*: *//') || true

        # A full-tunnel VPN link claims `~.`, i.e. every name. Adding our zones
        # there would make two scopes match equally, and resolved fans equal
        # matches out in parallel — leaking internal names to the VPN resolver
        # and racing its public answer against the LAN one.
        case " $current " in
          *" ~. "*) continue ;;
        esac

        merged="$current"
        for domain in ${lib.escapeShellArgs routingDomains}; do
          case " $merged " in
            *" $domain "*) ;;
            *) merged="''${merged:+$merged }$domain" ;;
          esac
        done

        if [ "$merged" = "$current" ]; then
          continue
        fi

        # Word splitting is the point: one argument per domain.
        # shellcheck disable=SC2086
        resolvectl domain "$link" $merged
        echo "pin-split-horizon-dns: $link -> $merged"
      done
    '';
  };
in
{
  networking = {
    nameservers = [
      "9.9.9.9#dns.quad9.net"
      "149.112.112.112#dns.quad9.net"
    ];

    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      wifi.powersave = true;
      connectionConfig = {
        # NB: `ipv4.ignore-auto-dns` used to live here. NetworkManager silently
        # ignores it in this section (see NetworkManager.conf(5) for the list of
        # properties a connection default may set), so it never took effect —
        # and the split-horizon pinning below now *depends* on the DHCP-supplied
        # resolver reaching the link. Do not reintroduce it.
      };

      dispatcherScripts = [
        {
          source = "${pinSplitHorizonDns}/bin/pin-split-horizon-dns";
          type = "basic";
        }
      ];
    };
  };

  services = {
    resolved = {
      enable = true;
      settings.Resolve = {
        DNSOverTLS = "opportunistic";
        FallbackDNS = [
          "1.1.1.1#cloudflare-dns.com"
          "8.8.8.8#dns.google"
        ];
      };
    };
  };
}
