{ lib, pkgs, ... }:
let
  happy = pkgs.mkYarnPackage rec {
    pname = "happy-cli";
    version = "0.11.2";

    src = pkgs.fetchFromGitHub {
      owner = "slopus";
      repo = "happy-cli";
      rev = "v${version}";
      hash = "sha256-WKzbpxHqE3Dxqy/PDj51tM9+Wl2Pallfrc5UU2MxNn8=";
    };

    offlineCache = pkgs.fetchYarnDeps {
      yarnLock = "${src}/yarn.lock";
      hash = "sha256-3/qcbCJ+Iwc+9zPCHKsCv05QZHPUp0it+QR3z7m+ssw=";
    };

    buildPhase = ''
      runHook preBuild
      yarn --offline build
      runHook postBuild
    '';

    postInstall = ''
      wrapProgram $out/bin/happy \
        --prefix PATH : ${lib.makeBinPath [ pkgs.nodejs pkgs.claude-code ]}
    '';

    nativeBuildInputs = [ pkgs.makeWrapper ];

    meta = {
      description = "Happy Coder CLI to connect your local Claude Code to mobile device";
      homepage = "https://github.com/slopus/happy-cli";
      license = lib.licenses.mit;
      mainProgram = "happy";
      platforms = lib.platforms.unix;
    };
  };
in
{
  home.packages = [ happy ];
}
