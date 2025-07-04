final: prev: {
  opencode = prev.opencode.overrideAttrs (oldAttrs: {
    version = "0.1.189";
    src = prev.fetchFromGitHub {
      owner = "opencode-ai";
      repo = "opencode";
      tag = "v0.1.189";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; 
    };
    vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  });
}
