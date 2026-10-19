{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
}:
let
  version = "0.15.1";
  baseUrl = "https://github.com/shshemi/tabiew/releases/download/v${version}";

  # Upstream's static musl builds; no ELF patching needed on NixOS.
  binaries = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-QE7Nn2jCnYnAIFrPQNa2OX/VzA0ZMj5RJEx4tPZRpZM=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-pXB2IsjMJgcbkfuikm7ChsbEMw5wKBbqG95sHDZALxM=";
    };
  };
  binary =
    binaries.${stdenvNoCC.hostPlatform.system}
      or (throw "tabiew: unsupported system ${stdenvNoCC.hostPlatform.system}");

  extras = fetchurl {
    url = "${baseUrl}/tabiew-manual-and-completions.tar.gz";
    hash = "sha256-tChSAZRQ9jOdnRtVd0XJlKg3NTBdLhYDYPfCYEQetls=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "tabiew";
  inherit version;

  src = fetchurl {
    url = "${baseUrl}/tw-${binary.target}";
    inherit (binary) hash;
  };

  dontUnpack = true;

  nativeBuildInputs = [ installShellFiles ];

  outputs = [
    "out"
    "man"
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 $src $out/bin/tw

    tar xzf ${extras}
    installManPage manual/tabiew.1
    installShellCompletion \
      --bash completion/tw.bash \
      --zsh completion/_tw \
      --fish completion/tw.fish

    runHook postInstall
  '';

  meta = {
    description = "Lightweight, terminal-based application to view and query delimiter separated value formatted documents, such as CSV and TSV files";
    homepage = "https://github.com/shshemi/tabiew";
    changelog = "https://github.com/shshemi/tabiew/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "tw";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames binaries;
  };
}
