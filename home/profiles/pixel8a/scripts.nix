{ config, pkgs, lib, ... }:

# Router control scripts for the Pixel 8a travel router
{
  # Router start script
  home.file.".local/bin/router-start" = {
    executable = true;
    text = ''
      #!/bin/bash
      set -e

      echo "Starting travel router services..."

      # Apply iptables rules (includes sysctl for IP forwarding)
      sudo ~/.config/router/iptables-rules.sh

      # Start blocky (DNS filtering)
      if ! pgrep -x blocky > /dev/null; then
        blocky serve --config ~/.config/blocky/config.yml &
        echo $! > /tmp/blocky.pid
        echo "Started blocky DNS"
      else
        echo "blocky already running"
      fi

      # Start Tailscale if not running
      if ! pgrep -x tailscaled > /dev/null; then
        echo "Starting tailscaled..."
        sudo tailscaled &
        sleep 2
      fi

      # Configure Tailscale as subnet router and exit node
      if ! tailscale status > /dev/null 2>&1; then
        echo "Connecting to Tailscale..."
        sudo tailscale up \
          --advertise-exit-node \
          --advertise-routes=192.168.42.0/24 \
          --accept-routes \
          --reset
      else
        echo "Tailscale already connected"
      fi

      echo ""
      echo "Router started!"
      echo "  Tailscale: $(tailscale status --json | jq -r '.Self.TailscaleIPs[0]')"
      echo "  DNS: blocky on port 53"
      echo ""
      echo "Remember to approve exit node and routes in Tailscale admin console!"
    '';
  };

  # Router stop script
  home.file.".local/bin/router-stop" = {
    executable = true;
    text = ''
      #!/bin/bash

      echo "Stopping travel router services..."

      # Stop blocky
      if [ -f /tmp/blocky.pid ]; then
        kill $(cat /tmp/blocky.pid) 2>/dev/null || true
        rm /tmp/blocky.pid
        echo "Stopped blocky"
      fi

      # Disconnect Tailscale (but don't stop daemon)
      sudo tailscale down 2>/dev/null || true
      echo "Disconnected Tailscale"

      # Flush iptables (restore defaults)
      sudo iptables -F
      sudo iptables -t nat -F
      sudo iptables -t mangle -F
      sudo iptables -P INPUT ACCEPT
      sudo iptables -P FORWARD ACCEPT
      sudo iptables -P OUTPUT ACCEPT
      echo "Flushed iptables"

      echo "Router stopped"
    '';
  };

  # Router status script
  home.file.".local/bin/router-status" = {
    executable = true;
    text = ''
      #!/bin/bash

      echo "=== Tailscale Status ==="
      tailscale status

      echo ""
      echo "=== Tailscale IP ==="
      tailscale ip -4 2>/dev/null || echo "Not connected"

      echo ""
      echo "=== Exit Node Status ==="
      tailscale status --json | jq '.Self | {ExitNode: .ExitNode, ExitNodeOption: .ExitNodeOption, AdvertisedRoutes: .AllowedIPs}'

      echo ""
      echo "=== Public IP (through Tailscale) ==="
      curl -s --max-time 5 ifconfig.me 2>/dev/null && echo "" || echo "Unable to reach"

      echo ""
      echo "=== IP Forwarding ==="
      echo "IPv4: $(cat /proc/sys/net/ipv4/ip_forward)"
      echo "IPv6: $(cat /proc/sys/net/ipv6/conf/all/forwarding)"

      echo ""
      echo "=== Network Interfaces ==="
      ip -br addr

      echo ""
      echo "=== DNS Test ==="
      echo "Google (should resolve):"
      dig +short @127.0.0.1 google.com 2>/dev/null || echo "blocky not running"
      echo "Ad domain (should be blocked):"
      result=$(dig +short @127.0.0.1 ads.google.com 2>/dev/null)
      if [ -z "$result" ] || [ "$result" = "0.0.0.0" ]; then
        echo "Blocked!"
      else
        echo "$result"
      fi
    '';
  };

  # Chroot helper script (to be run from Termux)
  home.file.".local/bin/void-services" = {
    executable = true;
    text = ''
      #!/bin/bash
      # Helper to manage runit services in the Void chroot
      # Run this from within the chroot

      case "$1" in
        start)
          echo "Starting router services..."
          ~/.local/bin/router-start
          ;;
        stop)
          echo "Stopping router services..."
          ~/.local/bin/router-stop
          ;;
        status)
          ~/.local/bin/router-status
          ;;
        *)
          echo "Usage: $0 {start|stop|status}"
          exit 1
          ;;
      esac
    '';
  };
}
