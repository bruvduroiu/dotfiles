{ self, ... }:

{
  nixpkgs = {
    config.allowUnfree = true;
    config.permittedInsecurePackages = [
      "electron-25.9.0"
    ];

    overlays = [
      (final: prev: {
        lib = 
          prev.lib
          // {
            colors = import "${self}/lib/colors" prev.lib;
          };
        opencode = prev.opencode.overrideAttrs (oldAttrs: {
          version = "0.0.55";
          src = prev.fetchFromGitHub {
            owner = "opencode-ai";
            repo = "opencode";
            rev = "v0.0.55";
            hash = "sha256-UjGNtekqPVUxH/jfi6/D4hNM27856IjbepW7SgY2yQw="; 
          };
          vendorHash = "sha256-Kcwd8deHug7BPDzmbdFqEfoArpXJb1JtBKuk+drdohM=";
        });
        podman-compose = prev.podman-compose.overrideAttrs (oldAttrs: rec {
          version = "1.5.0";
          src = prev.fetchFromGitHub {
            owner = "containers";
            repo = "podman-compose";
            rev = "v1.5.0";
            hash = "sha256-AEnq0wsDHaCxefaEX4lB+pCAIKzN0oyaBNm7t7tK/yI="; 
          };
        });
       })
    ];
  };
}
