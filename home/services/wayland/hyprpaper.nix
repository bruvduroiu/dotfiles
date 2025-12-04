{ pkgs, inputs, config, ... }:

let
  wallpaper = ../../wallpapers/a_fish_swimming_in_water.png;
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
