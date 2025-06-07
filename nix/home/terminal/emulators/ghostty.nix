{ pkgs, ... }:

{
  # Install Ghostty (you may need to add it to nixpkgs or use a custom derivation)
  home.packages = with pkgs; [
    ghostty
  ];

  home.file = {
    ".config/ghostty/config" = {
      source = ../../../../ghostty/config;
    };
  };
}
