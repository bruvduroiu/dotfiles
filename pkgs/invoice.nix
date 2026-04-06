{
  lib,
  buildGoModule,
  fetchFromGitHub,
  srcHash ? lib.fakeHash,
  vendorHash ? lib.fakeHash,
}:

buildGoModule {
  pname = "invoice";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "seankelman";
    repo = "invoice";
    rev = "main";
    hash = srcHash;
  };

  inherit vendorHash;

  meta = {
    description = "Command line invoice generator";
    homepage = "https://github.com/seankelman/invoice";
    license = lib.licenses.mit;
    mainProgram = "invoice";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
