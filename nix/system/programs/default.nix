{
  imports = [
    ./fonts.nix
    ./xdg.nix
    ./home-manager.nix
  ];

  programs = {
    dconf.enable = true;
  };
}
