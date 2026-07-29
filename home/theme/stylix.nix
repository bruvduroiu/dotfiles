{ config, lib, ... }:

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

  # Stylix's GNOME target maps light polarity to "default", which the XDG
  # appearance portal reports as 0 = "no preference" rather than "light".
  # Apps reading the portal (Slack/Electron, KeePassXC, Firefox) then pick their
  # own default instead of following us. Force the explicit value both ways.
  dconf.settings."org/gnome/desktop/interface".color-scheme = lib.mkForce (
    if config.stylix.polarity == "dark" then "prefer-dark" else "prefer-light"
  );
}
