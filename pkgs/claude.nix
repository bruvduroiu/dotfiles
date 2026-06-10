{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  # Language servers spawned from $PATH by the *-lsp Claude Code plugins.
  # The plugins ship no binaries of their own — they shell out to these.
  nodejs,
  typescript,
  typescript-language-server,
  gopls,
  go,
  pyright,
}:
let
  version = "2.1.170";

  # Servers the typescript-lsp / gopls-lsp / pyright-lsp plugins expect on PATH.
  # nodejs backs the JS-based servers; `typescript` provides tsserver; `go`
  # lets gopls run `go list` for full analysis.
  lspServers = [
    typescript-language-server
    typescript
    gopls
    go
    pyright
    nodejs
  ];

  # Platform-specific binary info from manifest.json
  platforms = {
    "x86_64-linux" = {
      platform = "linux-x64";
      hash = "sha256-hJ4AcnegRCqydXDT49bUN4dQeUZZDo3RlH5aObcIH54=";
    };
    "aarch64-linux" = {
      platform = "linux-arm64";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
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

  # Linux needs autoPatchelfHook to fix the interpreter;
  # makeWrapper puts the LSP servers on claude's PATH.
  nativeBuildInputs = [ makeWrapper ] ++ lib.optionals stdenv.isLinux [ autoPatchelfHook ];

  # autoPatchelfHook needs these for dynamic linking
  buildInputs = lib.optionals stdenv.isLinux [
    stdenv.cc.cc.lib
  ];

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
    platforms = builtins.attrNames platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
