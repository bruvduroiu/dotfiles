# Phantom USB - Ephemeral NixOS

A portable, encrypted NixOS that boots from USB into Niri + Noctalia, with an
ephemeral root and selective state on the encrypted USB. The host machine's
disks and EFI variables are not used for installation.

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
- **Ephemeral root**: tmpfs `/`; only explicitly persisted state survives reboot
- **Impermanence**: Only `/persist` survives reboot
- **Niri + Noctalia**: Framework bindings and applications, automatic display placement
- **WireGuard auto-connect once provisioned**: Dedicated home-overlay peer, key on encrypted `/persist`
- **Portable EFI**: Works on any UEFI machine without modifying host
- **Memory scrub**: Clears caches on shutdown
- **Kernel hardening**: lockdown=confidentiality, init_on_alloc, etc.

## USB Device

The target device serial lives in the private flake:
`inputs.secrets.vars.hosts.phantom.usbDiskId` (a `/dev/disk/by-id/usb-...` id).

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

### 3. Provision the WireGuard Peer

The currently pinned private flake has no Phantom WireGuard identity. Until it
does, evaluation emits a warning and the overlay is disabled. Do not reuse the
Framework or Steam Deck private key/address: each running peer needs its own.

In the private flake, add `vars.hosts.phantom.wireguard.overlayIP`, using a free
address from the existing overlay. Register the corresponding public key and
that address's `/32` on the home hub. Update the secrets input through the normal
reviewed lockfile workflow before building the USB.

Install the dedicated private key from a root-readable file on the provisioning
machine (replace the source path below). It remains plaintext inside encrypted
`/persist`, never in the Nix store or this repository:

```bash
sudo install -d -m 0700 /mnt/persist/secrets
sudo install -o root -g root -m 0400 /path/to/phantom-private-key \
  /mnt/persist/secrets/wg-private-key
```

### 4. Enroll Credentials for FIDO2 Unlock

Order matters. Each step is authorised by a credential enrolled in the step
before it, so running these out of order leaves you with nothing to authorise
the next one.

```bash
DEV=/dev/disk/by-partlabel/disk-phantom-cryptroot

# 4a. Enroll the YubiKey, authorised by the temporary password from step 1.
#     Touch the key when it flashes.
sudo systemd-cryptenroll "$DEV" --fido2-device=auto

# 4b. Enroll a recovery key. NOT OPTIONAL — see below.
#     Prints a high-entropy passphrase exactly once; store it offline now.
sudo systemd-cryptenroll "$DEV" --unlock-fido2-device=auto --recovery-key

# 4c. Only now remove the temporary password slot.
sudo systemd-cryptenroll "$DEV" --unlock-fido2-device=auto --wipe-slot=password

# 4d. Verify before you walk away. Non-zero exit means a lockout risk remains.
sudo phantom-unlock check
```

**The recovery key is not optional.** Without step 4b the volume ends up with
exactly one credential bound to one piece of hardware. A lost, broken, or
factory-reset YubiKey then destroys 230GB permanently — there is no second
path in.

If you own a backup YubiKey, enroll it too — but note this needs **both keys
plugged in simultaneously**, and `auto` does not work on either side: systemd
cannot tell which token is authorising and which is being enrolled, and
refuses rather than guessing. Give explicit paths:

```bash
# With both keys inserted, list them and note which hidraw is which:
nix shell nixpkgs#libfido2 -c fido2-token -L

# Existing (authorises) → --unlock-fido2-device
# New (gets enrolled)   → --fido2-device
sudo systemd-cryptenroll "$DEV" \
  --unlock-fido2-device=/dev/hidrawX \
  --fido2-device=/dev/hidrawY
```

You touch the existing key first, then the new one.

**The backup key must actually support FIDO2.** `systemd-cryptenroll` needs
CTAP2 with the `hmac-secret` extension; U2F-only hardware cannot hold a LUKS
keyslot at all. In practice that rules out the YubiKey NEO (`0x0116`) and
other pre-2018 keys, which fail with `Specified device ... is not a FIDO2
device` no matter how the flags are arranged. A NEO appearing under
`fido2-token -L` is not evidence it will work — that listing enumerates HID
devices, not CTAP2 capability.

If you only have one FIDO2-capable key, the recovery key from 4b *is* your
backup — do not skip it.

**Do not skip 4d.** If step 4a silently failed, the volume still unlocks
during setup (the temporary password is live until 4c) and the gap only
surfaces at the next boot, long after `/tmp/disk-password` was shredded.
`phantom-unlock check` counts keyslots and FIDO2 tokens in the header and
fails loudly while the situation is still repairable.

### 5. Cleanup and Unmount

```bash
# Securely delete the temporary password file
shred -u /tmp/disk-password

# Unmount all partitions
sudo umount -R /mnt

# Lock the LUKS volume
sudo cryptsetup luksClose phantom-crypt
```

The USB is now ready for a boot test on a compatible x86_64 UEFI machine.

## Usage

### Booting

1. Plug USB into any UEFI machine
2. Boot from USB (may need to select boot device in BIOS)
3. Touch YubiKey when prompted to unlock LUKS
4. System boots into Niri; select Wi-Fi in Noctalia with Mod+Ctrl+N if needed
5. Once provisioned, `wg-quick-wg0` connects automatically and retries failed starts
6. Unlock Noctalia using the configured login credentials

The shared WireGuard module provides the same hub routes and host aliases as
the other machines. Phantom enables only the home overlay; Mullvad internet
egress is not configured. Internet traffic uses the physical uplink.

### Mounting on another running machine

Booting phantom and *mounting* phantom are different code paths, and only the
first one is automatic. Use the helper (available on any host importing
`system/services/yubikey.nix`):

```bash
sudo phantom-unlock             # unlock via YubiKey, mount @persist
sudo phantom-unlock --with-nix  # also mount @nix
sudo phantom-unlock status
sudo phantom-unlock lock        # unmount and close
```

Mounts land under `/run/media/phantom/`, deliberately away from `/mnt` so this
never collides with an in-progress install.

**Do not reach for `cryptsetup open` here.** The YubiKey enrollment writes a
*systemd* FIDO2 token into the LUKS2 header, and `cryptsetup` has no handler
for it — no plugin is installed on these hosts. It does not report the token
as unusable; it ignores it, finds no other handler, and prompts for a
passphrase. A completely healthy volume therefore presents as one you have
lost the credentials for. `phantom-unlock` goes through `systemd-cryptsetup`,
which reads the token properly.

### What Persists

Only these survive reboot (configured in `system/phantom/impermanence.nix`):

| Path | Purpose |
|------|---------|
| `/var/lib/nixos` | User/group UID/GID mappings |
| `/var/lib/bluetooth` | Paired Bluetooth devices |
| `/var/lib/systemd/coredump` | Existing persistence entry; core dumps are disabled by kernel configuration |
| `/etc/NetworkManager/system-connections` | Saved WiFi networks |
| `/etc/machine-id` | Stable machine identity |
| `~/.gnupg` | GPG keyring |
| `~/.ssh` | SSH keys |
| `~/.local/share/keyrings` | GNOME keyring |
| `~/.bash_history` | Existing shell history persistence |
| `/persist/secrets/wg-private-key` | Dedicated WireGuard identity, provisioned directly |

Noctalia's `~/.local/state/noctalia` is deliberately not persisted, so settings
overrides and clipboard history reset on reboot. Generated themes are recreated
at login. Existing data under `/persist/var/lib/tailscale` is not deleted by this
migration, but is no longer mounted or used.

### Shutdown Behavior

On shutdown:
1. WireGuard interfaces stop; the hub retains the provisioned peer registration
2. Memory caches dropped
3. LUKS volume locked
4. tmpfs state is lost; explicitly persisted state remains on the USB

Dropping caches is not a guarantee of physical RAM erasure. Network peers and
remote services can retain logs of the session.

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

### "It's asking for a passphrase I never set"

Almost always the wrong unlock command rather than a lost volume. Check the
header before concluding anything is unrecoverable:

```bash
sudo phantom-unlock check
```

If that reports a FIDO2 token, the volume is healthy and you were using
`cryptsetup open`, which cannot read systemd tokens — use `sudo phantom-unlock`
instead (see *Mounting on another running machine*).

If it reports **no** FIDO2 token, enrollment never completed and the only
credential is whatever passphrase was set at step 1. That is the genuinely
unrecoverable case, and it is what step 4d exists to prevent.

Never run `disko --mode disko` to "reset" a volume you cannot open. It
repartitions and destroys `/persist` — including `~/.ssh`, `~/.gnupg` and
`~/.local/share/keyrings`, which may exist nowhere else.

### WireGuard not connecting

Check provisioning without printing private key material:
```bash
sudo test -s /persist/secrets/wg-private-key
sudo stat -c '%a %U %G' /persist/secrets/wg-private-key
```

Check the service status:
```bash
systemctl status wg-quick-wg0
journalctl -b -u wg-quick-wg0
sudo wg show wg0 latest-handshakes
```

If the service does not exist, provision the private-flake address first. If it
starts without a handshake, check the hub's peer registration, endpoint reachability
and Wi-Fi connectivity. Noctalia's network icon is not a WireGuard health check.

### Adding more persistence

Edit `system/phantom/impermanence.nix` to add directories or files you want to persist.

## Security Notes

- The WireGuard private key is root-only on LUKS-encrypted `/persist`
- YubiKey FIDO2 provides strong authentication without needing to remember a password
- The existing empty initial password and `sufficient` U2F PAM configuration are
  retained; they do not establish YubiKey-only authentication. Provision a usable
  login/unlock credential and verify the Noctalia lock screen before deployment.
- Kernel lockdown limits some memory access paths; it does not guarantee protection
  from every physical attack
