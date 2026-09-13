{ config, lib, pkgs, ... }:

let
  # btop re-reads its config and every theme file on SIGUSR2 (the same path as
  # its Ctrl+R hot reload), so a running btop recolors in place.
  reload = pkgs.writeShellApplication {
    name = "noctalia-btop-reload";
    runtimeInputs = [ pkgs.procps pkgs.coreutils ];
    text = ''
      # Only this user's processes. No matches is the normal case.
      status=0
      pkill -USR2 -u "$(id -u)" -x btop || status=$?
      if [ "$status" -gt 1 ]; then
        exit "$status"
      fi
    '';
  };
in
{
  # Stylix renders btop's theme from `stylix.polarity`, which is fixed at
  # build time — so btop stayed dark through every Mod+F5. Noctalia owns the
  # theme file instead; see noctalia-stylix.nix for the target disable.
  programs.btop.settings = {
    color_theme = "noctalia";
    # Stylix set this as part of its opacity target. Preserve it explicitly:
    # without it btop paints an opaque background over the translucent terminal.
    theme_background = false;
  };

  # Written into `themes/` rather than through `programs.btop.themes`, which
  # would make it an immutable Home Manager symlink Noctalia cannot rewrite.
  programs.noctalia.settings.theme.templates.user.btop = {
    input_path = "${./btop-noctalia.theme}";
    output_path = "${config.xdg.configHome}/btop/themes/noctalia.theme";
    post_hook = lib.getExe reload;
    hook_async = false;
  };
}
