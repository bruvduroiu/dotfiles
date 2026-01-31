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
        tailsnitch = prev.callPackage "${self}/pkgs/tailsnitch.nix" {};
        podman = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.podman;
        podman-compose = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.podman-compose;
        obsidian = (import inputs.nixpkgs-unstable.outPath {
          system = prev.system;
          config.allowUnfree = true;
        }).obsidian;
       })
    ];
  };
}
