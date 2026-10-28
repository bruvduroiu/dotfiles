{
  description = "myapp";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      imports = [ inputs.treefmt-nix.flakeModule ];

      perSystem =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          packages = {
            default = pkgs.callPackage ./default.nix { };
          }
          // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
            image = pkgs.callPackage ./nix/image.nix { package = config.packages.default; };
          };

          devShells.default = import ./shell.nix {
            inherit pkgs;
            package = config.packages.default;
          };

          # buildGoModule runs `go test ./...` in its checkPhase
          checks.package = config.packages.default;

          treefmt.programs = {
            nixfmt.enable = true;
            gofmt.enable = true;
          };
        };

      flake.nixosModules.default = import ./nix/module.nix { inherit self; };
    };
}
