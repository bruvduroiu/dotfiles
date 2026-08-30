{ pkgs, lib, config, ... }:

let
  lock = "${pkgs.procps}/bin/pgrep -x swaylock || ${lib.getExe config.programs.swaylock.package} -f";
  niri = "${pkgs.niri}/bin/niri";

  # Lock before blanking, not after: swaylock has to get its first paint in
  # while the output is still powered, otherwise waking takes seconds.
  # Same timings and ordering as the hypridle setup this replaces.
  lockTimeout = 300;
  dpmsTimeout = lockTimeout + 30;
  suspendTimeout = 1800;
in
{
  # Idle daemon for the niri session (hypridle.nix stays alongside for the
  # Hyprland hosts). swayidle listens on ext-idle-notify, so an app holding
  # an idle inhibit (video playback) holds off blank, lock and suspend alike.
  services.swayidle = {
    enable = true;

    events = [
      { event = "before-sleep"; command = lock; }
      { event = "lock"; command = lock; }
    ];

    timeouts = [
      {
        timeout = lockTimeout;
        command = lock;
      }
      {
        timeout = dpmsTimeout;
        command = "${niri} msg action power-off-monitors";
        resumeCommand = "${niri} msg action power-on-monitors";
      }
      {
        timeout = suspendTimeout;
        command = "${pkgs.systemd}/bin/systemctl suspend";
      }
    ];
  };
}
