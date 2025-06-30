{ config, ... }: let
  data = config.xdg.dataHome;
  conf = config.xdg.configHome;
  cache = config.xdg.cacheHome;
in {
  imports = [
    ./programs
    ./shell/fish.nix
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
