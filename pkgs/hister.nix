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
  version = "0.17.0";

  src = fetchFromGitHub {
    owner = "asciimoo";
    repo = "hister";
    rev = "v${version}";
    hash = "sha256-UIKQVs2hbzalDeRL1ILUgfMQnues5IFrzWn9Eg5sm30=";
  };

  # server/static/static.go embeds `all:app/*`, which webui/build.sh generates
  # from the SvelteKit sources. Build it separately and drop it in preBuild.
  frontend = buildNpmPackage {
    pname = "hister-frontend";
    inherit version src;

    npmWorkspace = "webui/app";
    npmDepsHash = "sha256-l5A+MgAYIhVXgytrn/jmb+oSbx+ndhXK1gj0/UxbM1U=";

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

  vendorHash = "sha256-fZqT0B5T0FtZdkO96hgGwJCAHF0U6Jxw8XWF206mhlQ=";

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
    license = lib.licenses.agpl3Only;
    mainProgram = "hister";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
