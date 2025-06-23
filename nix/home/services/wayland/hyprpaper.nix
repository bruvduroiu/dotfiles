{ pkgs, inputs, config, ... }:

let
  wallpaper = ../../wallpapers/a_woman_wearing_a_helmet.jpg;
in {
  services.hyprpaper = {
    enable = true;
    package = inputs.hyprpaper.packages.${pkgs.system}.default;

    settings = {
      preload = [ (builtins.toString wallpaper) ];
      wallpaper = [",${builtins.toString wallpaper}"];
    };
  };
}
