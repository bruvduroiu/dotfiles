# Phantom USB - Home Manager configuration
# Inherits from framework13 profile for familiar environment
# Adds phantom-specific overrides for ephemeral usage
{ pkgs, ... }:
{
  imports = [
    # Desktop shell. wayland/default.nix brings noctalia, wf-recorder and the
    # grim/slurp/satty screenshot chain; it does NOT pull niri.nix in, so the
    # compositor config is imported separately — the same split steamdeck uses.
    ../../programs/wayland
    ../../programs/wayland/niri.nix
    ../../programs/gtk.nix

    # Browser, credentials, signing. firefox.nix carries the arkenfox user.js
    # and overrides, so the hardened browser travels with the USB. All three
    # are sops-free; noctalia-calendar.nix and the terminal set are not, which
    # is why they are absent.
    ../../programs/browsers/firefox.nix
    ../../programs/keepassxc.nix
    ../../programs/gpg.nix

    # helix only. nvim's closure is dominated by plugins, language servers and
    # treesitter grammars that earn their place on a development machine and
    # not on a portable recovery station.
    ../../editors/helix

    ../../terminal/emulators/ghostty.nix
  ];

  # Keep the shared bindings/layout without Framework's monitor placement.
  desktop.niri.portable = true;

  # Normally supplied by home/default.nix, which this profile does not import.
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

  programs.home-manager.enable = true;
}
