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

  # Datadog API keys (used by opencode dd-log tool)
  sops.secrets.dd_api_key = {
    sopsFile = "${self}/secrets/common/datadog.yaml";
  };
  sops.secrets.dd_app_key = {
    sopsFile = "${self}/secrets/common/datadog.yaml";
  };
}
