{
  lib,
  writeShellApplication,
  curl,
  jq,
  wireguard-tools,
  util-linux,
  coreutils,
  fzf,
  gawk,
  gnugrep,
  iproute2,
  systemd,
}:

# Relay manager for the wg-quick "wg-mullvad" interface (see
# system/network/wireguard.nix).
#
# WHY THIS EXISTS IN THIS SHAPE
#
# Mullvad decommissions relays and rotates their WireGuard keys on their own
# schedule. Pinning an endpoint IP + public key in Nix therefore stores a
# value that decays: when the relay goes away, wg-mullvad comes up perfectly,
# handshakes with nobody, and — because the split tunnel fails OPEN — you keep
# browsing with your real IP. Silent, and the worst possible failure mode.
#
# So the pin here is SYMBOLIC, not concrete: a hostname prefix
# ("se", "se-got", "se-got-wg-001") kept in /var/lib/mullvad-jump/pin. The
# concrete endpoint+key are resolved from Mullvad's live catalog at every
# interface start (`apply`, called from the interface's postUp) and at every
# jump. A retired relay can then only cost one resolution, never a silent leak.
#
# The v1 catalog carries no "active" field — Mullvad simply drops dead relays
# from the feed — so PRESENCE IN THE CATALOG IS THE LIVENESS SIGNAL, and a
# resolve that returns nothing is itself the "this relay is gone" alarm.

writeShellApplication {
  name = "mullvad-jump";

  # EVERY external command must be listed. writeShellApplication PREPENDS these
  # to the inherited $PATH rather than replacing it, so a missing entry still
  # resolves in an interactive shell and only fails where PATH is minimal —
  # i.e. under systemd, which is exactly where postUp runs. ShellCheck cannot
  # catch it either. awk/ip/systemctl/grep were missing on the first cut and
  # broke relay resolution at boot while working perfectly by hand.
  runtimeInputs = [
    curl            # catalog fetch
    jq              # catalog parsing
    wireguard-tools # wg set/show
    util-linux      # column
    coreutils       # cat cut date head mkdir mktemp mv rm sleep sort tr
    fzf             # pick
    gawk            # candidates, uplink_dev, handshake_age
    gnugrep         # list/pick filters
    iproute2        # ip route (uplink detection)
    systemd         # systemctl restart
  ];

  text = ''
    RELAY_API="https://api.mullvad.net/public/relays/wireguard/v1"
    IFACE="wg-mullvad"
    STATE=/var/lib/mullvad-jump
    PIN="$STATE/pin"
    CACHE="$STATE/relays.tsv"
    # Candidates tried before giving up. A relay can be listed but sick, so a
    # pin that resolves to several ("se-got") self-heals onto the next one.
    MAX_TRIES=3
    HS_WAIT=4          # seconds to wait for a handshake before trying the next

    usage() {
      cat <<EOF
    usage: mullvad-jump <prefix>        jump to a relay and persist the choice
           mullvad-jump pick [filter]   fuzzy-pick a relay, then jump
           mullvad-jump list [filter]   list relays (city/country/hostname)
           mullvad-jump status          pin, live relay, handshake, exit check
           mullvad-jump reset           forget the pin, revert to the Nix default
           mullvad-jump apply [default] resolve the pin and configure the peer
                                        (run from wg-mullvad's postUp)

    <prefix> is any leading part of a relay hostname, so it selects at three
    granularities — "se" (country), "se-got" (city), "se-got-wg-001" (exact).
    Broader pins survive relay churn better and allow failover between tries.
    EOF
      exit 1
    }

    need_root() { [ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"; }

    # Physical default route, i.e. egress ignoring the tunnel. Read from table
    # main specifically: wg-mullvad is Table=off, so its default never appears
    # there — main is by definition the uplink.
    uplink_dev() {
      ip -4 route show default table main 2>/dev/null \
        | awk '{for (i = 1; i < NF; i++) if ($i == "dev") { print $(i + 1); exit }}'
    }

    # hostname \t country \t city \t ipv4 \t pubkey
    # Network first, cache second. The cache is what makes an offline boot (or
    # a boot where the fetch is slow) configure a peer at all, rather than
    # leaving the interface up and mute.
    catalog() {
      local tmp dev
      local -a bind=()
      tmp=$(mktemp)
      # Pin the fetch to the physical uplink when we have the privilege for
      # SO_BINDTODEVICE. Without it, an unbound socket obeys the RPDB: if the
      # egress rules are live and the peer is stale, the request for the data
      # needed to REPAIR the tunnel is itself routed into that broken tunnel.
      # Best-effort by design — unprivileged callers fall back to the cache.
      if [ "$(id -u)" -eq 0 ]; then
        dev=$(uplink_dev)
        [ -n "$dev" ] && bind=(--interface "$dev")
      fi
      if curl -sf --max-time 8 "''${bind[@]}" "$RELAY_API" 2>/dev/null | jq -r '
            .countries[] as $c | $c.cities[] as $ci | $ci.relays[]
            | [.hostname, $c.name, $ci.name, .ipv4_addr_in, .public_key] | @tsv
          ' > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
        mkdir -p "$STATE" 2>/dev/null || true
        mv "$tmp" "$CACHE" 2>/dev/null || { cat "$tmp"; rm -f "$tmp"; return 0; }
        cat "$CACHE"
        return 0
      fi
      rm -f "$tmp"
      if [ -s "$CACHE" ]; then
        echo "warning: relay catalog unreachable, using cache from $(date -r "$CACHE" '+%Y-%m-%d %H:%M')" >&2
        cat "$CACHE"
        return 0
      fi
      echo "error: relay catalog unreachable and no cache at $CACHE" >&2
      return 1
    }

    # Matches an exact hostname or a dash-delimited prefix, so "se" cannot
    # accidentally match "sea-...". Sorted for deterministic, explainable picks.
    candidates() {
      local pref=$1
      awk -F'\t' -v p="$pref" '$1 == p || index($1, p "-") == 1' | sort
    }

    current_peer() { wg show "$IFACE" peers 2>/dev/null | head -1; }

    handshake_age() {
      local hs now
      hs=$(wg show "$IFACE" latest-handshakes 2>/dev/null | awk 'NR==1 {print $2}')
      [ -n "''${hs:-}" ] && [ "$hs" -gt 0 ] || return 1
      now=$(date +%s)
      echo $(( now - hs ))
    }

    # persistent-keepalive is what makes verification possible at all: without
    # it WireGuard only handshakes once something routes into the tunnel, so a
    # freshly-configured peer would sit silent and look identical to a dead
    # one. It also keeps the NAT mapping open and makes waybar's freshness
    # check meaningful on an idle tunnel.
    configure_peer() {
      local pk=$1 ip=$2 old
      old=$(current_peer)
      [ -n "$old" ] && wg set "$IFACE" peer "$old" remove 2>/dev/null || true
      wg set "$IFACE" peer "$pk" \
        allowed-ips 0.0.0.0/0,::/0 \
        endpoint "$ip:51820" \
        persistent-keepalive 25
    }

    await_handshake() {
      local waited=0
      while [ "$waited" -lt "$((HS_WAIT * 2))" ]; do
        handshake_age >/dev/null 2>&1 && return 0
        sleep 0.5
        waited=$((waited + 1))
      done
      return 1
    }

    # Walk the candidates for a pin until one actually handshakes.
    # Returns 0 and echoes the chosen hostname; 1 if none answered.
    select_relay() {
      local pref=$1 quiet=''${2:-} tries=0 host country city ip pk
      local list feed try
      feed=$(catalog) || return 1
      # An exact pin is the most churn-prone kind: when that one relay retires
      # it resolves to nothing, and "nothing" would leave the dead peer in
      # place — the silent leak again, one level up. So widen the pin a
      # dash-segment at a time (se-got-wg-001 → se-got → se) rather than fail.
      try=$pref
      while :; do
        list=$(candidates "$try" <<< "$feed")
        [ -n "$list" ] && break
        case "$try" in
          *-*)
            echo "warning: no relay matches \"$try\" (retired?), broadening to \"''${try%-*}\"" >&2
            try=''${try%-*}
            ;;
          *)
            echo "error: no relay matches \"$pref\" at any granularity (try: mullvad-jump list)" >&2
            return 1
            ;;
        esac
      done
      while IFS=$'\t' read -r host country city ip pk; do
        [ -n "$host" ] || continue
        tries=$((tries + 1))
        [ "$tries" -le "$MAX_TRIES" ] || break
        configure_peer "$pk" "$ip" || continue
        if await_handshake; then
          [ -n "$quiet" ] || echo "on $host ($city, $country)"
          return 0
        fi
        echo "warning: $host did not handshake within ''${HS_WAIT}s, trying next" >&2
      done <<< "$list"
      echo "error: no relay matching \"$pref\" completed a handshake" >&2
      return 1
    }

    verify_exit() {
      curl -sf --max-time 15 https://am.i.mullvad.net/json \
        | jq -r '"exit: \(.mullvad_exit_ip_hostname // "NOT MULLVAD") (\(.ip), \(.city))"' \
        || echo "exit check failed — tunnel may still be handshaking"
    }

    cmd="''${1:-usage}"
    case "$cmd" in
      list)
        if [ -n "''${2:-}" ]; then
          catalog | { grep -i -- "$2" || true; } | cut -f1-3 | column -t
        else
          catalog | cut -f1-3 | column -t
        fi
        ;;

      pick)
        # Interactive path: choose, then hand off to the jump path so the
        # choice is persisted and verified exactly like a typed prefix.
        feed=$(catalog) || exit 1
        [ -n "''${2:-}" ] && feed=$(grep -i -- "$2" <<< "$feed" || true)
        sel=$(cut -f1-3 <<< "$feed" | column -t \
              | fzf --prompt='mullvad relay > ' --height=40% --reverse) || exit 1
        [ -n "$sel" ] || exit 1
        exec "$0" "$(awk '{print $1}' <<<"$sel")"
        ;;

      apply)
        # Boot/restart path, run from wg-mullvad's postUp BEFORE the egress
        # rules are installed. The exit status is the contract: postUp installs
        # the policy only on success, so "no verified relay" degrades to the
        # physical uplink instead of blackholing every route into a tunnel that
        # cannot carry traffic.
        need_root "$@"
        mkdir -p "$STATE" 2>/dev/null || true
        pref=""
        [ -s "$PIN" ] && pref=$(tr -d ' \n' < "$PIN")
        [ -n "$pref" ] || pref="''${2:-}"
        if [ -z "$pref" ]; then
          echo "mullvad-jump: no pin and no default relay — egress policy not installed" >&2
          exit 1
        fi
        select_relay "$pref"
        ;;

      status)
        need_root "$@"
        pin=$([ -s "$PIN" ] && cat "$PIN" || echo "(none — using the Nix default)")
        echo "pin:            $pin"
        pk=$(current_peer)
        if [ -z "$pk" ]; then
          echo "peer:           NONE — interface has no peer configured"
        else
          # "absent from the catalog" and "could not consult the catalog" are
          # different facts and must not collapse into one message: reporting a
          # failed lookup as a retired relay sends you hunting the wrong bug.
          feed=$(catalog 2>/dev/null) || feed=""
          if [ -z "$feed" ]; then
            echo "peer:           UNKNOWN — catalog unavailable, cannot classify this peer"
          else
            host=$(awk -F'\t' -v k="$pk" '$5 == k {print $1" ("$3", "$2")"; exit}' <<< "$feed")
            if [ -n "$host" ]; then
              echo "peer:           $host"
            else
              echo "peer:           NOT IN CATALOG — relay retired or key rotated;"
              echo "                this tunnel can never handshake. Run: mullvad-jump <prefix>"
            fi
          fi
        fi
        if age=$(handshake_age); then
          echo "last handshake: ''${age}s ago"
        else
          echo "last handshake: NEVER"
        fi
        verify_exit
        ;;

      reset)
        need_root "$@"
        rm -f "$PIN"
        echo "pin cleared — reverting to the Nix default relay"
        systemctl restart wg-quick-"$IFACE"
        ;;

      usage|-h|--help)
        usage
        ;;

      *)
        need_root "$@"
        mkdir -p "$STATE" 2>/dev/null || true
        # Resolve BEFORE touching the interface. Bringing wg-mullvad up
        # installs the egress rules, and if its peer is stale that blackholes
        # the connectivity this very fetch depends on — the deadlock that made
        # a cold-start jump impossible. Fetching first also warms the cache
        # while the uplink is known-good.
        feed=$(catalog) || exit 1
        if [ -z "$(candidates "$cmd" <<< "$feed")" ]; then
          echo "error: no relay matches \"$cmd\" (try: mullvad-jump list)" >&2
          exit 1
        fi
        echo "$cmd" > "$PIN"
        echo "pinned \"$cmd\" — survives restarts and reboots, re-resolved live each time"
        # postUp is the single place that resolves, verifies and installs the
        # egress policy; restarting the unit is how a pin takes effect. Doing
        # the wg-set here as well would be a second, divergent copy of that.
        systemctl restart wg-quick-"$IFACE"
        if age=$(handshake_age); then
          echo "tunnel up — handshake ''${age}s ago"
          verify_exit
        else
          echo "warning: no handshake after restart — egress left on the physical" >&2
          echo "uplink (fail open). See: mullvad-jump status" >&2
          exit 1
        fi
        ;;
    esac
  '';

  meta = {
    description = "Live Mullvad relay switcher and resolver for the wg-mullvad split tunnel";
    license = lib.licenses.mit;
    mainProgram = "mullvad-jump";
    platforms = lib.platforms.linux;
  };
}
