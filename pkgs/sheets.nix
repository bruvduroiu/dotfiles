{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  srcHash ? lib.fakeHash,
  vendorHash ? lib.fakeHash,
}:

buildGoModule {
  pname = "sheets";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "maaslalani";
    repo = "sheets";
    rev = "main";
    hash = srcHash;
  };

  inherit vendorHash;

  doCheck = false;

  nativeBuildInputs = [ installShellFiles ];

  meta = {
    description = "Terminal based spreadsheet tool";
    homepage = "https://github.com/maaslalani/sheets";
    license = lib.licenses.mit;
    mainProgram = "sheets";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
