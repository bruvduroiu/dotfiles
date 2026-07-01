{
  lib,
  python3,
  makeBinaryWrapper,
  stdenv,
}:

let
  pythonEnv = python3.withPackages (ps: [
    ps.odfpy
    ps.requests
  ]);
in
stdenv.mkDerivation {
  pname = "portfolio-tracker";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ makeBinaryWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/portfolio-tracker
    mkdir -p $out/bin

    cp update-prices.py $out/lib/portfolio-tracker/update-prices.py

    makeBinaryWrapper ${pythonEnv}/bin/python3 $out/bin/portfolio-update-prices \
      --add-flags "$out/lib/portfolio-tracker/update-prices.py"

    runHook postInstall
  '';

  meta = {
    description = "Refresh portfolio-tracker.ods stock prices from Alpha Vantage";
    license = lib.licenses.mit;
    mainProgram = "portfolio-update-prices";
    platforms = lib.platforms.linux;
  };
}
