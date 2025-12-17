{ self, inputs, ... }:

{
  flake.nixosConfigurations = let
    inherit (inputs.nixpkgs.lib) nixosSystem;

    homeImports = import "${self}/home/profiles";
    mod = "${self}/system";

    inherit (import mod) laptop steamdeck;

    specialArgs = { inherit inputs self;};
  in {
    framework13 = nixosSystem {
      inherit specialArgs;
      modules = laptop
      ++ [
      ./framework13

      "${mod}/programs/hyprland"

      # Home Manager (stable, follows nixpkgs)
      inputs.home-manager.nixosModules.home-manager

      # Secrets management
      inputs.sops-nix.nixosModules.sops

      # Services
      inputs.rental-bot.nixosModules.default

      {
        home-manager = {
          users.bogdan.imports = homeImports."bogdan@framework13";
          extraSpecialArgs = specialArgs;
          backupFileExtension = ".hm-backup";
          sharedModules = [
            inputs.sops-nix.homeManagerModules.sops
          ];
        };
      }
      ];
    };

    # Steam Deck with Jovian-NixOS (requires nixpkgs-unstable)
    steamdeck = inputs.nixpkgs-unstable.lib.nixosSystem {
      inherit specialArgs;
      modules = steamdeck
      ++ [
      ./steamdeck

      # Jovian-NixOS for Steam Deck support
      inputs.jovian-nixos.nixosModules.default

      # Home Manager (unstable, follows nixpkgs-unstable for Jovian compatibility)
      inputs.home-manager-unstable.nixosModules.home-manager

      # Secrets management
      inputs.sops-nix.nixosModules.sops

      {
        home-manager = {
          users.deck.imports = homeImports."deck@steamdeck";
          extraSpecialArgs = specialArgs;
          backupFileExtension = ".hm-backup";
          sharedModules = [
            inputs.sops-nix.homeManagerModules.sops
          ];
        };
      }
      ];
    };
  };
}
