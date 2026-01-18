# Phantom USB - Ephemeral NixOS

A portable, encrypted NixOS that boots from USB, connects to your infrastructure, and leaves no trace when removed.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        256GB USB Drive                              │
├─────────────┬───────────────────────────────────────────────────────┤
│   ESP (1G)  │              LUKS Encrypted (rest)                    │
│   FAT32     │  ┌─────────────────────────────────────────────────┐  │
│             │  │  BTRFS                                          │  │
│  - Kernel   │  │  ├── @nix      (Nix store, compressed)          │  │
│  - Initrd   │  │  ├── @persist  (secrets, state you keep)        │  │
│  - EFI stub │  │  └── @snapshots (optional rollbacks)            │  │
│             │  └─────────────────────────────────────────────────┘  │
└─────────────┴───────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    RAM (tmpfs root @ boot)                          │
├─────────────────────────────────────────────────────────────────────┤
│  /           <- tmpfs (vanishes on poweroff)                        │
│  /nix        <- bind mount from USB @nix                            │
│  /persist    <- bind mount from USB @persist                        │
│  /home/bogdan<- tmpfs + symlinks to /persist where needed           │
└─────────────────────────────────────────────────────────────────────┘
```

## Features

- **LUKS2 + YubiKey FIDO2**: One touch to unlock at boot
- **Ephemeral root**: tmpfs `/` - everything in RAM, zero disk trace
- **Impermanence**: Only `/persist` survives reboot
- **Tailscale auto-connect**: Joins your tailnet immediately on boot
- **Portable EFI**: Works on any UEFI machine without modifying host
- **Memory scrub**: Clears caches on shutdown
- **Kernel hardening**: lockdown=confidentiality, init_on_alloc, etc.

## USB Device

Current target device:
```
/dev/disk/by-id/usb-_USB_DISK_3.0_070D48E289013A26-0:0
```

**Warning**: The disko configuration targets this specific USB by serial number. It will NOT accidentally wipe other drives.

## Initial Setup

Run these commands from your existing NixOS system (e.g., framework13):

### 1. Partition and Format the USB

```bash
# Create a temporary password for initial LUKS setup
echo "your-temporary-password" > /tmp/disk-password

# Run disko to partition and format the USB
# This creates: ESP (1GB) + LUKS-encrypted BTRFS (rest)
sudo nix run github:nix-community/disko -- --mode disko --flake .#phantom
```

**What this does:**
- Creates GPT partition table
- ESP partition (1GB, FAT32) at `/dev/disk/by-partlabel/disk-phantom-ESP`
- LUKS2 encrypted partition at `/dev/disk/by-partlabel/disk-phantom-cryptroot`
- BTRFS with @nix, @persist, @snapshots subvolumes
- Mounts everything under `/mnt`

### 2. Install NixOS to the USB

```bash
# Install the phantom configuration to /mnt
sudo nixos-install --flake .#phantom --root /mnt --no-root-password
```

**Note:** The installation writes to a temporary BTRFS root at `/mnt`. After the first boot, this will be overlayed with tmpfs (ephemeral root).

### 3. Embed the Tailscale Auth Key

The Tailscale key is stored in plaintext on `/persist` (protected by LUKS encryption):

```bash
# Create secrets directory on the encrypted persist partition
sudo mkdir -p /mnt/persist/secrets

# Decrypt the Tailscale auth key from SOPS and write to persist
# NOTE: Adjust the SOPS path to match your secrets location
sops -d --extract '["tailscale_auth_key"]' secrets/iso/tailscale.yaml | \
  sudo tee /mnt/persist/secrets/tailscale-authkey > /dev/null

# Lock down permissions (root-only read)
sudo chmod 600 /mnt/persist/secrets/tailscale-authkey
```

### 4. Enroll YubiKey for FIDO2 Unlock

```bash
# Remove the temporary password and enroll YubiKey instead
# You'll be prompted to touch your YubiKey during enrollment
sudo systemd-cryptenroll /dev/disk/by-partlabel/disk-phantom-cryptroot --fido2-device=auto --wipe-slot=password
```

**Important:**
- The `--wipe-slot=password` removes the temporary password
- After this, ONLY your YubiKey can unlock the USB
- Keep a recovery key if you want a backup: add `--recovery-key` before wiping

### 5. Cleanup and Unmount

```bash
# Securely delete the temporary password file
shred -u /tmp/disk-password

# Unmount all partitions
sudo umount -R /mnt

# Lock the LUKS volume
sudo cryptsetup luksClose phantom-crypt
```

The USB is now ready! Remove it and test booting on any UEFI machine.

## Usage

### Booting

1. Plug USB into any UEFI machine
2. Boot from USB (may need to select boot device in BIOS)
3. Touch YubiKey when prompted to unlock LUKS
4. System boots, Tailscale auto-connects
5. Login with YubiKey touch (or password if configured)

### What Persists

Only these survive reboot (configured in `system/phantom/impermanence.nix`):

| Path | Purpose |
|------|---------|
| `/var/lib/nixos` | User/group UID/GID mappings |
| `/var/lib/tailscale` | Tailscale node identity |
| `/var/lib/bluetooth` | Paired Bluetooth devices |
| `/etc/NetworkManager/system-connections` | Saved WiFi networks |
| `/etc/machine-id` | Stable machine identity |
| `~/.gnupg` | GPG keyring |
| `~/.ssh` | SSH keys |
| `~/.local/share/keyrings` | GNOME keyring |

### Shutdown Behavior

On shutdown:
1. Tailscale logs out (node disappears from tailnet)
2. Memory caches dropped
3. LUKS volume locked
4. tmpfs cleared - no trace remains

## Updating

To update the phantom configuration:

```bash
# From your main machine
nixos-rebuild build --flake .#phantom

# Or boot phantom and rebuild in place
sudo nixos-rebuild switch --flake /path/to/dotfiles#phantom
```

## Troubleshooting

### YubiKey not detected at boot

Ensure the YubiKey is plugged in before GRUB loads. The initrd needs to detect it early.

### Tailscale not connecting

Check if the auth key exists:
```bash
cat /persist/secrets/tailscale-authkey
```

Check the service status:
```bash
systemctl status tailscale-autoconnect
journalctl -u tailscale-autoconnect
```

### Adding more persistence

Edit `system/phantom/impermanence.nix` to add directories or files you want to persist.

## Security Notes

- The Tailscale auth key is stored unencrypted on `/persist`, but `/persist` is on the LUKS-encrypted partition
- YubiKey FIDO2 provides strong authentication without needing to remember a password
- The empty user password means YubiKey is required for sudo (configured as `sufficient`)
- Kernel lockdown prevents memory dumps even with physical access
