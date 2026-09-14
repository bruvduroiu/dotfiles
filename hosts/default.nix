{ self, inputs, ... }:

{
  flake.nixosConfigurations = let
    inherit (inputs.nixpkgs.lib) nixosSystem;

    homeImports = import "${self}/home/profiles";
    mod = "${self}/system";

    inherit (import mod) laptop steamdeck phantom;

    specialArgs = { inherit inputs self;};
    # Shared modules may select unstable applications. Scope those selections
    # to the Deck's pin without changing Framework or Phantom's package set.
    deckSpecialArgs = {
      inherit self;
      inputs = inputs // {
        nixpkgs-unstable = inputs.nixpkgs-steamdeck;
        jovian-nixos = inputs.nyx.vendored.jovian;
      };
    };
  in {
    framework13 = nixosSystem {
      inherit specialArgs;
      modules = laptop
      ++ [
      ./framework13

      # Scrollable-tiling compositor; Noctalia supplies the desktop shell.
      "${mod}/programs/niri"

      # Home Manager (stable, follows nixpkgs)
      inputs.home-manager.nixosModules.home-manager

      # Theming (auto-injects into Home Manager via sharedModules)
      inputs.stylix.nixosModules.stylix

      # Secrets management
      inputs.sops-nix.nixosModules.sops

      # Private NixOS config (from the private flake)
      inputs.secrets.nixosModules.default

      {
        home-manager = {
          users.bogdan.imports = homeImports."bogdan@framework13" ++ [
            ../home/programs/wayland/noctalia-stylix.nix
          ];
          extraSpecialArgs = specialArgs;
          backupFileExtension = ".hm-backup";
          sharedModules = [
            inputs.sops-nix.homeManagerModules.sops
            inputs.nix4nvchad.homeManagerModules.default
          ];
        };
      }
      ];
    };

    # Nyx's vendored Jovian and its matching nixpkgs/Home Manager pins.
    steamdeck = inputs.nixpkgs-steamdeck.lib.nixosSystem {
      specialArgs = deckSpecialArgs;
      modules = steamdeck
      ++ [
      ./steamdeck

      # Jovian-NixOS for Steam Deck support
      inputs.nyx.vendored.jovian.nixosModules.default
      inputs.nyx.nixosModules.default

      inputs.home-manager-steamdeck.nixosModules.home-manager

      # Secrets management
      inputs.sops-nix.nixosModules.sops

      # Private NixOS config (from the private flake)
      inputs.secrets.nixosModules.default

      {
        home-manager = {
          users.deck.imports = homeImports."deck@steamdeck";
          extraSpecialArgs = deckSpecialArgs;
          backupFileExtension = ".hm-backup";
          sharedModules = [
            inputs.sops-nix.homeManagerModules.sops
          ];
        };
      }
      ];
    };

    # Phantom USB - ephemeral NixOS that leaves no trace
    # LUKS-encrypted, impermanent root, WireGuard home overlay
    phantom = nixosSystem {
      inherit specialArgs;
      modules = phantom ++ [
        ./phantom

        "${mod}/programs/niri"
        inputs.stylix.nixosModules.stylix

        # Declarative disk partitioning
        inputs.disko.nixosModules.disko

        # Home Manager (stable, follows nixpkgs)
        inputs.home-manager.nixosModules.home-manager

        # Secrets management (for runtime YubiKey-based decryption)
        inputs.sops-nix.nixosModules.sops

        # Private NixOS config (from the private flake)
        inputs.secrets.nixosModules.default

        {
          home-manager = {
            users.bogdan.imports = homeImports."bogdan@phantom" ++ [
              ../home/programs/wayland/noctalia-stylix.nix
            ];
            extraSpecialArgs = specialArgs;
            backupFileExtension = ".hm-backup";
            sharedModules = [
              inputs.sops-nix.homeManagerModules.sops
              inputs.nix4nvchad.homeManagerModules.default
            ];
          };
        }
      ];
    };
  };
}
