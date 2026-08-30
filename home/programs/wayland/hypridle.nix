{ pkgs, lib, config, inputs, ... }: let
  lock = "${pkgs.systemd}/bin/loginctl lock-session";
  suspend = "${pkgs.systemd}/bin/systemctl suspend";

  # WM-neutral panel power control: this file is shared between niri
  # (framework13) and Hyprland (iso), so pick the IPC at runtime.
  #
  # Hyprland leg: 0.55+ reparses `hyprctl dispatch` args as Lua, so the old
  # `hyprctl dispatch dpms off` is a syntax error that still exits 0. The
  # action has to arrive as a table field: tableToggleAction() returns
  # TOGGLE_ACTION_TOGGLE for any non-table argument, so `dpms('off')` still
  # answers "ok" while actually toggling. Two toggles on resume (on-resume
  # plus after_sleep_cmd) then cancel out and leave the panel dark.
  wm-dpms = pkgs.writeShellApplication {
    name = "wm-dpms";
    text = ''
      state="$1"
      if [ -n "''${NIRI_SOCKET:-}" ]; then
        niri msg action "power-''${state}-monitors"
      else
        hyprctl dispatch "hl.dsp.dpms({action = \"''${state}\"})"
      fi
    '';
  };
  dpms = state: "${wm-dpms}/bin/wm-dpms ${state}";

  # Lock before blanking, not after. hyprlock has to get its first paint in
  # while the output is still powered, otherwise it renders only once the
  # panel comes back and waking takes seconds. Same ordering as upstream's
  # reference config.
  lockTimeout = 300;
  dpmsTimeout = lockTimeout + 30;
  suspendTimeout = 1800;
in
{
  services.hypridle = {
    enable = true;

    package = inputs.hypridle.packages.${pkgs.stdenv.hostPlatform.system}.hypridle;

    settings = {
      general = {
        before_sleep_cmd = lock;
        after_sleep_cmd = dpms "on";
        lock_cmd = "pgrep hyprlock || ${lib.getExe config.programs.hyprlock.package}";
      };

      # Every listener leaves ignore_inhibit at its default of false, so an
      # app holding an idle inhibit (Grayjay/Firefox while a video plays)
      # holds off the screen blank, the lock and the suspend alike.
      listener = [
        {
          timeout = lockTimeout;

          on-timeout = lock;
        }
        {
          timeout = dpmsTimeout;

          on-timeout = dpms "off";
          on-resume = dpms "on";
        }
        {
          timeout = suspendTimeout;

          on-timeout = suspend;
        }
      ];
    };
  };
}
