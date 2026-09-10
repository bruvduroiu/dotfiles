{
  description = "Framework 13 NixOS Configuration";

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      perSystem = { pkgs, system, ... }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ ];
          config = { };
        };

        # Boox eReader and Android device management shell
        devShells.default = import ./shell.nix {
          inherit pkgs inputs;
        };
      };

      imports = [
        ./hosts
      ];
    };

  inputs = {
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk partitioning (for phantom USB)
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };


    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    helix.url = "github:helix-editor/helix";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager for Steam Deck (follows unstable for Jovian-NixOS compatibility)
    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };


    # Hyprland
    hyprland.url = "github:hyprwm/hyprland";

    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };



    # Ephemeral root with selective persistence (for phantom USB)
    impermanence.url = "github:nix-community/impermanence";

    # Hermes Agent desktop client (connects to the homelab gateway)
    # Note: Don't override nixpkgs — the uv2nix-built closure is pinned to
    # upstream's lock, and following ours would force a full local rebuild
    hermes-agent.url = "github:NousResearch/hermes-agent";

    # Steam Deck support via Jovian-NixOS
    # Note: Don't override nixpkgs to ensure cache hits for pre-built binaries
    jovian-nixos.url = "github:Jovian-Experiments/Jovian-NixOS";

    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Minecraft declarative mod management
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Keep upstream's nixpkgs pin so Noctalia's binary cache can be used.
    noctalia-templates = {
      url = "github:noctalia-dev/community-templates/cdb77210cd9c4fa9ccc5673523b57d2a6b76e804";
      flake = false;
    };
    noctalia.url = "github:noctalia-dev/noctalia/cachix";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Path to your local nvim configuration folder
    nvchad-config = {
      url = "path:./home/editors/nvim/nvchad";
      flake = false;
    };

    nix4nvchad = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nvchad-starter.follows = "nvchad-config"; # Overrides the starter
    };

    openapi-tui.url = "github:zaghaghi/openapi-tui";

    secrets.url = "git+ssh://forgejo@git.oolongtechnologies.io/bogdan/secrets.git";

    # Secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    yazi.url = "github:sxyazi/yazi";
  };
}
