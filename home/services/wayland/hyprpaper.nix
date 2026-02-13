{ config, pkgs, inputs, ... }:

{
  services.hyprpaper = {
    enable = true;
    package = inputs.hyprpaper.packages.${pkgs.system}.default;

    settings = {
      splash = false;

      # Wallpaper follows config.stylix.image, which changes per NixOS specialisation.
      # switch-to-configuration restarts hyprpaper with the correct wallpaper automatically.
      wallpaper = [
        {
          monitor = "";
          path = builtins.toString config.stylix.image;
        }
      ];
    };
  };
}
