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
  version = "0.20.0";
  hash = "sha256-8FKieCq7T87wIawCjVoto2kX1PU2sV1LFQtz2nydzBM=";

  src = fetchFromGitHub {
    owner = "asciimoo";
    repo = "hister";
    rev = "v${version}";
    inherit hash;
  };

  # server/static/static.go embeds `all:app/*`, which webui/build.sh generates
  # from the SvelteKit sources. Build it separately and drop it in preBuild.
  frontend = buildNpmPackage {
    pname = "hister-frontend";
    inherit version src;

    npmWorkspace = "webui/app";
    npmDepsHash = "sha256-ho0iMiA0GPI4h8ylRMT/oFXUIO9K893osAnBe4/FV70=";

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
  vendorHash = "sha256-piPns+kq6ZCM4Bpe7nzdjHjkZKe1VV6UY9IIMshNGpo=";
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

    # hister ≥0.20 creates its data dir on every invocation; $HOME is unwritable here
    installShellCompletion --cmd hister \
      --fish <(HISTER_DATA_DIR=$TMPDIR/hister $out/bin/hister completion fish)
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
