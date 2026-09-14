{
  writeShellApplication,
  cryptsetup,
  systemd,
  util-linux,
  coreutils,
  gnugrep,
}:

# Attach phantom's LUKS volume from an ALREADY-RUNNING machine.
#
# WHY THIS EXISTS IN THIS SHAPE
#
# Phantom boots on any UEFI box without help: system/phantom/boot.nix enables a
# systemd initrd and passes `fido2-device=auto` through crypttab, so
# systemd-cryptsetup reads the FIDO2 token out of the LUKS2 header and one
# YubiKey touch unlocks the root device. That path is fine and this script has
# nothing to do with it.
#
# NONE of that machinery exists when you merely plug the USB into a running
# system. There is no crypttab entry and no initrd, so the obvious command is
# `cryptsetup open` — and cryptsetup CANNOT READ systemd's FIDO2 token. It is a
# systemd-specific JSON token serviced by a libcryptsetup token plugin that is
# not installed here. cryptsetup does not report this: it ignores the token,
# finds no usable handler, and falls through to a passphrase prompt. A perfectly
# healthy volume therefore presents as "I've forgotten the passphrase and lost
# the disk" — which is precisely how a wipe gets contemplated for no reason.
#
# So the out-of-band unlock has to go through systemd-cryptsetup explicitly.
# This wraps that, and makes the passphrase path an ANNOUNCED fallback rather
# than a silent degradation, so "the YubiKey didn't work" is always visible as
# its own event.
#
# `check` exists for the other half of that afternoon: the steady state after
# README step 4 is a volume with exactly ONE credential bound to ONE physical
# key. That is a backup problem disguised as a security property, and it is
# invisible unless something counts the keyslots for you.

writeShellApplication {
  name = "phantom-unlock";

  # EVERY external command must be listed; writeShellApplication PREPENDS these
  # to PATH and runs shellcheck at build time. systemd-cryptsetup is NOT in
  # bin/ (it lives in lib/systemd), so it is referenced by absolute path below
  # rather than through runtimeInputs.
  runtimeInputs = [
    cryptsetup
    util-linux
    coreutils
    gnugrep
  ];

  text = ''
    DEVICE=/dev/disk/by-partlabel/disk-phantom-cryptroot
    MAPPER=phantom-crypt
    BASE=/run/media/phantom
    SYSTEMD_CRYPTSETUP=${systemd}/lib/systemd/systemd-cryptsetup

    usage() {
      cat <<'EOF'
    phantom-unlock — attach the phantom USB's encrypted volume on a running system

      phantom-unlock              unlock with the YubiKey and mount @persist
      phantom-unlock --with-nix   also mount @nix (for chroot / rebuild work)
      phantom-unlock status       show device, mapper and mount state
      phantom-unlock check        audit the header for a lockout risk
      phantom-unlock lock         unmount and close the volume

    Booting phantom needs none of this — see system/phantom/boot.nix.
    EOF
    }

    need_root() {
      if [ "$(id -u)" -ne 0 ]; then
        echo "phantom-unlock: must run as root — re-run the same command with sudo" >&2
        exit 1
      fi
    }

    need_device() {
      if [ ! -e "$DEVICE" ]; then
        echo "phantom-unlock: $DEVICE not found — is the USB plugged in?" >&2
        exit 1
      fi
    }

    mount_subvol() {
      sub=$1
      target=$2
      mkdir -p "$target"
      if findmnt -n "$target" >/dev/null 2>&1; then
        echo "already mounted: $target"
      else
        mount -o "subvol=$sub,compress=zstd:3,noatime" "/dev/mapper/$MAPPER" "$target"
        echo "mounted $sub -> $target"
      fi
    }

    cmd_unlock() {
      with_nix=$1
      need_root
      need_device

      if [ -e "/dev/mapper/$MAPPER" ]; then
        echo "volume already open at /dev/mapper/$MAPPER"
      else
        echo "unlocking via FIDO2 — touch your YubiKey when it flashes..."
        # The `-` is the key-file argument: none, because the FIDO2 token in
        # the LUKS2 header supplies the key material.
        if ! "$SYSTEMD_CRYPTSETUP" attach "$MAPPER" "$DEVICE" - fido2-device=auto; then
          echo "" >&2
          echo "FIDO2 unlock FAILED. This is the fallback path, not the normal one." >&2
          echo "Enter the recovery key you enrolled (not a passphrase you invented):" >&2
          cryptsetup open "$DEVICE" "$MAPPER"
        fi
      fi

      mount_subvol @persist "$BASE/persist"
      if [ "$with_nix" = "1" ]; then
        mount_subvol @nix "$BASE/nix"
      fi
      echo ""
      echo "done. lock again with: sudo phantom-unlock lock"
    }

    cmd_lock() {
      need_root
      for m in "$BASE/nix" "$BASE/persist"; do
        if findmnt -n "$m" >/dev/null 2>&1; then
          umount "$m"
          echo "unmounted $m"
        fi
      done
      if [ -e "/dev/mapper/$MAPPER" ]; then
        cryptsetup close "$MAPPER"
        echo "closed $MAPPER"
      else
        echo "mapper already closed"
      fi
      rmdir "$BASE/nix" "$BASE/persist" "$BASE" 2>/dev/null || true
    }

    cmd_status() {
      if [ -e "$DEVICE" ]; then
        echo "device:  present"
      else
        echo "device:  ABSENT (USB not plugged in?)"
      fi
      if [ -e "/dev/mapper/$MAPPER" ]; then
        echo "mapper:  OPEN (/dev/mapper/$MAPPER)"
      else
        echo "mapper:  closed"
      fi
      for m in "$BASE/persist" "$BASE/nix"; do
        if findmnt -n "$m" >/dev/null 2>&1; then
          echo "mount:   $m"
        fi
      done
    }

    # Counts credentials rather than trusting that README step 4 was completed.
    # A single keyslot is the lockout condition: one dead YubiKey and the
    # volume is unrecoverable, with no warning until the day it matters.
    cmd_check() {
      need_root
      need_device
      dump=$(cryptsetup luksDump "$DEVICE")
      slots=$(echo "$dump" | grep -cE '^[[:space:]]+[0-9]+: luks2' || true)
      fido=$(echo "$dump" | grep -c 'systemd-fido2' || true)

      echo "keyslots:     $slots"
      echo "fido2 tokens: $fido"

      if [ "$fido" -eq 0 ]; then
        echo "" >&2
        echo "WARNING: no FIDO2 token in the header. Boot-time YubiKey unlock" >&2
        echo "cannot work; this volume is passphrase-only." >&2
        echo "  Fix: sudo systemd-cryptenroll $DEVICE --fido2-device=auto" >&2
      fi

      if [ "$slots" -le 1 ]; then
        echo "" >&2
        echo "WARNING: only $slots keyslot. Losing or resetting that YubiKey" >&2
        echo "destroys access to this volume permanently." >&2
        echo "  Fix: sudo systemd-cryptenroll $DEVICE \\" >&2
        echo "         --unlock-fido2-device=auto --recovery-key" >&2
        exit 1
      fi

      echo "ok: $slots credentials enrolled, no single point of failure"
    }

    case "''${1:-unlock}" in
      unlock)     cmd_unlock 0 ;;
      --with-nix) cmd_unlock 1 ;;
      status)     cmd_status ;;
      check)      cmd_check ;;
      lock)       cmd_lock ;;
      -h|--help)  usage ;;
      *)          usage; exit 1 ;;
    esac
  '';
}
