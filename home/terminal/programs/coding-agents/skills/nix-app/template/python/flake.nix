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
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
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
            default = pkgs.callPackage ./default.nix {
              inherit (inputs) pyproject-nix uv2nix pyproject-build-systems;
            };
          }
          // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
            image = pkgs.callPackage ./nix/image.nix { package = config.packages.default; };
          };

          devShells.default = import ./shell.nix {
            inherit pkgs;
            package = config.packages.default;
          };

          checks = {
            package = config.packages.default;
          }
          // config.packages.default.tests;

          treefmt.programs = {
            nixfmt.enable = true;
            ruff-check.enable = true;
            ruff-format.enable = true;
          };
        };

      flake.nixosModules.default = import ./nix/module.nix { inherit self; };
    };
}
