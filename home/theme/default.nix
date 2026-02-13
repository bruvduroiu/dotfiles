{ config, pkgs, lib, ... }:

let
  theme-switch = pkgs.writeShellScriptBin "theme-switch" ''
    set -euo pipefail

    THEME_DIR="$HOME/.config/theme"
    CURRENT_FILE="$THEME_DIR/current"

    mkdir -p "$THEME_DIR"

    # Read current mode
    current=$(cat "$CURRENT_FILE" 2>/dev/null || echo "dark")

    # Toggle or set explicit mode
    if [ "''${1:-}" = "light" ] || [ "''${1:-}" = "dark" ]; then
      target="$1"
    elif [ "$current" = "dark" ]; then
      target="light"
    else
      target="dark"
    fi

    echo "$target" > "$CURRENT_FILE"

    # --- Activate NixOS specialisation ---
    # This restarts services (hyprpaper, mako, etc.) with the correct
    # specialisation config — wallpaper, colors, and polarity all change
    # automatically via config.stylix.image / Stylix base16 scheme.
    if [ "$target" = "light" ]; then
      sudo /nix/var/nix/profiles/system/specialisation/light/bin/switch-to-configuration switch
    else
      sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
    fi

    # --- Waybar ---
    pkill -SIGUSR2 waybar 2>/dev/null || true

    # --- GTK ---
    if command -v gsettings &>/dev/null; then
      if [ "$target" = "dark" ]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
      else
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
      fi
    fi

    # --- Neovim ---
    if [ "$target" = "dark" ]; then
      nvim_theme="rosepine"
      nvim_bg="dark"
    else
      nvim_theme="rosepine-dawn"
      nvim_bg="light"
    fi
    echo "$nvim_theme" > "$THEME_DIR/nvim-theme"
    echo "$nvim_bg" > "$THEME_DIR/nvim-bg"

    # Live-switch all running Neovim instances
    for server in /run/user/$(id -u)/nvim.*.0 /tmp/nvim.*/0; do
      [ -S "$server" ] || continue
      nvim --server "$server" --remote-send \
        "<cmd>lua vim.o.background='$nvim_bg'; local ok, _ = pcall(function() require('nvconfig').base46.theme = '$nvim_theme'; require('base46').load_all_highlights() end); vim.cmd('redraw!')<CR>" \
        2>/dev/null || true
    done

    notify-send -t 2000 "Theme" "Switched to $target mode" 2>/dev/null || true
  '';

in {
  imports = [ ./stylix.nix ];

  home.packages = [ theme-switch ];

  # Initialize theme on activation
  home.activation.initTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    THEME_DIR="$HOME/.config/theme"
    mkdir -p "$THEME_DIR"
    if [ ! -f "$THEME_DIR/current" ]; then
      echo "dark" > "$THEME_DIR/current"
    fi
  '';
}
