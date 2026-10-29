{
  lib,
  grayjay,
  bubblewrap,
  symlinkJoin,
  writeShellScript,
}:
# Grayjay runs third-party source plugins (JS in an in-process ClearScript V8)
# and launches its CEF UI with a hardcoded --no-sandbox, so the whole process
# tree gets an outer bubblewrap sandbox instead. Inside, $HOME only contains
# Grayjay's own data dir plus read-only theming; no D-Bus session bus (it would
# let the app ask systemd --user to run anything outside the sandbox) and a
# cleared environment, so direnv/sops-exported tokens never reach it.
let
  launcher = writeShellScript "grayjay-bwrap" ''
    set -euo pipefail

    : "''${HOME:?}" "''${XDG_RUNTIME_DIR:?}" "''${WAYLAND_DISPLAY:?}"
    data_home="''${XDG_DATA_HOME:-$HOME/.local/share}"
    mkdir -p "$data_home/Grayjay"

    args=(
      --unshare-all --share-net
      --die-with-parent --new-session
      --clearenv

      --ro-bind /nix/store /nix/store
      --ro-bind-try /run/current-system /run/current-system
      --ro-bind-try /run/opengl-driver /run/opengl-driver
      --ro-bind-try "/etc/profiles/per-user/$USER" "/etc/profiles/per-user/$USER"
      --proc /proc
      --dev /dev
      --dev-bind-try /dev/dri /dev/dri
      --tmpfs /tmp
    )

    # GPU probing in Chromium walks sysfs; the same subset Flatpak exposes.
    for p in /sys/block /sys/bus /sys/class /sys/dev /sys/devices; do
      args+=(--ro-bind-try "$p" "$p")
    done

    # bwrap resolves a symlinked bind source, but not symlinks *inside* a bound
    # dir (/etc/ssl/certs/* -> /etc/static/...), so /etc/static (store) too.
    args+=(--ro-bind-try /etc/static /etc/static)
    # CEF can't find libpulse (not on its LD_LIBRARY_PATH or RUNPATH), so
    # Chromium uses ALSA; /etc/alsa/conf.d routes ALSA's default PCM to the
    # pipewire-0 socket. Without it ALSA looks for /dev/snd and plays nothing.
    for p in alsa fonts ssl pki resolv.conf hosts nsswitch.conf localtime zoneinfo \
             machine-id passwd group; do
      args+=(--ro-bind-try "/etc/$p" "/etc/$p")
    done

    args+=(
      --perms 0700 --dir "$XDG_RUNTIME_DIR"
      --ro-bind "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
      --ro-bind-try "$XDG_RUNTIME_DIR/pipewire-0" "$XDG_RUNTIME_DIR/pipewire-0"
      --ro-bind-try "$XDG_RUNTIME_DIR/pulse/native" "$XDG_RUNTIME_DIR/pulse/native"
    )

    for p in .icons .local/share/icons .local/share/fonts .config/gtk-3.0 .config/fontconfig; do
      args+=(--ro-bind-try "$HOME/$p" "$HOME/$p")
    done
    args+=(--bind "$data_home/Grayjay" "$data_home/Grayjay")

    args+=(
      --setenv HOME "$HOME"
      --setenv USER "''${USER:-$(id -un)}"
      --setenv XDG_DATA_HOME "$data_home"
      --setenv XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR"
      --setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY"
      --setenv XDG_SESSION_TYPE wayland
    )
    for v in LANG LC_ALL LOCALE_ARCHIVE TZDIR XDG_CURRENT_DESKTOP XDG_DATA_DIRS \
             XCURSOR_THEME XCURSOR_SIZE XCURSOR_PATH GTK_THEME; do
      if [[ -n "''${!v:-}" ]]; then
        args+=(--setenv "$v" "''${!v}")
      fi
    done

    exec ${lib.getExe' bubblewrap "bwrap"} "''${args[@]}" -- ${lib.getExe grayjay} "$@"
  '';
in
symlinkJoin {
  name = "grayjay-sandboxed-${grayjay.version}";
  paths = [ grayjay ];
  # The .desktop entry runs `Grayjay` from $PATH, so replacing the binary is
  # enough for the launcher to go through the sandbox too.
  postBuild = ''
    rm $out/bin/Grayjay
    ln -s ${launcher} $out/bin/Grayjay
  '';
  passthru.unwrapped = grayjay;
  inherit (grayjay) meta;
}
