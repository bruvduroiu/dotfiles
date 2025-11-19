{
  lib,
  stdenv,
  fetchFromGitHub,
  bun,
  nodejs,
  makeBinaryWrapper,
}:

let
  pname = "gh-actions-language-server";
  version = "unstable-2025-11-18";
  
  src = fetchFromGitHub {
    owner = "lttb";
    repo = "gh-actions-language-server";
    rev = "0287d3081d7b74fef88824ca3bd6e9a44323a54d";
    hash = "sha256-ZWO5G33FXGO57Zca5B5i8zaE8eFbBCrEtmwwR3m1Px4=";
  };

  node_modules = stdenv.mkDerivation {
    pname = "${pname}-node-modules";
    inherit version src;

    nativeBuildInputs = [ bun ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR
      bun install --frozen-lockfile --no-progress

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r node_modules $out/

      runHook postInstall
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-WXMIUvdiels1NimJCYZiPA9M7NO64jVi6Ifw5HjDc3o=";
  };
in 

stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    bun
    nodejs
    makeBinaryWrapper
  ];

  configurePhase = ''
    runHook preConfigure

    ln -s ${node_modules}/node_modules node_modules

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR
    bun run build:node

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/gh-actions-language-server
    mkdir -p $out/bin

    # Copy source files and dependencies
    cp -r . $out/lib/gh-actions-language-server/
    rm $out/lib/gh-actions-language-server/node_modules
    cp -r ${node_modules}/node_modules $out/lib/gh-actions-language-server/

    # Create wrapper script
    makeBinaryWrapper ${nodejs}/bin/node $out/bin/gh-actions-language-server \
      --add-flags "$out/lib/gh-actions-language-server/bin/gh-actions-language-server"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Language server for GitHub Actions workflows";
    homepage = "https://github.com/lttb/gh-actions-language-server";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "gh-actions-language-server";
    platforms = platforms.all;
  };
}
