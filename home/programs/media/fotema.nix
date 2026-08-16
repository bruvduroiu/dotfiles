{ pkgs, ... }:
# Fotema — local photo library ("iPhoto for this laptop").
#
# Deliberately NOT a server. It runs as bogdan, so ~/Pictures is reachable by
# ordinary file permissions and nothing listens on any socket. The obvious
# alternative, Immich, is a Postgres + Redis + ML-worker stack whose unit runs
# as a system user under ProtectHome=true — reaching a library in $HOME means
# either weakening that hardening and chmod'ing /home/bogdan off 0700, or
# copying every photo into /var/lib/immich. Both are a lot of moving parts for
# a gallery only this machine ever opens.
#
# HEIC (the iPhone half of the library) works without extra config: the
# derivation wires in libglycin's setup hook, so glycin-loaders and libheif are
# in the runtime closure.
#
# Face detection is local — onnxruntime + opencv, already in the closure — and
# runs as a background scan on first launch, so expect one burst of CPU.
{
  home.packages = [ pkgs.fotema ];

  # Settings are gsettings keys under app.fotema.Fotema; dconf is already the
  # backend here (system/programs: dconf.enable, and home/theme/stylix.nix
  # writes org/gnome/desktop/interface the same way).
  dconf.settings."app/fotema/Fotema" = {
    # "Off" | "Mobile" | "Desktop" — the last is the heavier, more accurate
    # model pair, which this machine can afford.
    face-detection-mode = "Desktop";
  };

  # NB: the library root lives in `pictures-base-dir-b64`, left unset on
  # purpose. It stores a base64-encoded *sandbox* view of the chosen path (a
  # Flatpak portal detail, default '/var/empty'), so a hand-written value risks
  # a silently empty gallery. Pick ~/Pictures in the first-run dialog instead.
}
