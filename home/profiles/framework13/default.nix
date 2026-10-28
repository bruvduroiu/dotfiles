{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # API keys a command may ask for by env var name. They used to be exported
  # into every fish shell, so every child process (each coding agent
  # included) inherited all of them; now a key reaches only the command run
  # under `withkey`. The values stay in sops (docs/secrets.md).
  apiKeyFiles = {
    ABLITERATION_API_KEY = config.sops.secrets.abliteration_api_key.path;
    ALPHAVANTAGE_API_KEY = config.sops.secrets.alphavantage_api_key.path;
    DEEPSEEK_API_KEY = config.sops.secrets.deepseek_api_key.path;
    IMMICH_API_KEY = config.sops.secrets.immich_api_key.path;
    OPENROUTER_API_KEY = config.sops.secrets.openrouter_api_key.path;
  };

  withkey = pkgs.writeShellApplication {
    name = "withkey";
    text = ''
      # withkey VAR [VAR...] -- COMMAND [ARGS...]
      declare -A files=(
        ${lib.concatStringsSep "\n    " (
          lib.mapAttrsToList (name: path: "[${name}]=${lib.escapeShellArg path}") apiKeyFiles
        )}
      )

      usage() {
        echo "usage: withkey VAR [VAR...] -- COMMAND [ARGS...]" >&2
        echo "known: ''${!files[*]}" >&2
        exit 2
      }

      vars=()
      while (($#)); do
        if [[ $1 == -- ]]; then
          shift
          break
        fi
        vars+=("$1")
        shift
      done
      ((''${#vars[@]} && $#)) || usage

      for var in "''${vars[@]}"; do
        file=''${files[$var]:-}
        [[ -n $file ]] || { echo "withkey: unknown key $var" >&2; usage; }
        [[ -r $file ]] || { echo "withkey: $var: $file is not readable (sops not activated?)" >&2; exit 1; }
        export "$var=$(<"$file")"
      done
      exec "$@"
    '';
  };
in
{
  home.packages = [
    withkey
    # mods reads DEEPSEEK_API_KEY for its deepseek provider (~/.config/mods/mods.yml).
    (lib.hiPrio (
      pkgs.writeShellScriptBin "mods" ''
        exec ${lib.getExe withkey} DEEPSEEK_API_KEY -- ${lib.getExe pkgs.mods} "$@"
      ''
    ))
  ];

  imports = [

    # editors
    ../../editors/helix
    ../../editors/nvim

    # programs
    ../../programs
    ../../programs/vesktop.nix
    ../../programs/keepassxc.nix
    ../../programs/wayland
    ../../programs/wayland/noctalia-templates.nix
    ../../programs/wayland/noctalia-plugins.nix
    ../../programs/wayland/noctalia-calendar.nix
    ../../programs/wayland/niri.nix
    ../../programs/wayland/voxtype.nix
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

  # Push-to-talk dictation: hold F19 (a Voyager layer key) or toggle with
  # Mod+V on the internal keyboard. Transcribed by the mbp's Qwen3-ASR server.
  sops.secrets.asr_api_key.sopsFile = "${inputs.secrets}/secrets/common/api-keys.yaml";
  services.dictation.apiKeyFile = config.sops.secrets.asr_api_key.path;
  services.dictation.enable = true;
  # The daemon reads the key once at start; at login it raced sops-nix's
  # decryption, lost, and sent every clip unauthenticated (401) until restarted.
  systemd.user.services.voxtype.Unit = {
    After = [ "sops-nix.service" ];
    Wants = [ "sops-nix.service" ];
  };

  # OpenRouter key (opencode `openrouter` provider; `withkey` for ad-hoc use)
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

  # Immich API key (`withkey IMMICH_API_KEY -- …`)
  sops.secrets.immich_api_key = {
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

  # dd-log and portfolio-update-prices read *_FILE variants so key material
  # stays on disk (sops runtime paths), not in every process environment.
  home.sessionVariables = {
    DD_API_KEY_FILE = config.sops.secrets.dd_api_key.path;
    DD_APP_KEY_FILE = config.sops.secrets.dd_app_key.path;
    ALPHAVANTAGE_API_KEY_FILE = config.sops.secrets.alphavantage_api_key.path;
  };
}
