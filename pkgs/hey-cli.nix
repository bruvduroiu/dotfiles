{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
}:
let
  version = "1.10.1";

  # Upstream's goreleaser builds are static (CGO off); no ELF patching needed.
  binaries = {
    x86_64-linux = {
      arch = "linux_amd64";
      hash = "sha256-3Xj86YHs+8vziDbthQr6FRBzgRm0jF1GTbVDWZLbhK8=";
    };
    aarch64-linux = {
      arch = "linux_arm64";
      hash = "sha256-iru02rxwVlPwjMWVwiC0SXShU1TE+iUGIkagKEyKubA=";
    };
  };
  binary =
    binaries.${stdenvNoCC.hostPlatform.system}
      or (throw "hey-cli: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
# Attribute is hey-cli, not hey: nixpkgs' `hey` is the HTTP load generator.
stdenvNoCC.mkDerivation {
  pname = "hey-cli";
  inherit version;

  src = fetchurl {
    url = "https://github.com/basecamp/hey-cli/releases/download/v${version}/hey_${version}_${binary.arch}.tar.gz";
    inherit (binary) hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = [ installShellFiles ];

  # The tarball carries pre-generated completions, so `hey shell-completion
  # install` (which writes into ~/.config) is never needed.
  installPhase = ''
    runHook preInstall
    install -Dm755 hey $out/bin/hey
    installShellCompletion --cmd hey \
      --bash completions/hey.bash \
      --fish completions/hey.fish \
      --zsh completions/_hey
    runHook postInstall
  '';

  meta = {
    description = "CLI, TUI and MCP server for HEY email and calendar";
    homepage = "https://github.com/basecamp/hey-cli";
    license = lib.licenses.mit;
    mainProgram = "hey";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames binaries;
  };
}
