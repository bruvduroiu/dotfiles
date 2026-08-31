{ pkgs, ... }:
pkgs.buildNpmPackage rec {
  pname = "obsidian.plugins.helix";
  version = "0.1.13";

  src = pkgs.fetchFromGitHub {
    owner = "obsidian-helix";
    repo = "obsidian-helix";
    rev = version;
    hash = "sha256-E1y2UBln3UaNPirhC4gLE9RaREZ0/fwffjM6NPHJ9YU=";
  };

  # Ships package-lock.json (npm), like obsidian-maps — not pnpm.
  npmDepsHash = "sha256-xT15bel0ayz0MMUB9mgsou5yZr8UCJYaYsKopkCYs4s=";

  nativeBuildInputs = with pkgs; [ nodejs ];

  dontNpmPrune = true; # hangs forever on both Linux/darwin

  # `npm run build` is `tsc -noEmit && esbuild production` -> bundles main.js.
  # No styles.css in this plugin (the release zip is main.js + manifest.json
  # only), so unlike templater/maps there is nothing else to copy.
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp manifest.json main.js $out/
    runHook postInstall
  '';
}
