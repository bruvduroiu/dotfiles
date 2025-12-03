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

  pnpmDeps = pkgs.pnpm.fetchDeps {
    inherit pname version src;
    fetcherVersion = 2;
    hash = "sha256-FwqdZ9IoOUrgDJlaEpLvxEQYG2QJQ5imMOpoXgWjQSE=";
  };

  nativeBuildInputs = with pkgs; [ nodejs ];

  npmConfigHook = pkgs.pnpm.configHook;
  npmDeps = pnpmDeps;

  dontNpmPrune = true; # hangs forever on both Linux/darwin

  installPhase = ''
    mkdir -p $out
    cp ./manifest.json $out/manifest.json
    cp ./main.js $out/main.js
    cp ./styles.css $out/styles.css
  '';
}
