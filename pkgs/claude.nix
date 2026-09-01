{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  nodejs,
  typescript,
  typescript-language-server,
  gopls,
  go,
  pyright,
  version,
  hashes,
}:
let
  lspServers = [
    typescript-language-server
    typescript
    gopls
    go
    pyright
    nodejs
  ];

  # Nix system -> the release bucket's platform directory name.
  platformDirs = {
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
  };

  inherit (stdenv.hostPlatform) system;
  platformDir = platformDirs.${system} or (throw "Unsupported system: ${system}");
  hash = hashes.${system} or (throw "No hash provided for system: ${system}");
  bucket = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
in
stdenv.mkDerivation {
  pname = "claude-code";
  inherit version;

  src = fetchurl {
    url = "${bucket}/${version}/${platformDir}/claude";
    inherit hash;
  };

  # Don't try to unpack - it's a single binary
  dontUnpack = true;

  # autoPatchelfHook rewrites the prebuilt binary's ELF interpreter;
  # makeWrapper puts the LSP servers on claude's PATH.
  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
  ];

  # autoPatchelfHook needs these for dynamic linking
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall

    install -D -m755 $src $out/bin/claude

    runHook postInstall
  '';

  # Suffix the language servers so a project-local copy still takes precedence,
  # but Claude Code's *-lsp plugins always find a server to spawn.
  postInstall = ''
    wrapProgram $out/bin/claude \
      --suffix PATH : ${lib.makeBinPath lspServers}
  '';

  # Skip fixup phases that don't apply to pre-built binaries
  dontStrip = true;

  meta = {
    description = "Claude Code - Anthropic's official CLI for Claude";
    homepage = "https://claude.ai/claude-code";
    license = lib.licenses.unfree;
    mainProgram = "claude";
    platforms = builtins.attrNames platformDirs;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
