{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_24,
  makeWrapper,
  bash,
  git,
  jujutsu,
  jq,
  xdg-utils,
}:

buildNpmPackage {
  pname = "skepsis";
  version = "0.5.0-unstable-2026-10-25";

  src = fetchFromGitHub {
    owner = "oxidecomputer";
    repo = "skepsis";
    rev = "025e3949d648de318a272f020283d290d380f8cd";
    hash = "sha256-9qdUjjgWj6XFwvFlU5O9hC6O9FTa5lxe9f4uaf/hq60=";
  };

  nodejs = nodejs_24;
  npmDepsHash = "sha256-htiB2eWfjVDU4p/3kgPEE0H/ILKjbCDQ2VNL8FtQ10s=";
  nativeBuildInputs = [ makeWrapper ];
  nativeCheckInputs = [
    git
    jujutsu
  ];

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    npm run tsc
    npm test
    runHook postCheck
  '';

  # Upstream bundles the server and frontend; no npm or network access is
  # needed at runtime. sh is used by optional --send/--open-cmd commands.
  postInstall = ''
    wrapProgram "$out/bin/skepsis" --prefix PATH : ${
      lib.makeBinPath [
        bash
        git
        jujutsu
        jq
        xdg-utils
      ]
    }
  '';

  meta = {
    description = "Local browser-based diff review for jj and git";
    homepage = "https://github.com/oxidecomputer/skepsis";
    license = lib.licenses.mpl20;
    mainProgram = "skepsis";
    platforms = lib.platforms.linux;
  };
}
