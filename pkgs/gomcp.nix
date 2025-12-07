{ pkgs }:

pkgs.stdenv.mkDerivation {
  pname = "gomcp";
  version = "1.0.4";
  
  src = pkgs.fetchurl {
    url = if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86_64 then
      "https://github.com/lightpanda-io/gomcp/releases/download/1.0.4/gomcp-linux-amd64"
    else if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isAarch64 then
      "https://github.com/lightpanda-io/gomcp/releases/download/1.0.4/gomcp-linux-arm64"
    else if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64 then
      "https://github.com/lightpanda-io/gomcp/releases/download/1.0.4/gomcp-darwin-arm64"
    else if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isx86_64 then
      "https://github.com/lightpanda-io/gomcp/releases/download/1.0.4/gomcp-darwin-amd64"
    else
      throw "Unsupported platform for gomcp";
    sha256 = if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86_64 then
      "sha256-A8JEh4aJXcBOqaMLhuiIqjwQVmgZ1gVpcBgsUCp8Qwc="
    else if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isAarch64 then
      "sha256-6tqrTK3+aZSEiXB50+27vovUSNC6v/vRdyQOXWQE866="
    else if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64 then
      "sha256-Ic2PZTPevRMJGMziLN6RUs0rojVG6w5j4MW2qd5FWnI="
    else
      "sha256-fayRe46ro+w6OHrfjMREsBGuekUnc31wKBV/7nWRBS8=";
  };
  
  dontUnpack = true;
  
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/gomcp
    chmod +x $out/bin/gomcp
  '';
  
  meta = {
    description = "Lightpanda MCP server written in Go";
    homepage = "https://github.com/lightpanda-io/gomcp";
    license = pkgs.lib.licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  };
}
