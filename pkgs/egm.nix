{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

# The whole plugin tree, not just skills/: the skills read agents/ and
# resources/document_standards/ at run time, and the repository root is
# itself the plugin for both Claude Code and Codex (docs/harnesses.md).
stdenvNoCC.mkDerivation rec {
  pname = "egm";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "google";
    repo = "elephant-goldfish-model";
    rev = "v${version}";
    hash = "sha256-pg7ceIy3Maf6cLK2j3ABFC0CPlXhRMssOUiSjFJdCl4=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    cp -r . $out
    runHook postInstall
  '';

  meta = {
    description = "Elephant-Goldfish Model: agent skills for drafting specs, reviewing designs and checking drift";
    homepage = "https://github.com/google/elephant-goldfish-model";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
  };
}
