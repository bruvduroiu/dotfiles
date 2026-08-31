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

    # Colors only: fonts and opacity still come from stylix. The generated
    # themes/stylix file is invisible to ghostty's soft reload (the path
    # triggered by theme-switch's color-scheme flip), so ghostty.nix declares
    # a light:/dark: conditional theme pair instead.
    ghostty.colors.enable = false;

    # Stylix bakes hex into FZF_DEFAULT_OPTS, which running shells export at
    # startup and can never update — fzf stays on the old polarity after
    # theme-switch. fzf.nix maps the same roles to ANSI-16 indexes instead,
    # so fzf inherits whatever palette the terminal is currently showing.
    fzf.enable = false;
  };

  # Stylix's GNOME target maps light polarity to "default", which the XDG
  # appearance portal reports as 0 = "no preference" rather than "light".
  # Apps reading the portal (Slack/Electron, KeePassXC, Firefox) then pick their
  # own default instead of following us. Force the explicit value both ways.
  dconf.settings."org/gnome/desktop/interface".color-scheme = lib.mkForce (
    if config.stylix.polarity == "dark" then "prefer-dark" else "prefer-light"
  );
}
