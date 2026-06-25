{ pkgs, ... }:
pkgs.buildNpmPackage rec {
  pname = "obsidian.plugins.maps";
  version = "0.1.6";

  src = pkgs.fetchFromGitHub {
    owner = "obsidianmd";
    repo = "obsidian-maps";
    rev = version;
    hash = "sha256-KYWgPu08tV4vMpTZt4ygcenel1JBsXWdh7VFl9vVuU8=";
  };

  # obsidian-maps ships package-lock.json (npm), not pnpm-lock.yaml.
  npmDepsHash = "sha256-KGTRLJkbJU8BXED6ziEFlSTLXNHPYIE6pWoWxiQXSMU=";

  nativeBuildInputs = with pkgs; [ nodejs ];

  dontNpmPrune = true; # hangs forever on both Linux/darwin

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp manifest.json main.js styles.css $out/
    runHook postInstall
  '';
}
