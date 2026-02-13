{ ... }:

{
  # Stylix config + specialisation are at the NixOS level (hosts/framework13/default.nix)
  # and auto-inherit into Home Manager via followSystem.
  # Only HM-specific target overrides go here.
  stylix.targets = {
    hyprland.enable = false;
    hyprpaper.enable = false;
    neovim.enable = false;
    waybar.enable = false;
  };
}
