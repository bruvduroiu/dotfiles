{
  lib,
  python3,
  playwright-driver,
  makeBinaryWrapper,
  stdenv,
}:

let
  pythonEnv = python3.withPackages (ps: [
    ps.playwright
  ]);
in
stdenv.mkDerivation {
  pname = "uber-receipts";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ makeBinaryWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/uber-receipts
    mkdir -p $out/bin

    cp scraper.py $out/lib/uber-receipts/scraper.py

    makeBinaryWrapper ${pythonEnv}/bin/python3 $out/bin/uber-receipts \
      --add-flags "$out/lib/uber-receipts/scraper.py" \
      --set PLAYWRIGHT_BROWSERS_PATH "${playwright-driver.browsers}"

    runHook postInstall
  '';

  meta = {
    description = "Download Uber receipt PDFs matched to bank transaction IDs";
    license = lib.licenses.mit;
    mainProgram = "uber-receipts";
    platforms = lib.platforms.linux;
  };
}
