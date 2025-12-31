{ config, pkgs, lib, ... }:

# Tailscale subnet router configuration for Pixel 8a travel router
# This acts as an exit node and subnet router, allowing devices to:
# 1. Route all traffic through Tailscale (exit node)
# 2. Access the local network the Pixel is connected to (subnet router)

{
  # Blocky DNS configuration for ad/tracker blocking
  home.file.".config/blocky/config.yml".text = ''
    upstream:
      default:
        - 9.9.9.9      # Quad9
        - 149.112.112.112
        - 1.1.1.1      # Cloudflare
        - 1.0.0.1

    ports:
      dns: 53
      http: 4000

    blocking:
      blackLists:
        ads:
          - https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
          - https://adaway.org/hosts.txt
        malware:
          - https://urlhaus.abuse.ch/downloads/hostfile/
        tracking:
          - https://v.firebog.net/hosts/Easyprivacy.txt

      clientGroupsBlock:
        default:
          - ads
          - malware
          - tracking

    queryLog:
      type: console

    prometheus:
      enable: false
  '';

  # iptables rules for NAT routing
  # Tailscale handles most routing, but we need NAT for subnet routing
  home.file.".config/router/iptables-rules.sh" = {
    executable = true;
    text = ''
      #!/bin/bash

      # Flush existing rules
      iptables -F
      iptables -t nat -F
      iptables -t mangle -F

      # Default policies - more permissive since Tailscale handles security
      iptables -P INPUT ACCEPT
      iptables -P FORWARD ACCEPT
      iptables -P OUTPUT ACCEPT

      # Enable IP forwarding
      sysctl -w net.ipv4.ip_forward=1
      sysctl -w net.ipv6.conf.all.forwarding=1

      # NAT for traffic going out the upstream interface
      # This allows devices connected via USB/WiFi tethering to access the internet
      # tailscale0 is the Tailscale interface
      iptables -t nat -A POSTROUTING -o tailscale0 -j MASQUERADE

      # Also NAT for the physical upstream (wlan0 or rmnet_data*)
      # This is needed when not using Tailscale as exit node
      iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE

      # TTL normalization for carrier tethering evasion
      # Set TTL to 64 for all forwarded packets
      iptables -t mangle -A POSTROUTING -j TTL --ttl-set 64
      ip6tables -t mangle -A POSTROUTING -j HL --hl-set 64 2>/dev/null || true

      echo "iptables rules applied"
    '';
  };

  # dnsmasq configuration for DHCP (optional, for WiFi hotspot mode)
  home.file.".config/dnsmasq/dnsmasq.conf".text = ''
    # Interface to serve DHCP on (USB tethering interface)
    # Android typically uses rndis0 for USB tethering
    interface=rndis0

    # Don't use dnsmasq for DNS (blocky handles that)
    port=0

    # DHCP range for tethered devices
    dhcp-range=192.168.42.10,192.168.42.200,24h

    # Gateway (this device)
    dhcp-option=option:router,192.168.42.1

    # DNS server (this device running blocky)
    dhcp-option=option:dns-server,192.168.42.1

    # Lease file
    dhcp-leasefile=/tmp/dnsmasq.leases
  '';

  # Tailscale configuration notes
  # Tailscale needs to be started with specific flags for subnet routing:
  #
  # tailscale up \
  #   --advertise-exit-node \
  #   --advertise-routes=192.168.42.0/24 \
  #   --accept-routes \
  #   --reset
  #
  # Then approve the subnet routes in the Tailscale admin console
  home.file.".config/router/tailscale-notes.md".text = ''
    # Tailscale Subnet Router Setup

    ## Initial Setup
    ```bash
    # Start Tailscale as subnet router and exit node
    sudo tailscale up \
      --advertise-exit-node \
      --advertise-routes=192.168.42.0/24 \
      --accept-routes \
      --reset
    ```

    ## Approve in Admin Console
    1. Go to https://login.tailscale.com/admin/machines
    2. Find the Pixel 8a device
    3. Click "..." menu → "Edit route settings"
    4. Enable "Use as exit node"
    5. Approve the subnet routes (192.168.42.0/24)

    ## Client Setup
    On devices that want to use this as exit node:
    ```bash
    tailscale up --exit-node=<pixel-tailscale-ip>
    ```

    ## Subnet Access
    Devices on your Tailnet can now access 192.168.42.0/24
    (the network of devices tethered to the Pixel)
  '';
}
