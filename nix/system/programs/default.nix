{
  imports = [
    ./fonts.nix
    ./xdg.nix
    ./home-manager.nix
    ./nix-ld.nix
  ];

  programs = {
    dconf.enable = true;
  };
}
