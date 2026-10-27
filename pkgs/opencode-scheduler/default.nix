{ lib, stdenvNoCC, fetchurl, nodejs, systemd, profileDirectory }:

stdenvNoCC.mkDerivation {
  pname = "opencode-scheduler";
  version = "1.3.0";
  src = fetchurl {
    url = "https://raw.githubusercontent.com/different-ai/opencode-scheduler/cd0b62364792f53e8687db53bc2c2c0261c9cf17/dist/index.js";
    hash = "sha256-gqeikqq2doVboos6d2E8pCy/lxFiJFmvtim1+oXfYNc=";
  };
  dontUnpack = true;
  nativeBuildInputs = [ nodejs systemd ];
  buildPhase = ''
    cp $src upstream.js
    chmod u+w upstream.js
    patch -p1 < ${./nixos.patch}
    substituteInPlace upstream.js \
      --replace-fail '@perl@' '${profileDirectory}/bin/perl' \
      --replace-fail '@opencode@' '${profileDirectory}/bin/opencode' \
      --replace-fail '@runtimePath@' '${profileDirectory}/bin:/run/current-system/sw/bin'
    cp ${./adapter.js} index.js
    echo '{"name":"opencode-scheduler","version":"1.3.0","type":"module","exports":"./index.js"}' > package.json
    node --check upstream.js
    node --check index.js
    cp ${./test.mjs} test.mjs
    node test.mjs
  '';
  installPhase = ''
    mkdir -p $out
    cp upstream.js index.js package.json $out/
    cp ${./LICENSE} $out/LICENSE
  '';
  meta = {
    description = "Local systemd scheduling tools for OpenCode and OpenWork";
    homepage = "https://github.com/different-ai/opencode-scheduler";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
