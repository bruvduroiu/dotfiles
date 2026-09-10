{ config, pkgs, ... }:

let
  official = pkgs.fetchFromGitHub {
    owner = "noctalia-dev";
    repo = "official-plugins";
    rev = "f5d7f8049da8b7e830b6d3d57761bb869e46cede";
    hash = "sha256-mYUomM1N+7eD65g6Mdfntn5rMrUBcH6T1BZuDBj3OmI=";
  };
  community = pkgs.fetchFromGitHub {
    owner = "noctalia-dev";
    repo = "community-plugins";
    rev = "ea86850b8c21f9f8f3663021163b8f071040986d";
    hash = "sha256-7I7A4EuxiRTRZycDOErPP8oSdtAcv7zhJEpQU+S2mq0=";
  };
  plugins = pkgs.runCommand "noctalia-plugins" { } ''
    mkdir -p "$out"
    cp -R ${official}/{timer,translator,world_clock} "$out/"
    cp -R ${community}/{obsidian,phone-connect,syncthing} "$out/"
    chmod -R u+w "$out"

    # Upstream has no declarative timezone setting. Customize its first-run
    # seed; zones.json remains writable and later panel edits survive rebuilds.
    substituteInPlace "$out/world_clock/service.luau" --replace-fail \
      'local DEFAULT_ZONES = { "UTC", "America/New_York", "Europe/Berlin", "Asia/Tokyo" }' \
      'local DEFAULT_ZONES = { "Europe/London", "Europe/Bucharest", "Asia/Taipei" }'

    ${config.programs.noctalia.package}/bin/noctalia plugins lint \
      "$out"/{timer,translator,world_clock,obsidian,phone-connect,syncthing}
  '';
in
{
  programs.noctalia.settings = {
    plugins = {
      auto_update = "none";
      enabled = [
        "noctalia/timer"
        "noctalia/translator"
        "noctalia/world_clock"
        "davemhammer/obsidian"
        "icefish/phone-connect"
        "rylos/syncthing"
      ];
      # Explicit sources replace the implicit defaults. Keep the remote stores
      # disabled so these pinned plugins are loaded only from the Nix store.
      source = [
        {
          name = "official";
          kind = "git";
          location = "https://github.com/noctalia-dev/official-plugins";
          enabled = false;
        }
        {
          name = "community";
          kind = "git";
          location = "https://github.com/noctalia-dev/community-plugins";
          enabled = false;
        }
        {
          name = "nix";
          kind = "path";
          location = "${plugins}";
          enabled = true;
        }
      ];
    };

    plugin_settings = {
      "noctalia/translator" = {
        provider = "google";
        target_lang = "en";
      };
      "davemhammer/obsidian" = {
        vault_path = "${config.home.homeDirectory}/${config.programs.obsidian.vaults.Keep.target}";
        vault_name = "Keep";
        daily_folder = "5 - Main Notes/Daily";
        daily_format = "%Y-%m-%d";
        refresh_interval = 60;
      };
      "icefish/phone-connect" = {
        enable_charging_animation = false;
        show_device_name = false;
        battery_display = "icon";
        language = "en";
      };
      "rylos/syncthing" = {
        # The daemon listens on 0.0.0.0; connect through loopback. The API key
        # is read at runtime from Syncthing's config.xml, never put in the store.
        url = "http://127.0.0.1:8384";
        poll_interval = 30;
        notify_events = false;
      };
    };

    # The shared bar places these in its existing time and status islands.
    widget = {
      timer = {
        type = "noctalia/timer:bar";
        show_idle_on_horizontal = false;
      };
      world-clock.type = "noctalia/world_clock:bar";
      phone-connect.type = "icefish/phone-connect:bar";
      syncthing.type = "rylos/syncthing:bar";
    };
  };

  # Runtime command dependencies, including Phone Connect's file picker and
  # optional SFTP browser. KDE Connect and Syncthing keep their existing services.
  home.packages = with pkgs; [
    coreutils
    findutils
    git
    glib
    kdePackages.kdeconnect-kde
    sshfs
    xdg-utils
    zenity
  ];
}
