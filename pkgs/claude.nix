{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
let
  version = "2.1.33";

  # Platform-specific binary info from manifest.json
  platforms = {
    "x86_64-linux" = {
      platform = "linux-x64";
      hash = "sha256-yGVZMfNf6WPPACqnuiwhSXCFB0i/HaUkD5eUDC/Yg1w=";
    };
    "aarch64-linux" = {
      platform = "linux-arm64";
      hash = "sha256-fvYn5nAuCFXQD0TvmBjyPguWVks+lBc/LsJE/PZZkHs=";
    };
    "x86_64-darwin" = {
      platform = "darwin-x64";
      hash = "sha256-6BkBKtcIhUx4e1Pi8pF/IJASHyMyelDuiVDugo++rhg=";
    };
    "aarch64-darwin" = {
      platform = "darwin-arm64";
      hash = "sha256-QWegdXiZqUumCrfYFfaHSi27cJntuBjq9bRE7R9BLt0=";
    };
  };

  platformInfo = platforms.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
  bucket = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
in
stdenv.mkDerivation {
  pname = "claude-code";
  inherit version;

  src = fetchurl {
    url = "${bucket}/${version}/${platformInfo.platform}/claude";
    hash = platformInfo.hash;
  };

  # Don't try to unpack - it's a single binary
  dontUnpack = true;

  # Linux needs autoPatchelfHook to fix the interpreter
  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];

  # autoPatchelfHook needs these for dynamic linking
  buildInputs = lib.optionals stdenv.isLinux [
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    install -D -m755 $src $out/bin/claude

    runHook postInstall
  '';

  # Skip fixup phases that don't apply to pre-built binaries
  dontStrip = true;

  meta = {
    description = "Claude Code - Anthropic's official CLI for Claude";
    homepage = "https://claude.ai/claude-code";
    license = lib.licenses.unfree;
    mainProgram = "claude";
    platforms = builtins.attrNames platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
