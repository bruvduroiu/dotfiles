{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation {
  pname = "mcp-grafana";
  version = "2.2.0";
  # Official static release, pinned independently of the fleet nixpkgs.
  src = fetchurl {
    url = "https://github.com/grafana/mcp-grafana/releases/download/v2.2.0/mcp-grafana_Linux_x86_64.tar.gz";
    sha256 = "f93bfbd94cde68cc2e43cf5ba55da4f8e28b1a36b14fb14dadd566fc36b1312b";
  };
  sourceRoot = ".";
  installPhase = ''
    runHook preInstall
    install -Dm755 mcp-grafana $out/bin/mcp-grafana
    runHook postInstall
  '';
  meta = {
    description = "Official Grafana MCP server (pinned static release)";
    homepage = "https://github.com/grafana/mcp-grafana";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "mcp-grafana";
  };
}
