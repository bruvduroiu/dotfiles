{ self, inputs, ... }:

{
  nixpkgs = {
    config.allowUnfree = true;
    config.permittedInsecurePackages = [
      "electron-25.9.0"
    ];

    overlays = [
      inputs.nur.overlays.default
      inputs.mcp-servers-nix.overlays.default
      (final: prev: {
        lib = 
          prev.lib
          // {
            colors = import "${self}/lib/colors" prev.lib;
          };
        claude-code = (import inputs.nixpkgs-unstable.outPath {
          system = prev.system;
          config.allowUnfree = true;
        }).claude-code;
        terraform-mcp-server = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.terraform-mcp-server;
        keymapp = (import inputs.nixpkgs-unstable.outPath {
          system = prev.system;
          config.allowUnfree = true;
        }).keymapp;
        gh-actions-language-server = prev.callPackage "${self}/pkgs/gh-actions-language-server.nix" {};
        lightpanda = prev.callPackage "${self}/pkgs/lightpanda.nix" {};
        gomcp = prev.callPackage "${self}/pkgs/gomcp.nix" {};
        opencode = prev.callPackage "${self}/pkgs/opencode.nix" {
          version = "1.0.137";
          hash = "sha256-XMAKKcbEYl3PJ4JAFlZg1d6Oc8wtaww22dDm9HEGnL4=";
        };
        podman = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.podman.overrideAttrs (oldAttrs: rec {
          version = "5.6.0-rc1";
          src = prev.fetchFromGitHub {
            owner = "containers";
            repo = "podman";
            rev = "v${version}";
            hash = "sha256-pgilheesCs7BzPIloyYPPMGv+KKoiEsVZFoHwePdUKM="; 
          };
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
        obsidian = prev.obsidian.overrideAttrs (oldAttrs: rec {
          version = "1.10.6";
        });
       })
    ];
  };
}
