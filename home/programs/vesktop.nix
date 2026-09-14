{ config, lib, pkgs, ... }:

let
  vesktopDir = "${config.xdg.configHome}/vesktop";

  # Vencord resolves its data dir from VENCORD_USER_DATA_DIR, which Vesktop
  # sets to its own Electron userData dir. So themes live in
  # <vesktopDir>/themes and Vencord's own state in <vesktopDir>/settings.
  themeFile = "noctalia.theme.css";

  # Vencord persists all plugin and theme state to settings/settings.json, so
  # declaring `programs.vesktop.vencord.settings` would link it in read-only
  # and break the in-app settings panel. Seed the one key we care about into
  # the mutable file instead, appending so Noctalia lands last in the cascade
  # and never reordering what is already enabled.
  enableTheme = pkgs.writeShellApplication {
    name = "vesktop-enable-noctalia-theme";
    runtimeInputs = with pkgs; [ jq coreutils ];
    text = ''
      dir="$1"
      settings="$dir/settings/settings.json"
      mkdir -p "$dir/themes" "$dir/settings"
      if [ -f "$settings" ]; then
        tmp="$(mktemp "$settings.XXXXXX")"
        jq --arg t "${themeFile}" \
          'if (.enabledThemes // []) | index($t) then .
           else .enabledThemes = ((.enabledThemes // []) + [$t]) end' \
          "$settings" > "$tmp"
        mv "$tmp" "$settings"
      else
        jq -n --arg t "${themeFile}" '{ enabledThemes: [ $t ] }' > "$settings"
      fi
    '';
  };
in
# Vesktop replaces the official client: it is the only Discord client that can
# load the Noctalia theme, and Vencord live-reloads it on every Mod+F5.
{
  programs.vesktop = {
    enable = true;

    # Take Vencord from nixpkgs instead of letting Vesktop fetch and
    # self-update its own copy at runtime.
    vencord.useSystem = true;

    # Intentionally no `settings` / `vencord.settings` — see enableTheme above.
  };

  # Vencord reads settings.json once at startup (it watches the themes dir and
  # quickCss.css, but not its own settings), so a newly seeded theme applies
  # from the next Vesktop launch onwards.
  home.activation.vesktopNoctaliaTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe enableTheme} ${lib.escapeShellArg vesktopDir}
  '';
}
