{ config, inputs, pkgs, lib, ... }:

let
  # Vim-style window marks ($mod N <letter> to set, $mod ' <letter> to jump).
  # Marks are window tags; "set" steals the letter from any previous holder
  # so each mark always points at exactly one window.
  hypr-mark = pkgs.writeShellApplication {
    name = "hypr-mark";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      mode="$1"
      tag="mark$2"
      # 0.55 reparses `hyprctl dispatch` args as Lua (wraps them in
      # `return hl.dispatch(...)`), so the old `tagwindow +tag address:...`
      # plaintext form is a syntax error — dispatch Lua expressions instead.
      case "$mode" in
        set)
          hyprctl clients -j \
            | jq -r --arg t "$tag" '.[] | select(.tags | index($t)) | .address' \
            | while read -r old; do
                hyprctl dispatch "hl.dsp.window.tag({ tag = '-$tag', window = 'address:$old' })" >/dev/null
              done
          active=$(hyprctl activewindow -j | jq -r .address)
          hyprctl dispatch "hl.dsp.window.tag({ tag = '+$tag', window = 'address:$active' })" >/dev/null
          hyprctl notify -1 1200 0 "  mark: $2"
          ;;
        jump)
          hyprctl dispatch "hl.dsp.focus({ window = 'tag:$tag' })"
          ;;
      esac
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
    # Hyprland config is a hand-written lua file shipped by home-manager,
    # see home/programs/wayland/hyprland.{nix,lua}. This NixOS module owns
    # only the UWSM session, portals and helper scripts — no Hyprland config.
  ];

  environment = {
    pathsToLink = ["/share/icons"];
    systemPackages = [
      hypr-mark
      screenshot
    ];
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  desktop.greetd.sessionCommand =
    let
      hyprlandDesktop = "${config.programs.hyprland.package}/share/wayland-sessions/hyprland.desktop";
    in "${lib.getExe config.programs.uwsm.package} start -eD Hyprland ${hyprlandDesktop}";

  environment.variables = {
    NIXOS_OZONE_WL = "1";
    XMODIFIERS = "@im=fcitx";
  };

  # fcitx5's Qt6 plugin segfaults Qt apps on launch (see waylandFrontend in
  # system/core). With waylandFrontend=true QT_IM_MODULE is never set, so this
  # is belt-and-braces: keeps screenshare alive even if that gets reverted.
  systemd.user.services.xdg-desktop-portal-hyprland.environment.QT_IM_MODULE = "";

  # stylix's QT_QPA_PLATFORMTHEME=qt5ct loads the qt6ct platform-theme plugin
  # into hyprland-share-picker, whose bundled Qt (hyprland flake's nixpkgs)
  # drifts from the system Qt the plugin was built against — qt6ct's proxy
  # style then recurses in standardPalette until the stack blows (SIGSEGV, so
  # every screenshare portal prompt dies before it can appear). Blank it here;
  # QT_STYLE_OVERRIDE=kvantum alone loads fine, so the picker stays themed.
  systemd.user.services.xdg-desktop-portal-hyprland.environment.QT_QPA_PLATFORMTHEME = "";
}
