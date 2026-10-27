{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeBinaryWrapper,
  coreutils,
  findutils,
  fzf,
  gawk,
  gnugrep,
  gnused,
  python3Minimal,
  systemd,
  zellij,
}:

# lazy-zellij: fzf session picker (lzj), imperative helper (zj) and the
# snapshot job feeding the picker's preview. Upstream's install.sh copies the
# scripts to ~/.local/bin and seds the systemd units; here the scripts are
# wrapped with their tools and the units live in the zellij HM module.
stdenvNoCC.mkDerivation {
  pname = "lazy-zellij";
  version = "0-unstable-2026-06-10";

  src = fetchFromGitHub {
    owner = "Logos-Flux";
    repo = "lazy-zellij";
    rev = "3a44fb261ed03aa674003ae04c239a172b39b37e";
    hash = "sha256-1GB+iZ3jWjG+ZXENYh1X1GYUY8gI0F3dp4QZWyyn4Hw=";
  };

  nativeBuildInputs = [ makeBinaryWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # ctrl-p's fallback when the snapshot unit can't be started. find -L:
    # Home Manager's layouts are symlinks, which `-type f` skips.
    substituteInPlace bin/lzj \
      --replace-fail '"$HOME/.local/bin/lzj-snapshot"' "$out/bin/lzj-snapshot" \
      --replace-fail 'find "$LAYOUT_DIR"' 'find -L "$LAYOUT_DIR"'

    # zellij 0.45 takes the dump path as --path; the positional form upstream
    # wrote against 0.43/0.44 errors out, so no snapshot was ever written.
    substituteInPlace bin/lzj-snapshot \
      --replace-fail 'action dump-screen "$tmp"' 'action dump-screen --path "$tmp"'

    install -Dm755 -t "$out/bin" bin/lzj bin/zj bin/lzj-snapshot
    for f in "$out"/bin/*; do
      wrapProgram "$f" --prefix PATH : ${
        lib.makeBinPath [
          coreutils
          findutils
          fzf
          gawk
          gnugrep
          gnused
          python3Minimal
          systemd
          zellij
        ]
      }
    done

    runHook postInstall
  '';

  meta = {
    description = "fzf-based session manager for zellij";
    homepage = "https://github.com/Logos-Flux/lazy-zellij";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
