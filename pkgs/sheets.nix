{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "0.3.0";

  # Upstream's goreleaser builds are static (CGO off); no ELF patching needed.
  binaries = {
    x86_64-linux = {
      arch = "Linux_x86_64";
      hash = "sha256-JDablY3nmYmDLaScwlvwD6+w9b8BGXYeo9u7+ip17a8=";
    };
    aarch64-linux = {
      arch = "Linux_arm64";
      hash = "sha256-ItYVy6uDqBqU1ucPohLQIY+aKy3lAYWv+IFKzUazdqo=";
    };
  };
  binary =
    binaries.${stdenvNoCC.hostPlatform.system}
      or (throw "sheets: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "sheets";
  inherit version;

  src = fetchurl {
    url = "https://github.com/maaslalani/sheets/releases/download/v${version}/sheets_${binary.arch}.tar.gz";
    inherit (binary) hash;
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 sheets $out/bin/sheets
    runHook postInstall
  '';

  meta = {
    description = "Terminal based spreadsheet tool";
    homepage = "https://github.com/maaslalani/sheets";
    license = lib.licenses.mit;
    mainProgram = "sheets";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames binaries;
  };
}
