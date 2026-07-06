{ config, pkgs, ... }:

{
  imports = [
    ./terminal
    ./terminal/emulators/ghostty.nix
  ];

  home = {
    username = "bogdan";
    homeDirectory = "/home/bogdan";
    stateVersion = "25.11";

    pointerCursor = {
      name = "BreezeX-RosePine-Linux";
      package = pkgs.rose-pine-cursor;
      size = 24;
      gtk.enable = true;
    };
  };

  # Symlink hyprcursor theme into ~/.local/share/icons/ so hyprcursor
  # can discover it even when XDG_DATA_DIRS is empty (UWSM sessions).
  xdg.dataFile."icons/rose-pine-hyprcursor".source =
    "${pkgs.rose-pine-hyprcursor}/share/icons/rose-pine-hyprcursor";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
