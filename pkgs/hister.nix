{
  lib,
  buildGoModule,
  buildNpmPackage,
  fetchFromGitHub,
  installShellFiles,
  makeBinaryWrapper,
  pkg-config,
  sqlite,
  yt-dlp,
}:

let
  version = "0.18.0";

  src = fetchFromGitHub {
    owner = "asciimoo";
    repo = "hister";
    rev = "v${version}";
    hash = "sha256-yX/MGhGyQxE5cSe1Q4T9EEBwRS5mxUBtpkn/RnGN4lU=";
  };

  # server/static/static.go embeds `all:app/*`, which webui/build.sh generates
  # from the SvelteKit sources. Build it separately and drop it in preBuild.
  frontend = buildNpmPackage {
    pname = "hister-frontend";
    inherit version src;

    npmWorkspace = "webui/app";
    npmDepsHash = "sha256-WlN/84qmKSd98xGF/XTbwTt0WFqJgogmy9Kmyjq1DuY=";

    preBuild = ''
      patchShebangs webui
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r webui/app/build/* "$out/"
      runHook postInstall
    '';
  };
in
buildGoModule {
  pname = "hister";
  inherit version src;

  # Upstream nix/package.nix publishes this hash; it assumes proxyVendor.
  vendorHash = "sha256-UR384CLSa44MqPVzzgzGZC/ROdG2iWtJ5L8AX/tfg0k=";
  proxyVendor = true;

  nativeBuildInputs = [
    installShellFiles
    makeBinaryWrapper
    pkg-config
  ];

  buildInputs = [ sqlite ];

  # link mattn/go-sqlite3 against the system sqlite instead of the amalgamation
  tags = [ "libsqlite3" ];

  subPackages = [ "." ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  preBuild = ''
    mkdir -p server/static/app
    cp -r ${frontend}/* server/static/app/
  '';

  postInstall = ''
    wrapProgram $out/bin/hister \
      --prefix PATH : ${lib.makeBinPath [ yt-dlp ]}

    installShellCompletion --cmd hister \
      --fish <($out/bin/hister completion fish)
  '';

  passthru = {
    inherit frontend;
  };

  meta = {
    description = "Web history on steroids";
    homepage = "https://github.com/asciimoo/hister";
    license = lib.licenses.agpl3Plus;
    mainProgram = "hister";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
