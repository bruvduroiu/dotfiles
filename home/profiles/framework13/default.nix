{ config, inputs, ... }:

{
  imports = [

    # editors
    ../../editors/helix
    ../../editors/nvim

    # programs
    ../../programs
    ../../programs/keepassxc.nix
    ../../programs/wayland
    ../../programs/wayland/noctalia-templates.nix
    ../../programs/wayland/noctalia-plugins.nix
    ../../programs/wayland/noctalia-calendar.nix
    ../../programs/wayland/niri.nix
    ../../programs/gtk.nix
    ../../programs/yt-dlp.nix
    ../../programs/gpg.nix
    ../../programs/hermes.nix

    # terminal emulators
    ../../terminal/emulators/ghostty.nix

    ../../services/podman.nix
    ../../services/gpg.nix
    ../../services/syncthing.nix
    ../../services/media/playerctl.nix

    # Private home manager configuration
    inputs.secrets.homeModules.default
  ];

  # Markdown -> styled PDF pipeline (pandoc + headless chromium), with an
  # Obsidian "Export: note -> PDF" command bound to Mod+Shift+E.
  programs.md2pdf = {
    enable = true;
    obsidian.enable = true;
  };

  # SOPS secret for OpenRouter API key (used by nvim 99 plugin)
  sops.secrets.openrouter_api_key = {
    sopsFile = "${inputs.secrets}/secrets/common/api-keys.yaml";
  };

  sops.secrets.deepseek_api_key = {
    sopsFile = "${inputs.secrets}/secrets/common/api-keys.yaml";
  };

  # Z.AI Coding Plan key (used by opencode zai-coding-plan provider)
  sops.secrets.zai_api_key = {
    sopsFile = "${inputs.secrets}/secrets/common/api-keys.yaml";
  };

  # Self-hosted api.abliteration.ai key (used by the opencode `abliteration` provider)
  sops.secrets.abliteration_api_key = {
    sopsFile = "${inputs.secrets}/secrets/common/api-keys.yaml";
  };

  # Alpha Vantage key (used by portfolio-update-prices)
  sops.secrets.alphavantage_api_key = {
    sopsFile = "${inputs.secrets}/secrets/common/api-keys.yaml";
  };

  # Datadog API keys (used by opencode dd-log tool)
  sops.secrets.dd_api_key = {
    sopsFile = "${inputs.secrets}/secrets/common/datadog.yaml";
  };
  sops.secrets.dd_app_key = {
    sopsFile = "${inputs.secrets}/secrets/common/datadog.yaml";
  };

  # dd-log reads *_FILE variants so key material stays on disk (sops
  # runtime paths), not in every process environment.
  home.sessionVariables = {
    DD_API_KEY_FILE = config.sops.secrets.dd_api_key.path;
    DD_APP_KEY_FILE = config.sops.secrets.dd_app_key.path;
  };
}
