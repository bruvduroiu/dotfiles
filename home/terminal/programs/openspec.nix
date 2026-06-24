{ pkgs, ... }:

let
 openspec = pkgs.buildNpmPackage rec {
    pname = "openspec";
    version = "0.14.0";

    src = pkgs.fetchFromGitHub {
      owner = "Fission-AI";
      repo = "OpenSpec";
      rev = "v${version}";
      hash = "sha256-jURQ/vr1CTzyS9I9/ksyH9JL6BRi/gSmJvYhOpR6jNg=";
    };

    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit pname version src;
      fetcherVersion = 3;
      hash = "sha256-BWQwBy2mBvsh4nsEy/ia5k4Ax7oogfjXb+LCb0OBjJI=";
    };

    nativeBuildInputs = with pkgs; [ nodejs pnpm ]; # pnpmConfigHook needs pnpm on PATH
    npmConfigHook = pkgs.pnpmConfigHook;
    npmDeps = pnpmDeps;

    dontNpmPrune = true; # hangs forever on both Linux/darwin

    meta = with pkgs.lib; {
      description = "Spec-driven development framework for AI coding assistants";
      homepage = "https://github.com/Fission-AI/OpenSpec";
      license = licenses.mit;
      mainProgram = "openspec";
      platforms = platforms.all;
    };
  };
in
{
  home.packages = [ openspec ];
}
