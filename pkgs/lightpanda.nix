{ pkgs }:

pkgs.stdenv.mkDerivation {
  pname = "lightpanda";
  version = "nightly";
  
  src = pkgs.fetchurl {
    url = if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86_64 then
      "https://github.com/lightpanda-io/browser/releases/download/nightly/lightpanda-x86_64-linux"
    else if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isAarch64 then
      "https://github.com/lightpanda-io/browser/releases/download/nightly/lightpanda-aarch64-linux"
    else if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64 then
      "https://github.com/lightpanda-io/browser/releases/download/nightly/lightpanda-aarch64-macos"
    else if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isx86_64 then
      "https://github.com/lightpanda-io/browser/releases/download/nightly/lightpanda-x86_64-macos"
    else
      throw "Unsupported platform for Lightpanda";
    sha256 = if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86_64 then
      "sha256-cIQJXyH3SxG+MSUHGRHMjAGEYu/o9tmihFP6lOITh9E="
    else if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isAarch64 then
      "sha256-0000000000000000000000000000000000000000000="
    else if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64 then
      "sha256-0000000000000000000000000000000000000000000="
    else
      "sha256-0000000000000000000000000000000000000000000=";
  };
  
  dontUnpack = true;
  
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/lightpanda
    chmod +x $out/bin/lightpanda
  '';
  
  meta = {
    description = "Lightweight headless browser for web scraping and automation";
    homepage = "https://lightpanda.io";
    license = pkgs.lib.licenses.agpl3Only;
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  };
}
