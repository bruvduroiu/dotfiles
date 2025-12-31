# Pixel 8a Stealth Travel Router Setup Guide

## Overview

Your Pixel 8a is now configured as a **stealth travel router** that:
- Routes tethered traffic through Mullvad VPN (if enabled)
- Uses TTL cloaking to defeat carrier tethering detection
- Applies MSS clamping to prevent fragmentation fingerprinting
- Hides all HTTP/TLS fingerprints inside encrypted VPN tunnel

## Quick Start

### 1. Install Mullvad VPN (One-time Setup)

**Option A: Using Mullvad App (Easiest)**
```bash
# Download Mullvad from Google Play or F-Droid
# Login with your account
# In Mullvad: Settings → VPN Settings → Always-on VPN ✓
# Leave "Block connections without VPN" OFF (otherwise your phone can't reach cellular)
```

**Option B: Manual WireGuard Config**
```bash
# Get your Mullvad WireGuard config from mullvad.net/account
# Settings → Network & Internet → VPN → + (Add VPN)
# Import WireGuard config
```

### 2. Start the Router

```bash
# Connect USB-C to Ethernet adapter
# Enable VPN (Mullvad app or Android VPN settings)
# Start router
adb shell
su
/data/local/tmp/router-start
```

Expected output:
```
=== Pixel 8a Stealth Router ===
[1/8] IP forwarding...
[2/8] Finding upstream...
    Primary: rmnet1 (100.x.x.x)
[3/8] Detecting VPN...
    VPN found: tun0 (10.x.x.x)
[4/8] Configuring eth0...
    eth0 = 192.168.50.1/24
[5/8] NAT rules...
    Added MASQUERADE -> tun0 (VPN)
[6/8] Forward rules...
    eth0 <-> tun0 allowed
[7/8] TTL cloaking...
    Outbound: TTL=64 on rmnet1
    Inbound: TTL+1 on rmnet1
    MSS clamping enabled
[8/8] DHCP...
    DHCP started

=== Router Ready ===
Mode: STEALTH (via tun0)
Carrier sees: Encrypted VPN traffic only
Downstream: eth0 (192.168.50.1/24)
Upstream: rmnet1 (100.x.x.x)
```

### 3. Connect Your Devices

Plug in Ethernet cable or USB-C hub with Ethernet. Your laptop should get:
- IP: `192.168.50.100-200` (DHCP)
- Gateway: `192.168.50.1`
- DNS: `1.1.1.1`, `8.8.8.8`

### 4. Check Status

```bash
adb shell
su
/data/local/tmp/router-status
```

### 5. Stop Router

```bash
adb shell
su
/data/local/tmp/router-stop
```

## How Stealth Mode Works

### Without VPN (⚠️ Not Stealthy)
```
Laptop → Phone → Carrier
         ↑
    TTL fixes only
    (Carrier can still see HTTP/TLS fingerprints)
```

### With VPN (✅ Fully Stealthy)
```
Laptop → Phone → Mullvad VPN → Internet
         ↑          ↑
    TTL fixes   All traffic
                encrypted

Carrier sees:
- Single destination IP (Mullvad server)
- TTL=64 (looks like phone traffic)
- Encrypted payload (no DPI possible)
- No HTTP headers, no TLS fingerprints, no DNS queries
```

## Detection Methods Defeated

| Method | How We Defeat It |
|--------|-----------------|
| **TTL Analysis** | Set to 64 (outbound) + increment (inbound) |
| **TCP Fingerprinting** | Hidden in VPN tunnel |
| **HTTP User-Agent** | Hidden in VPN tunnel |
| **TLS/JA3 Fingerprinting** | Hidden in VPN tunnel |
| **DNS Patterns** | All DNS through VPN |
| **SNI Analysis** | Hidden in VPN tunnel |
| **MSS/MTU Fingerprinting** | MSS clamping normalizes packets |

## Traffic Flow (Stealth Mode)

```
┌─────────┐     ┌──────────────┐     ┌─────────┐     ┌──────────┐
│ Laptop  │────▶│  Pixel 8a    │────▶│ Carrier │────▶│ Mullvad  │
│         │ eth0│ 192.168.50.1 │rmnet│  Tower  │     │   VPN    │
└─────────┘     │              │     └─────────┘     └──────────┘
                │ - NAT        │           │               │
                │ - TTL=64     │        Sees only:         │
                │ - VPN tunnel │        - Encrypted        │
                └──────────────┘        - TTL=64           │
                                        - 1 destination     │
                                                            │
                                        ┌───────────────────┘
                                        ▼
                                  ┌──────────┐
                                  │ Internet │
                                  └──────────┘
```

## Troubleshooting

### Router says "No VPN detected"
**Cause**: Mullvad VPN not running in Android
**Fix**: Open Mullvad app and connect, or enable VPN in Android Settings

### Router starts but no internet on laptop
**Cause**: VPN tunnel may have dropped
**Fix**:
```bash
# Check status
/data/local/tmp/router-status

# If VPN shows "None", restart VPN in Mullvad app
# Then restart router
/data/local/tmp/router-stop
/data/local/tmp/router-start
```

### Slow speeds
**Cause**: VPN overhead or distant server
**Fix**: In Mullvad app, choose a nearby server (e.g., same city/country)

### Carrier still detecting tethering
**Extremely unlikely if VPN is active**. But if it happens:
1. Verify VPN is running: `ip addr show tun0`
2. Check TTL rules: `/data/local/tmp/router-status`
3. Consider using Mullvad's "Multihop" feature for extra obfuscation

## Advanced: DNS Enforcement (Optional)

To force all DNS through VPN (prevent leaks):

```bash
# Add to router-start after line 163 (MSS clamping):

# Force DNS through VPN
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 53 -j DNAT --to 192.168.50.1:53
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 53 -j DNAT --to 192.168.50.1:53
```

Then configure dnsmasq to forward to Mullvad's DNS or use DoH.

## Notes

- **Battery Impact**: VPN + routing uses more battery. Keep phone plugged in.
- **Data Usage**: VPN overhead adds ~5-10% to data usage
- **Mullvad Servers**: Choose geographically close servers for best latency
- **Kill Switch**: Don't enable "Block connections without VPN" in Android - it will break cellular routing
- **Always-On VPN**: You CAN enable this - router will auto-detect when VPN reconnects

## Performance Tips

1. **Choose nearby Mullvad server** (lowest latency)
2. **Use WireGuard protocol** (faster than OpenVPN)
3. **Disable unnecessary Android services** (save battery)
4. **Keep phone plugged in** (router + VPN = heavy battery use)

## What the Carrier Actually Sees

```
IP Packet Header:
  Source: 100.x.x.x (your cellular IP)
  Dest: 185.213.154.x (Mullvad server)
  TTL: 64 ✓ (looks like phone)
  Protocol: UDP (WireGuard)

Payload:
  [encrypted gibberish]

Carrier's View:
  "Phone is using a VPN to some server in Sweden. Can't see anything inside."
```

They **cannot** detect:
- What websites you visit
- What protocols you use
- What devices are behind the phone
- HTTP headers, TLS fingerprints, DNS queries

## Safety Level

| Mode | Carrier Visibility | Detection Risk |
|------|-------------------|----------------|
| **No Router** | Phone traffic only | None |
| **Router, No VPN** | All tethered traffic visible | Very High ⚠️ |
| **Router + TTL** | Traffic visible, TTL fixed | High ⚠️ |
| **Router + VPN + TTL** | Only encrypted VPN traffic | Very Low ✅ |

**Current Setup**: Router + VPN + TTL = **Very Low Risk** ✅

---

Enjoy your stealth travel router! 🚀
