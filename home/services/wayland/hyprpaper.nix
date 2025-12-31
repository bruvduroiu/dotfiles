{ pkgs, inputs, ... }:

let
  wallpaper = ../../wallpapers/a_fish_swimming_in_water.png;
in {
  services.hyprpaper = {
    enable = true;
    package = inputs.hyprpaper.packages.${pkgs.system}.default;

    settings = {
      splash = false;

      wallpaper = [
        {
          monitor = "";
          path = "${wallpaper}";
        }
      ];
    };
  };
}
