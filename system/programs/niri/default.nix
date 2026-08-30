{ pkgs, ... }:

let
  # Jump to the urgent window if any (ghostty bell → xdg-activation → niri
  # marks urgent → red workspace in waybar), else bounce to the last-focused
  # window. Replaces Hyprland's `focus({ urgent_or_last = true })`.
  niri-focus-urgent = pkgs.writeShellApplication {
    name = "niri-focus-urgent";
    runtimeInputs = [ pkgs.jq pkgs.niri ];
    text = ''
      id=$(niri msg --json windows | jq -r '[.[] | select(.is_urgent)][0].id // empty')
      if [ -n "$id" ]; then
        niri msg action focus-window --id "$id"
      else
        niri msg action focus-window-previous
      fi
    '';
  };

  # Mod+N workspace binds, scratchpad-aware: declared named workspaces
  # (chat/work) always sit at the TOP of niri's strip, so raw indices would
  # make Mod+1 focus "work". Map N to the Nth UNNAMED workspace on the
  # focused output instead (clamping to the trailing empty one), keeping
  # Hyprland's "numbers = real workspaces" semantics.
  niri-ws = pkgs.writeShellApplication {
    name = "niri-ws";
    runtimeInputs = [ pkgs.jq pkgs.niri ];
    text = ''
      mode="$1" n="$2"
      # 1..5 are the named daily workspaces (declared in niri.kdl, strip
      # order = declaration order); 6..9 count unnamed overflow workspaces
      # on the focused output.
      case "$n" in
        1) ref="web" ;;
        2) ref="code" ;;
        3) ref="aux" ;;
        4) ref="chat" ;;
        5) ref="work" ;;
        *)
          ord=$(( n - 5 ))
          ref=$(niri msg --json workspaces | jq -r --argjson n "$ord" '
            ([.[] | select(.is_focused)] | first | .output) as $out
            | [.[] | select(.output == $out and .name == null)] | sort_by(.idx)
            | (.[$n - 1] // last).idx')
          ;;
      esac
      case "$mode" in
        focus)       niri msg action focus-workspace "$ref" ;;
        move)        niri msg action move-column-to-workspace "$ref" ;;
        move-silent) niri msg action move-column-to-workspace --focus false "$ref" ;;
      esac
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

  # Screenshots: grim captures, satty edits. "area" opens the annotation
  # editor (Ctrl+C copy / Ctrl+S save / copy also saves); "full" goes
  # straight to clipboard + file. niri implements wlr-screencopy, so the
  # grim/slurp pipeline carries over from Hyprland unchanged.
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
  # Niri config is a hand-written KDL file shipped by home-manager, see
  # home/programs/wayland/niri.{nix,kdl}. The nixpkgs module owns the
  # session, portals (gnome + gtk), gnome-keyring and systemd units; this
  # module adds only env and helper scripts — no niri config.
  programs.niri.enable = true;

  environment = {
    pathsToLink = [ "/share/icons" ];
    systemPackages = [
      # niri spawns xwayland-satellite on demand for X11 clients; it only
      # needs to be reachable on PATH.
      pkgs.xwayland-satellite
      mako-history-menu
      niri-focus-urgent
      niri-ws
      screenshot
    ];
  };

  environment.variables = {
    NIXOS_OZONE_WL = "1";
    XMODIFIERS = "@im=fcitx";
  };

  # PAM entry for swaylock (HM, home/programs/wayland/swaylock.nix);
  # fprintd being enabled makes fingerprint auth available in the stack.
  security.pam.services.swaylock = { };

  desktop.greetd.sessionCommand = "${pkgs.niri}/bin/niri-session";
}
