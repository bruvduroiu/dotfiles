{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "tailsnitch";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "Adversis";
    repo = "tailsnitch";
    rev = "v${version}";
    hash = "sha256-LvAOIDM1YIB4LmOm6zXrzr5SOH7tyF4t79XCLDg6p2Q=";
  };

  vendorHash = "sha256-khw9K4sKhubhkccoC4f923Aw2Cj9eKpVqLHZICdkTXw=";

  meta = {
    description = "A security auditor for Tailscale configurations";
    homepage = "https://github.com/Adversis/tailsnitch";
    license = lib.licenses.mit;
    mainProgram = "tailsnitch";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
