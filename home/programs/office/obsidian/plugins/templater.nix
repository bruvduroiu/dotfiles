{ pkgs, ... }:
pkgs.buildNpmPackage rec {
  pname = "obsidian.plugins.templater";
  version = "2.16.2";

  src = pkgs.fetchFromGitHub {
    owner = "SilentVoid13";
    repo = "Templater";
    rev = version;
    hash = "sha256-jFELX0gW0aLW/eY685hMBgrbECNMqg0zbumpF2q0HFk=";
  };

  pnpmDeps = pkgs.fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 3;
    hash = "sha256-xI6Hz6UPgz+4B6w3cxVsTuYpgPwwpSkgWgdadPeR8XM=";
  };

  nativeBuildInputs = with pkgs; [ nodejs pnpm ]; # pnpmConfigHook needs pnpm on PATH (pnpm.configHook used to add it)

  npmConfigHook = pkgs.pnpmConfigHook;
  npmDeps = pnpmDeps;

  dontNpmPrune = true; # hangs forever on both Linux/darwin

  installPhase = ''
    mkdir -p $out
    cp ./manifest.json $out/manifest.json
    cp ./main.js $out/main.js
    cp ./styles.css $out/styles.css
  '';
}
