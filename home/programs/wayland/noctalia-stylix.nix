# Imported only where Stylix is available; Noctalia owns these live colors.
{
  stylix.targets = {
    gtk.enable = false;
    gnome.enable = false;
    helix.enable = false;
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
