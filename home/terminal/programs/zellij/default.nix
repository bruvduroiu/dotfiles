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
    pkgs.jq
  ];

  zellij = lib.getExe config.programs.zellij.package;
in
{
  home.packages = [
    # lzj (picker) and zj (attach-or-create by name): pkgs/lazy-zellij.nix.
    pkgs.lazy-zellij
    agent
    zj-edit
  ];

  # lazy-zellij's units, from upstream's systemd/ with store paths in place
  # of the ~/.local/bin its install.sh seds in.
  #
  # zellij@<name>: `systemctl --user enable --now zellij@<name>` (lzj ctrl-u,
  # `zj up`) keeps a detached session running from login. Idempotent: it only
  # creates the session if it isn't there already.
  #
  # A plain file, not systemd.user.services: HM turns Install.WantedBy into a
  # default.target.wants/zellij@.service link and sd-switch then tries to
  # start the bare template ("missing the instance name"), failing the whole
  # activation. The [Install] section must still be in the file, or
  # `systemctl --user enable zellij@<name>` has nothing to enable.
  xdg.configFile."systemd/user/zellij@.service".text = ''
    [Unit]
    Description=Zellij session %i
    Documentation=https://zellij.dev
    After=default.target

    [Service]
    Type=oneshot
    RemainAfterExit=yes
    ExecStart=${pkgs.writeShellScript "zellij-session-up" ''
      ${zellij} list-sessions --short 2>/dev/null | ${pkgs.gnugrep}/bin/grep -qxF "$1" \
        || ${zellij} attach -b "$1"
    ''} %i
    ExecStop=${zellij} kill-session %i

    [Install]
    WantedBy=default.target
  '';

  # Every 30s, the focused pane of each attached session to
  # ~/.cache/lzj/snapshots, for the picker's preview.
  systemd.user.services.lzj-snapshot = {
    Unit.Description = "Snapshot active zellij sessions for the lzj preview pane";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.lazy-zellij}/bin/lzj-snapshot";
      Nice = 10;
    };
  };
  systemd.user.timers.lzj-snapshot = {
    Unit.Description = "Periodic snapshots of active zellij sessions for lzj preview";
    Timer = {
      OnBootSec = "30s";
      OnUnitActiveSec = "30s";
      AccuracySec = "5s";
    };
    Install.WantedBy = [ "timers.target" ];
  };

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
    # entered through `lzj`/`zj` (fish), Mod+Shift+Return (niri), `W` (yazi)
    # or the Workbench launcher entry.
    enableFishIntegration = false;
  };

  # fish completions for zellij's session + layout names, through conf.d:
  # fish loads a single <cmd>.fish per command, first on $fish_complete_path
  # wins, so a completions/zellij.fish here would shadow the package's
  # clap-generated one in vendor_completions.d instead of extending it.
  xdg.configFile."fish/conf.d/zellij-completions.fish".source = ./zellij-completions.fish;

  # Noctalia launcher: "Workbench" opens the lzj picker in a new ghostty window.
  xdg.desktopEntries.zj = {
    name = "Workbench";
    comment = "Pick, attach or create a Zellij session";
    exec = "ghostty +new-window -e lzj";
    icon = "utilities-terminal";
    terminal = false;
    categories = [ "Development" ];
  };
}
