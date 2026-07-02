{ self, config, ... }:

{
  imports = [
    # theme
    ../../theme

    # editors
    ../../editors/nvim

    # programs
    ../../programs
    ../../programs/keepassxc.nix
    ../../programs/wayland
    # HM-generated Hyprland lua config (framework13-first; replaces the
    # hand-authored system-level lua.nix once verified). See Change 2 plan.
    ../../programs/wayland/hyprland.nix
    ../../programs/gtk.nix
    ../../programs/yt-dlp.nix
    ../../programs/gpg.nix

    # terminal emulators
    ../../terminal/emulators/ghostty.nix

    ../../services/wayland/hyprpaper.nix
    ../../services/mako.nix
    ../../services/podman.nix
    ../../services/gpg.nix
    ../../services/syncthing.nix
    ../../services/trayscale.nix
    ../../services/media/playerctl.nix
  ];

  # SOPS secret for OpenRouter API key (used by nvim 99 plugin)
  sops.secrets.openrouter_api_key = {
    sopsFile = "${self}/secrets/common/api-keys.yaml";
  };

  sops.secrets.deepseek_api_key = {
    sopsFile = "${self}/secrets/common/api-keys.yaml";
  };

  # Z.AI Coding Plan key (used by opencode zai-coding-plan provider)
  sops.secrets.zai_api_key = {
    sopsFile = "${self}/secrets/common/api-keys.yaml";
  };

  # Alpha Vantage key (used by portfolio-update-prices)
  sops.secrets.alphavantage_api_key = {
    sopsFile = "${self}/secrets/common/api-keys.yaml";
  };

  # Datadog API keys (used by opencode dd-log tool)
  sops.secrets.dd_api_key = {
    sopsFile = "${self}/secrets/common/datadog.yaml";
  };
  sops.secrets.dd_app_key = {
    sopsFile = "${self}/secrets/common/datadog.yaml";
  };

  # dd-log reads *_FILE variants so key material stays on disk (sops
  # runtime paths), not in every process environment.
  home.sessionVariables = {
    DD_API_KEY_FILE = config.sops.secrets.dd_api_key.path;
    DD_APP_KEY_FILE = config.sops.secrets.dd_app_key.path;
  };
}
