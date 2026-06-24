{ inputs, pkgs, lib, ... }:

let
  # Searchable keybind cheatsheet: decodes hyprctl's modmask bitfield into
  # readable modifier names, then displays via walker's dmenu mode.
  hypr-binds-menu = pkgs.writeShellApplication {
    name = "hypr-binds-menu";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      hyprctl binds -j | jq -r '
        .[] as $b |
        ([["SUPER", 64], ["CTRL", 4], ["ALT", 8], ["SHIFT", 1]]
         | map(select((($b.modmask / .[1]) | floor) % 2 == 1) | .[0])
         | join("+")) as $mods |
        (if $b.submap != "" then "[\($b.submap)] " else "" end)
        + (if $mods == "" then "" else $mods + "+" end)
        + $b.key + "  →  " + $b.dispatcher
        + (if $b.arg != "" then " " + $b.arg else "" end)
      ' | walker -d -p "Keybinds"
    '';
  };

  # Notification control centre: mako history via dbus (this makoctl version
  # only prints human-readable text), formatted into walker dmenu.
  # Selecting an entry copies its text to the clipboard.
  mako-history-menu = pkgs.writeShellApplication {
    name = "mako-history-menu";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      selection=$(
        busctl --user -j call org.freedesktop.Notifications /fr/emersion/Mako \
          fr.emersion.Mako ListHistory \
          | jq -r '
              .data[0][] |
              (if ."app-name".data != "" then ."app-name".data else ."desktop-entry".data end)
              + ": " + .summary.data
              + (if .body.data != "" then " — " + (.body.data | gsub("\n"; " ")) else "" end)
            ' \
          | walker -d -p "Notifications"
      )
      if [ -n "$selection" ]; then
        printf '%s' "$selection" | wl-copy
      fi
    '';
  };

  # Vim-style window marks ($mod N <letter> to set, $mod ' <letter> to jump).
  # Marks are window tags; "set" steals the letter from any previous holder
  # so each mark always points at exactly one window.
  hypr-mark = pkgs.writeShellApplication {
    name = "hypr-mark";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      mode="$1"
      tag="mark$2"
      case "$mode" in
        set)
          # tagwindow silently no-ops without an explicit window argument
          # (observed on 0.55), so always pass address:
          hyprctl clients -j \
            | jq -r --arg t "$tag" '.[] | select(.tags | index($t)) | .address' \
            | while read -r old; do
                hyprctl dispatch tagwindow -- "-$tag" "address:$old" >/dev/null
              done
          active=$(hyprctl activewindow -j | jq -r .address)
          hyprctl dispatch tagwindow -- "+$tag" "address:$active" >/dev/null
          hyprctl notify -1 1200 0 "  mark: $2"
          ;;
        jump)
          hyprctl dispatch focuswindow "tag:$tag"
          ;;
      esac
    '';
  };

  # Chat centre: spawn messengers if missing (window rules tag them "im" and
  # route to special:chat), then toggle the workspace.
  chat-toggle = pkgs.writeShellApplication {
    name = "chat-toggle";
    text = ''
      pgrep -xf Telegram >/dev/null || uwsm app -- Telegram &
      pgrep -f signal-desktop >/dev/null || uwsm app -- signal-desktop &
      hyprctl dispatch togglespecialworkspace chat
    '';
  };

  # Screenshots: grim captures, satty edits. "area" opens the annotation
  # editor (Ctrl+C copy / Ctrl+S save / copy also saves); "full" goes
  # straight to clipboard + file.
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [ grim slurp satty wl-clipboard libnotify ];
    text = ''
      dir="$HOME/Pictures/Screenshots"
      mkdir -p "$dir"
      file="$dir/$(date +%F_%H-%M-%S).png"
      case "''${1:-area}" in
        area)
          grim -g "$(slurp)" - | satty --filename - \
            --output-filename "$file" \
            --early-exit --copy-command wl-copy --save-after-copy
          ;;
        full)
          grim "$file"
          wl-copy < "$file"
          notify-send -t 3000 "Screenshot" "saved + copied: ''${file##*/}"
          ;;
      esac
    '';
  };
in {
  imports = [
    inputs.hyprland.nixosModules.default

    ./binds.nix
    ./rules.nix
    ./settings.nix

    # Hyprland 0.55 Lua config (generated alongside the hyprlang .conf above;
    # .lua is preferred at startup). See docs/hyprland-lua-migration.md.
    ./lua.nix
  ];

  environment = {
    pathsToLink = ["/share/icons"];
    systemPackages = [
      chat-toggle
      hypr-binds-menu
      hypr-mark
      mako-history-menu
      screenshot
    ];
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  environment.variables = {
    NIXOS_OZONE_WL = "1";
    XMODIFIERS = "@im=fcitx";
  };

  # fcitx5's Qt6 plugin segfaults Qt apps on launch (see waylandFrontend in
  # system/core). With waylandFrontend=true QT_IM_MODULE is never set, so this
  # is belt-and-braces: keeps screenshare alive even if that gets reverted.
  systemd.user.services.xdg-desktop-portal-hyprland.environment.QT_IM_MODULE = "";
}
