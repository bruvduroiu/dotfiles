# Imported only where Stylix is available; Noctalia owns these live colors.
{
  stylix.targets = {
    gtk.enable = false;
    gnome.enable = false;
    helix.enable = false;
    # Its static `ui.colors` is jjui's highest-priority palette layer, and so
    # masked both a theme file and jjui's own light/dark reload.
    jjui.enable = false;
    # Renders from the build-time `stylix.polarity`, so btop stayed dark in
    # light mode. Its opacity half is restated in btop-noctalia.nix.
    btop.enable = false;
    neovim.enable = false;
    ghostty.colors.enable = false;
    # base16-fish emits OSC colors at every shell startup, overriding Ghostty.
    fish.enable = false;
    fzf.enable = false;
    bat.enable = false;
    yazi.enable = false;
    opencode.enable = false;
    obsidian.enable = false;
    zathura.enable = false;
  };
}
