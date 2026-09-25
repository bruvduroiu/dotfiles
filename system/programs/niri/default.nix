{ pkgs, ... }:

let
  # Jump to the urgent window if any (ghostty bell → xdg-activation → niri
  # marks urgent), else bounce to the last-focused
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
  # session, portals (gnome + gtk) and systemd units; this module adds only
  # env and helper scripts — no niri config.
  programs.niri.enable = true;

  # The nixpkgs niri module turns gnome-keyring on by default. Nothing here
  # uses it (SSH goes through gpg-agent), and greetd autologin never hands it
  # a password, so every login ended in an "unlock your keyring" prompt.
  # Its PAM hooks, Secret portal and gcr-ssh-agent all follow this switch.
  services.gnome.gnome-keyring.enable = false;

  environment = {
    pathsToLink = [ "/share/icons" ];
    systemPackages = [
      # niri spawns xwayland-satellite on demand for X11 clients; it only
      # needs to be reachable on PATH.
      pkgs.xwayland-satellite
      niri-focus-urgent
      niri-ws
      screenshot
    ];
  };

  environment.variables = {
    NIXOS_OZONE_WL = "1";
    XMODIFIERS = "@im=fcitx";
  };

  # One Settings portal publishes Noctalia's GTK dark/light preference.
  # Multiple implementations cause duplicate appearance notifications.
  xdg.portal.config.niri."org.freedesktop.impl.portal.Settings" = [ "gtk" ];
}
