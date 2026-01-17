{ pkgs, inputs, ...}:

let
  decryptBooxUpdateUpx = pkgs.fetchFromGitHub {
    owner = "Hagb";
    repo = "decryptBooxUpdateUpx";
    rev = "96ab23f757ab7bdad1b153d0bafce97ce099c647";
    hash = "sha256-8r3F4Df1NHI/e+Y+ArZlScH5OzVqQxHLO4ak4x9jo8c=";
  };

  pythonEnv = pkgs.python3.withPackages (ps: [ ps.pycryptodome ]);

  boox-decrypt-firmware = pkgs.writeShellScriptBin "boox-decrypt-firmware" ''
    set -euo pipefail
    MODEL="''${1:-GoColor7_2}"
    INPUT="''${2:-update.upx}"
    echo "Decrypting $INPUT for model $MODEL..."
    ${pythonEnv}/bin/python ${decryptBooxUpdateUpx}/DeBooxUpx.py "$MODEL" "$INPUT"
    echo "Done. Output: update.zip"
  '';

  boox-status = pkgs.writeShellScriptBin "boox-status" ''
    set -euo pipefail
    echo "=== Boox Device Status ==="
    echo ""
    echo "ADB Connection:"
    ${pkgs.android-tools}/bin/adb devices -l
    echo ""
    if ${pkgs.android-tools}/bin/adb get-state 2>/dev/null | grep -q "device"; then
      echo "Root Status:"
      ${pkgs.android-tools}/bin/adb shell "su -c 'echo Root: OK'" 2>/dev/null || echo "Root: Not available"
      echo ""
      echo "Disabled Packages:"
      ${pkgs.android-tools}/bin/adb shell pm list packages -d | sed 's/package:/  /'
    else
      echo "No device connected"
    fi
  '';

  boox-download-firmware = pkgs.writeShellScriptBin "boox-download-firmware" ''
    set -euo pipefail
    URL="http://firmware-us.boox.com/d833df9e7d14802acefd9da0a94fbcf3/update.upx"
    MD5="d833df9e7d14802acefd9da0a94fbcf3"
    OUTPUT="''${1:-update.upx}"
    echo "Downloading Go Color 7 Gen 2 firmware (~1.96 GB)..."
    ${pkgs.curl}/bin/curl -L -o "$OUTPUT" "$URL"
    echo "Verifying checksum..."
    echo "$MD5  $OUTPUT" | md5sum -c
    echo "Done: $OUTPUT"
  '';

  boox-extract-boot = pkgs.writeShellScriptBin "boox-extract-boot" ''
    set -euo pipefail
    INPUT="''${1:-update.zip}"
    OUTPUT_DIR="''${2:-.}"
    echo "Extracting payload.bin from $INPUT..."
    ${pkgs.unzip}/bin/unzip -p "$INPUT" payload.bin > /tmp/payload.bin
    echo "Extracting boot.img..."
    ${pkgs.payload-dumper-go}/bin/payload-dumper-go -p boot -o "$OUTPUT_DIR" /tmp/payload.bin
    rm /tmp/payload.bin
    echo "Done: $OUTPUT_DIR/boot.img"
  '';

  boox-push-magisk = pkgs.writeShellScriptBin "boox-push-magisk" ''
    set -euo pipefail
    MAGISK_VERSION="''${1:-v30.6}"
    MAGISK_URL="https://github.com/topjohnwu/Magisk/releases/download/$MAGISK_VERSION/Magisk-$MAGISK_VERSION.apk"

    echo "Downloading Magisk $MAGISK_VERSION..."
    ${pkgs.curl}/bin/curl -L -o /tmp/Magisk.apk "$MAGISK_URL"

    echo "Installing Magisk on device..."
    ${pkgs.android-tools}/bin/adb install /tmp/Magisk.apk

    echo "Pushing boot.img to device..."
    ${pkgs.android-tools}/bin/adb push boot.img /storage/emulated/0/Download/

    rm /tmp/Magisk.apk
    echo ""
    echo "=== Next Steps ==="
    echo "1. Open Magisk app on device"
    echo "2. Tap Install → Select and Patch a File"
    echo "3. Select /Download/boot.img"
    echo "4. Run: boox-flash-patched"
  '';

  boox-flash-patched = pkgs.writeShellScriptBin "boox-flash-patched" ''
    set -euo pipefail
    echo "Pulling patched boot image from device..."
    PATCHED=$(${pkgs.android-tools}/bin/adb shell ls /storage/emulated/0/Download/magisk_patched*.img 2>/dev/null | tr -d '\r' | head -1)

    if [ -z "$PATCHED" ]; then
      echo "Error: No patched image found. Did you patch boot.img with Magisk?"
      exit 1
    fi

    echo "Found: $PATCHED"
    ${pkgs.android-tools}/bin/adb pull "$PATCHED" ./magisk_patched.img

    echo ""
    echo "Rebooting to fastboot..."
    ${pkgs.android-tools}/bin/adb reboot bootloader
    sleep 10

    echo "Flashing patched boot image..."
    ${pkgs.android-tools}/bin/fastboot flash boot ./magisk_patched.img

    echo ""
    echo "Rebooting device..."
    ${pkgs.android-tools}/bin/fastboot reboot

    echo ""
    echo "=== Done! ==="
    echo "Device should boot with Magisk root access."
  '';

  configDir = ./scripts/boox/config;

  boox-debloat = pkgs.writeShellScriptBin "boox-debloat" ''
    set -euo pipefail

    CONFIG_DIR="${configDir}"
    DRY_RUN=""
    PACKAGES_FILE=""

    usage() {
      echo "Usage: boox-debloat [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --safe       Remove safe bloatware (recommended first)"
      echo "  --optional   Remove optional packages (user preference)"
      echo "  --all        Remove both safe and optional"
      echo "  --dry-run    Show what would be removed without doing it"
      echo "  --list       List packages in each category"
      echo "  -h, --help   Show this help"
    }

    list_packages() {
      echo "=== Safe to Remove ==="
      ${pkgs.gnugrep}/bin/grep -v '^#' "$CONFIG_DIR/packages-safe.txt" | ${pkgs.gnugrep}/bin/grep -v '^$' | ${pkgs.gawk}/bin/awk '{print "  " $1}'
      echo ""
      echo "=== Optional (user preference) ==="
      ${pkgs.gnugrep}/bin/grep -v '^#' "$CONFIG_DIR/packages-optional.txt" | ${pkgs.gnugrep}/bin/grep -v '^$' | ${pkgs.gawk}/bin/awk '{print "  " $1}'
    }

    disable_packages() {
      local file="$1"
      local count=0
      local failed=0

      # Read packages into array first to avoid stdin issues with adb
      local packages=()
      while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        # Extract package name (first word)
        pkg=$(echo "$line" | ${pkgs.gawk}/bin/awk '{print $1}')
        packages+=("$pkg")
      done < "$file"

      for pkg in "''${packages[@]}"; do
        if [ -n "$DRY_RUN" ]; then
          echo "[DRY-RUN] Would disable: $pkg"
          ((count++)) || true
        else
          echo -n "Disabling $pkg... "
          if ${pkgs.android-tools}/bin/adb shell pm disable-user --user 0 "$pkg" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "disabled"; then
            echo "OK"
            ((count++)) || true
          else
            echo "SKIP (not found or already disabled)"
            ((failed++)) || true
          fi
        fi
      done

      echo ""
      if [ -n "$DRY_RUN" ]; then
        echo "Would disable $count packages"
      else
        echo "Disabled $count packages ($failed skipped)"
      fi
    }

    # Parse arguments
    while [[ $# -gt 0 ]]; do
      case $1 in
        --safe)
          PACKAGES_FILE="safe"
          shift
          ;;
        --optional)
          PACKAGES_FILE="optional"
          shift
          ;;
        --all)
          PACKAGES_FILE="all"
          shift
          ;;
        --dry-run)
          DRY_RUN="1"
          shift
          ;;
        --list)
          list_packages
          exit 0
          ;;
        -h|--help)
          usage
          exit 0
          ;;
        *)
          echo "Unknown option: $1"
          usage
          exit 1
          ;;
      esac
    done

    if [ -z "$PACKAGES_FILE" ]; then
      usage
      exit 1
    fi

    # Check device connection
    if ! ${pkgs.android-tools}/bin/adb get-state 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "device"; then
      echo "Error: No device connected"
      exit 1
    fi

    echo "=== Boox Debloat ==="
    [ -n "$DRY_RUN" ] && echo "(DRY RUN - no changes will be made)"
    echo ""

    case "$PACKAGES_FILE" in
      safe)
        disable_packages "$CONFIG_DIR/packages-safe.txt"
        ;;
      optional)
        disable_packages "$CONFIG_DIR/packages-optional.txt"
        ;;
      all)
        echo "--- Safe packages ---"
        disable_packages "$CONFIG_DIR/packages-safe.txt"
        echo ""
        echo "--- Optional packages ---"
        disable_packages "$CONFIG_DIR/packages-optional.txt"
        ;;
    esac
  '';

  boox-restore = pkgs.writeShellScriptBin "boox-restore" ''
    set -euo pipefail

    usage() {
      echo "Usage: boox-restore [OPTIONS] [PACKAGE...]"
      echo ""
      echo "Options:"
      echo "  --all        Re-enable all disabled packages"
      echo "  --list       List currently disabled packages"
      echo "  -h, --help   Show this help"
      echo ""
      echo "Examples:"
      echo "  boox-restore --list"
      echo "  boox-restore com.onyx.calculator"
      echo "  boox-restore --all"
    }

    # Check device connection
    check_device() {
      if ! ${pkgs.android-tools}/bin/adb get-state 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "device"; then
        echo "Error: No device connected"
        exit 1
      fi
    }

    list_disabled() {
      echo "=== Disabled Packages ==="
      ${pkgs.android-tools}/bin/adb shell pm list packages -d | sed 's/package:/  /'
    }

    restore_package() {
      local pkg="$1"
      echo -n "Restoring $pkg... "
      if ${pkgs.android-tools}/bin/adb shell pm enable "$pkg" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "enabled"; then
        echo "OK"
        return 0
      elif ${pkgs.android-tools}/bin/adb shell pm install-existing "$pkg" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "installed"; then
        echo "OK (reinstalled)"
        return 0
      else
        echo "FAILED"
        return 1
      fi
    }

    restore_all() {
      local count=0
      local failed=0

      for pkg in $(${pkgs.android-tools}/bin/adb shell pm list packages -d | sed 's/package://'); do
        pkg=$(echo "$pkg" | tr -d '\r')
        if restore_package "$pkg"; then
          ((count++)) || true
        else
          ((failed++)) || true
        fi
      done

      echo ""
      echo "Restored $count packages ($failed failed)"
    }

    if [[ $# -eq 0 ]]; then
      usage
      exit 1
    fi

    check_device

    case "$1" in
      --all)
        restore_all
        ;;
      --list)
        list_disabled
        ;;
      -h|--help)
        usage
        ;;
      *)
        for pkg in "$@"; do
          restore_package "$pkg"
        done
        ;;
    esac
  '';

  pixel8a-reroot = pkgs.writeShellScriptBin "pixel8a-reroot" ''
    set -euo pipefail

    # Color output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color

    # Device codename
    DEVICE="akita"

    error() {
        echo -e "''${RED}ERROR: $1''${NC}" >&2
        exit 1
    }

    info() {
        echo -e "''${BLUE}>>> $1''${NC}"
    }

    success() {
        echo -e "''${GREEN}✓ $1''${NC}"
    }

    warn() {
        echo -e "''${YELLOW}! $1''${NC}"
    }

    check_adb_device() {
        info "Checking ADB connection..."
        if ! ${pkgs.android-tools}/bin/adb devices | ${pkgs.gnugrep}/bin/grep -q "device$"; then
            error "No device connected. Please connect your Pixel 8a and authorize USB debugging."
        fi
        success "Device connected"
    }

    check_fastboot_device() {
        info "Checking fastboot connection..."
        if ! ${pkgs.android-tools}/bin/fastboot devices | ${pkgs.gnugrep}/bin/grep -q "fastboot"; then
            error "Device not in fastboot mode"
        fi
        success "Device in fastboot mode"
    }

    # Parse arguments
    if [[ $# -ne 1 ]]; then
        echo "Usage: pixel8a-reroot <release-version>"
        echo ""
        echo "Example: pixel8a-reroot 2026011000"
        echo ""
        echo "To find the latest release version:"
        echo "  Visit https://grapheneos.org/releases"
        echo "  Or check your current build: adb shell getprop ro.build.id"
        exit 1
    fi

    RELEASE="$1"
    OTA_FILE="''${DEVICE}-ota-''${RELEASE}.zip"
    OTA_URL="https://releases.grapheneos.org/''${DEVICE}-ota_update-''${RELEASE}.zip"

    info "Pixel 8a GrapheneOS Re-rooting Script"
    info "Release: $RELEASE"
    echo ""

    # Step 1: Download OTA image
    if [[ -f "$OTA_FILE" ]]; then
        warn "OTA file already exists: $OTA_FILE"
        read -p "Download again? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f "$OTA_FILE"
        fi
    fi

    if [[ ! -f "$OTA_FILE" ]]; then
        info "Downloading GrapheneOS OTA image (~1.2 GB)..."
        ${pkgs.curl}/bin/curl -L -o "$OTA_FILE" "$OTA_URL" || error "Failed to download OTA image"
        success "Downloaded OTA image"
    else
        success "Using existing OTA file"
    fi

    # Step 2: Extract init_boot.img
    info "Extracting init_boot.img from payload..."
    ${pkgs.unzip}/bin/unzip -p "$OTA_FILE" payload.bin > payload.bin || error "Failed to extract payload.bin"
    ${pkgs.payload-dumper-go}/bin/payload-dumper-go -p init_boot -o . payload.bin || error "Failed to extract init_boot.img"
    rm -f payload.bin
    success "Extracted init_boot.img"

    # Step 3: Push to device
    check_adb_device
    info "Pushing init_boot.img to device..."
    ${pkgs.android-tools}/bin/adb push init_boot.img /sdcard/Download/init_boot.img || error "Failed to push init_boot.img"
    success "Pushed init_boot.img to /sdcard/Download/"

    # Step 4: Wait for user to patch with Magisk
    echo ""
    warn "==== ACTION REQUIRED ===="
    echo "On your Pixel 8a:"
    echo "  1. Open the Magisk app"
    echo "  2. Tap 'Install' (next to Magisk)"
    echo "  3. Select 'Select and Patch a File'"
    echo "  4. Navigate to Downloads and select 'init_boot.img'"
    echo "  5. Tap 'Let's Go' and wait for patching to complete"
    echo ""
    read -p "Press ENTER when patching is complete..."

    # Step 5: Find and pull patched image
    info "Finding patched image on device..."
    PATCHED_NAME=$(${pkgs.android-tools}/bin/adb shell ls /sdcard/Download/magisk_patched*.img 2>/dev/null | tr -d '\r' | head -1)

    if [[ -z "$PATCHED_NAME" ]]; then
        error "No patched image found. Did you patch the file with Magisk?"
    fi

    info "Found patched image: $(basename $PATCHED_NAME)"
    ${pkgs.android-tools}/bin/adb pull "$PATCHED_NAME" ./magisk_patched_init_boot.img || error "Failed to pull patched image"
    success "Pulled patched init_boot.img"

    # Step 6: Reboot to fastboot
    info "Rebooting to fastboot mode..."
    ${pkgs.android-tools}/bin/adb reboot bootloader
    sleep 10

    # Step 7: Flash to both slots
    check_fastboot_device
    info "Flashing patched init_boot to both slots..."
    ${pkgs.android-tools}/bin/fastboot flash init_boot_a ./magisk_patched_init_boot.img || error "Failed to flash init_boot_a"
    ${pkgs.android-tools}/bin/fastboot flash init_boot_b ./magisk_patched_init_boot.img || error "Failed to flash init_boot_b"
    success "Flashed to init_boot_a and init_boot_b"

    # Step 8: Reboot
    info "Rebooting to Android..."
    ${pkgs.android-tools}/bin/fastboot reboot
    sleep 30

    # Step 9: Verify root
    info "Waiting for device to boot..."
    ${pkgs.android-tools}/bin/adb wait-for-device
    sleep 5

    info "Verifying root access..."
    if ${pkgs.android-tools}/bin/adb shell 'su -c "id"' | ${pkgs.gnugrep}/bin/grep -q "uid=0(root)"; then
        success "Root access verified!"
        echo ""
        success "=== Re-rooting Complete ==="
        echo ""
        info "Your Pixel 8a is now rooted with Magisk"
        info "You can now run your router scripts:"
        echo "  adb shell"
        echo "  su"
        echo "  /data/local/tmp/router-start"
    else
        error "Root verification failed. Please check Magisk app."
    fi

    # Cleanup
    info "Cleaning up temporary files..."
    rm -f payload.bin
    success "Done!"
  '';
in 
pkgs.mkShell {
  name = "boox";
  packages = [
    pkgs.android-tools
    pkgs.curl
    pkgs.unzip
    pkgs.payload-dumper-go
    pkgs.gnugrep
    pkgs.gawk
    pythonEnv
    boox-decrypt-firmware
    boox-extract-boot
    boox-status
    boox-download-firmware
    boox-push-magisk
    boox-flash-patched
    boox-debloat
    boox-restore
    pixel8a-reroot
  ];

  shellHook = ''
    echo "🔖 Android Device Management Shell"
    echo ""
    echo "=== Boox Go Color 7 Gen 2 ==="
    echo "Rooting & Firmware:"
    echo "  boox-status            - Check device connection and root status"
    echo "  boox-download-firmware - Download stock firmware UPX"
    echo "  boox-decrypt-firmware  - Decrypt UPX → update.zip"
    echo "  boox-extract-boot      - Extract boot.img from update.zip"
    echo "  boox-push-magisk       - Install Magisk + push boot.img to device"
    echo "  boox-flash-patched     - Flash Magisk-patched boot image"
    echo ""
    echo "Debloating:"
    echo "  boox-debloat --list    - List packages by category"
    echo "  boox-debloat --safe    - Remove safe bloatware"
    echo "  boox-debloat --dry-run - Preview changes"
    echo "  boox-restore --list    - List disabled packages"
    echo "  boox-restore <pkg>     - Re-enable a package"
    echo ""
    echo "=== Pixel 8a (GrapheneOS) ==="
    echo "  pixel8a-reroot <version> - Re-root after GrapheneOS update"
    echo "                             Example: pixel8a-reroot 2026011000"
    echo ""
    echo "Manual tools: adb, fastboot, payload-dumper-go, python"
    echo ""
  '';
}
