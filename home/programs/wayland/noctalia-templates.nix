{ config, inputs, lib, pkgs, ... }:

let
  source = inputs.noctalia-templates;
  template = input: output: {
    input_path = "${source}/${input}";
    output_path = output;
  };
  cfg = config.xdg.configHome;
  userHome = config.home.homeDirectory;
  # Use upstream colors without its shell hook appending universal fish variables.
  fzfTemplate = pkgs.runCommand "noctalia-fzf-template" { } ''
    sed -n '/^--color=/p' ${source}/fzf/fzf.sh | sed 's/"$//' > "$out"
  '';
  # Upstream builds beside apply.sh, which is read-only in the Nix store.
  libreofficeSource = pkgs.runCommand "noctalia-libreoffice" { } ''
    cp -r ${source}/libreoffice "$out"
    chmod -R u+w "$out"
    substituteInPlace "$out/apply.sh" \
      --replace-fail 'BUILD_DIR="$CONFIG_DIR/build"' \
        'BUILD_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/libreoffice-extension"'
  '';
  libreofficeApply = pkgs.writeShellApplication {
    name = "noctalia-libreoffice-apply";
    runtimeInputs = with pkgs; [ bash coreutils gnused python3 zip procps libreoffice ];
    text = ''exec bash ${libreofficeSource}/apply.sh'';
  };
  vaults = lib.filterAttrs (_: vault: vault.enable) config.programs.obsidian.vaults;
in
{
  # Pin upstream community colors, declare app selections in Nix, and leave
  # generated files writable. Avoid hooks that edit HM-owned configuration.
  programs.noctalia.settings.theme.templates.user = {
    bat = (template "bat/bat.tmTheme" "${cfg}/bat/themes/noctalia.tmTheme") // {
      post_hook = "${lib.getExe config.programs.bat.package} cache --build";
    };
    yazi = template "yazi/yazi.toml" "${cfg}/yazi/flavors/noctalia.yazi/flavor.toml";
    yazi-syntax = template "yazi/yazi.tmTheme" "${cfg}/yazi/flavors/noctalia.yazi/tmtheme.xml";
    claude-code = template "claude-code/claude-code.json" [
      "${userHome}/.claude/themes/noctalia.json"
      "${userHome}/.claude-work/themes/noctalia.json"
    ];
    codex = template "codex/codex.tmTheme" "${userHome}/.codex/themes/noctalia.tmTheme";
    discord = template "discord/discord-midnight.css" [
      "${cfg}/Vencord/themes/noctalia.theme.css"
      "${cfg}/vesktop/themes/noctalia.theme.css"
    ];
    fcitx5 = (template "fcitx5/theme.conf" "${config.xdg.dataHome}/fcitx5/themes/noctalia/theme.conf") // {
      post_hook = "${pkgs.systemd}/bin/busctl --user call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 ReloadAddonConfig s classicui";
    };
    fzf = { input_path = "${fzfTemplate}"; output_path = "${cfg}/fzf/noctalia.opts"; };
    libreoffice = (template "libreoffice/Theme_Colors.xcu" "${config.xdg.stateHome}/noctalia/libreoffice-theme-staging/Theme_Colors.xcu") // {
      post_hook = lib.getExe libreofficeApply;
    };
    obsidian = template "obsidian/obsidian.css" (lib.mapAttrsToList (_: vault:
      "${if lib.hasPrefix "/" vault.target then vault.target else "${userHome}/${vault.target}"}/.obsidian/snippets/noctalia.css"
    ) vaults);
    opencode = template "opencode/opencode.json" "${cfg}/opencode/themes/noctalia.json";
    telegram = template "telegram/telegram.tdesktop-theme" "${cfg}/telegram-desktop/themes/noctalia.tdesktop-theme";
    zathura = template "zathura/zathurarc" "${cfg}/zathura/noctaliarc";
  };

  # Declare selections rather than running upstream configuration-edit hooks.
  programs.bat.config.theme = "noctalia";
  programs.yazi.theme.flavor = { dark = "noctalia"; light = "noctalia"; };
  programs.fzf.colors = lib.mkForce { };
  home.sessionVariables.FZF_DEFAULT_OPTS_FILE = "${cfg}/fzf/noctalia.opts";
  programs.obsidian.defaultSettings.appearance.enabledCssSnippets = [ "noctalia" ];
  programs.opencode.tui.theme = "noctalia";
  programs.zathura.extraConfig = "include ${cfg}/zathura/noctaliarc";
}
