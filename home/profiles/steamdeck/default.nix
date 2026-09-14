{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./syncthing.nix
    ../../programs/keepassxc.nix
    ../../programs/games/minecraft
    ../../programs/games/openrct2
    # Configured Claude Code (settings/agents/MCP/plugins under ~/.claude). Required
    # by the openrct2 coding-agent fork, whose in-game terminal launches `claude`.
    ../../terminal/programs/claude
    ./media.nix
    ../../programs/wayland
    ../../programs/wayland/niri.nix
    ../../terminal/emulators/ghostty.nix
    ../../services/media/playerctl.nix
  ];

  desktop.niri = {
    portable = true;
    omittedApplications = [ "obsidian" "mullvad-browser" ];
    # Niri reads the kernel's panel orientation; keep the small display at 1x.
    extraConfig = ''
      output "eDP-1" {
        scale 1
      }
    '';
  };
  programs.firefox.enable = true;
  programs.firefox.configPath = ".mozilla/firefox";
  programs.yazi.enable = true;
  programs.newsboat.enable = true;
  gtk.enable = true;
  home.pointerCursor = {
    enable = true;
    name = "BreezeX-RosePine-Linux";
    package = pkgs.rose-pine-cursor;
    size = 24;
    gtk.enable = true;
  };
  # Desktop inactivity must not suspend the stationary media server.
  programs.noctalia.settings.idle.behavior.suspend.enabled = lib.mkForce false;
  # Gaming Mode also starts graphical-session.target. Only start the desktop
  # shell when Niri has imported its socket into the user manager environment.
  systemd.user.services.noctalia.Unit.ConditionEnvironment = "NIRI_SOCKET";

  home = {
    username = "deck";
    homeDirectory = "/home/deck";
    stateVersion = "25.11";
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # claude-code (pulled in by programs.claude-code and baked into the openrct2
  # coding-agent wrapper) is unfree. This host's Home Manager builds its OWN pkgs
  # (useGlobalPkgs is not set for steamdeck — see system/default.nix), so the
  # system-level allowUnfree in hosts/steamdeck/default.nix does not reach it.
  # Opt in here too.
  nixpkgs.config.allowUnfree = true;

  # keepassxc.nix sets `programs.keepassxc.autostart = true`, which (on
  # Nyx's Home Manager, used by this host) asserts xdg.autostart must be on.
  # Framework13's stable HM lacks that assertion, so this is only needed here.
  xdg.autostart.enable = true;
}
