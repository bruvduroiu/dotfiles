{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Scripts live beside this file as plain shell; writeShellApplication wraps
  # each with pinned runtime deps and shellchecks it at build time (same
  # pattern as the claude hooks). They PREPEND runtimeInputs to PATH and
  # inherit the rest, so hx/claude/jjui resolve from the user profile.
  mkScript =
    name: deps:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = deps;
      text = builtins.readFile ./${name}.sh;
    };

  # Attach-or-create a project session: picker over live sessions, dead
  # (resurrectable) sessions and project directories.
  zj = mkScript "zj" [
    config.programs.zellij.package
    pkgs.fzf
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gawk
  ];

  # Coding-agent chooser that the workbench's agent pane runs.
  agent = mkScript "agent" [
    pkgs.fzf
    pkgs.coreutils
  ];

  # yazi's `edit` opener inside a session: send `:open <file>` to the Helix
  # pane instead of starting a second hx.
  zj-edit = mkScript "zj-edit" [
    config.programs.zellij.package
    config.programs.helix.package
    pkgs.coreutils
    pkgs.gawk
  ];
in
{
  home.packages = [
    zj
    agent
    zj-edit
  ];

  programs.zellij = {
    enable = true;

    # Hand-written KDL: keybinds are repeated `bind` nodes with arguments,
    # which the attrset->KDL generator can't express cleanly. `settings` stays
    # empty so nothing is emitted twice.
    extraConfig = builtins.readFile ./config.kdl;

    layouts = {
      workbench = ./layouts/workbench.kdl;
      agent = ./layouts/agent.kdl;
      shell = ./layouts/shell.kdl;
    };

    # No shell autostart: Mod+Return stays a plain ghostty shell; sessions are
    # entered through `zj` (fish), Mod+Shift+Return (niri), `W` (yazi) or the
    # Workbench launcher entry.
    enableFishIntegration = false;
  };

  # Noctalia launcher: "Workbench" opens the zj picker in a new ghostty window.
  xdg.desktopEntries.zj = {
    name = "Workbench";
    comment = "Attach or create a Zellij project session";
    exec = "ghostty +new-window -e zj";
    icon = "utilities-terminal";
    terminal = false;
    categories = [ "Development" ];
  };
}
