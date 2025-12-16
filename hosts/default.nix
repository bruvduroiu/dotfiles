{ self, inputs, ... }:

{
  flake.nixosConfigurations = let
    inherit (inputs.nixpkgs.lib) nixosSystem;

    homeImports = import "${self}/home/profiles";
    mod = "${self}/system";

    inherit (import mod) laptop;

    specialArgs = { inherit inputs self;};
  in {
    framework13 = nixosSystem {
      inherit specialArgs;
      modules = laptop
      ++ [
      ./framework13

      "${mod}/programs/hyprland"

      # Secrets management
      inputs.sops-nix.nixosModules.sops

      # Services
      inputs.rental-bot.nixosModules.default

      {
        home-manager = {
          users.bogdan.imports = homeImports."bogdan@framework13";
          extraSpecialArgs = specialArgs;
          backupFileExtension = ".hm-backup";
        };
      }
      ];
    };
  };
}
