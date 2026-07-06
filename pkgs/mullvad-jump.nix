{
  lib,
  writeShellApplication,
  curl,
  jq,
  wireguard-tools,
  util-linux,
}:

# Live Mullvad relay switcher for the wg-quick "wg-mullvad" interface
# (see system/network/wireguard.nix). Switches are runtime-only: the
# kill switch / policy routing operate on the interface, not the peer,
# so a swap is leak-free; a wrong relay just fails closed. Persist a
# choice by editing mullvadEndpoint/mullvadPublicKey in the nix module.

writeShellApplication {
  name = "mullvad-jump";

  runtimeInputs = [ curl jq wireguard-tools util-linux ];

  text = ''
    RELAY_API="https://api.mullvad.net/public/relays/wireguard/v1"
    IFACE="wg-mullvad"

    usage() {
      cat <<EOF
    usage: mullvad-jump <hostname>      switch live to relay (e.g. de-fra-wg-001)
           mullvad-jump list [filter]   list relays, optionally filtered (city/country/hostname)
           mullvad-jump status          current relay + exit verification
           mullvad-jump reset           restart tunnel back to the nix-configured relay
    EOF
      exit 1
    }

    relays() {
      curl -sf --max-time 15 "$RELAY_API" | jq -r '
        .countries[] as $c | $c.cities[] as $ci | $ci.relays[]
        | [.hostname, $c.name, $ci.name, .ipv4_addr_in, .public_key] | @tsv'
    }

    verify_exit() {
      sleep 2
      curl -sf --max-time 15 https://am.i.mullvad.net/json \
        | jq -r '"exit: \(.mullvad_exit_ip_hostname // "NOT MULLVAD") (\(.ip), \(.city))"' \
        || echo "exit check failed — tunnel may still be handshaking, try: mullvad-jump status"
    }

    cmd="''${1:-usage}"
    case "$cmd" in
      list)
        if [ -n "''${2:-}" ]; then
          relays | { grep -i -- "$2" || true; } | cut -f1-4 | column -t
        else
          relays | cut -f1-4 | column -t
        fi
        ;;
      status)
        [ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"
        wg show "$IFACE" endpoints | awk '{print "peer:", $1, "endpoint:", $2}'
        wg show "$IFACE" latest-handshakes | awk '{print "last handshake:", (systime()-$2), "s ago"}'
        verify_exit
        ;;
      reset)
        [ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"
        systemctl restart wg-quick-"$IFACE"
        echo "restarted $IFACE (nix-configured relay)"
        verify_exit
        ;;
      usage|-h|--help)
        usage
        ;;
      *)
        [ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"
        # No early-exit in awk: closing the pipe mid-stream SIGPIPEs
        # curl/jq, and pipefail+errexit then kills the script silently.
        line=$(relays | awk -F'\t' -v h="$cmd" '$1 == h {print}')
        [ -n "$line" ] || { echo "unknown relay: $cmd (try: mullvad-jump list)"; exit 1; }
        ip=$(cut -f4 <<<"$line"); pk=$(cut -f5 <<<"$line")
        old=$(wg show "$IFACE" peers)
        [ "$pk" = "$old" ] && { echo "already on $cmd"; exit 0; }
        wg set "$IFACE" peer "$old" remove
        wg set "$IFACE" peer "$pk" allowed-ips 0.0.0.0/0,::/0 endpoint "$ip:51820"
        echo "switched to $cmd ($ip) — live only; persist via mullvadEndpoint/mullvadPublicKey in wireguard.nix"
        verify_exit
        ;;
    esac
  '';

  meta = {
    description = "Live Mullvad relay switcher for the wg-mullvad split tunnel";
    license = lib.licenses.mit;
    mainProgram = "mullvad-jump";
    platforms = lib.platforms.linux;
  };
}
