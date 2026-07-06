{ config, pkgs, inputs, ... }:

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
  ];

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
  # home-manager-unstable, used by this host) asserts xdg.autostart must be on.
  # Framework13's stable HM lacks that assertion, so this is only needed here.
  xdg.autostart.enable = true;
}
