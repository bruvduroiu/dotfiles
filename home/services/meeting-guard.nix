{ pkgs, ... }:

# Auto-DND during calls: while any pipewire capture stream is running
# (mic or screenshare/camera consumption), mako gets a "meeting" mode —
# invisible notifications, so nothing pops over a shared screen. Uses its
# own mako mode rather than "dnd" so the manual SUPER+SHIFT+D toggle and
# this guard never fight over the same flag.
let
  meeting-guard = pkgs.writeShellApplication {
    name = "meeting-guard";
    runtimeInputs = with pkgs; [ pipewire jq mako procps ];
    text = ''
      # clear stale state from a previous run
      makoctl mode -r meeting >/dev/null || true
      state=0
      while true; do
        n=$(pw-dump 2>/dev/null | jq '[.[]
              | select(.type == "PipeWire:Interface:Node"
                  and ((.info.props["media.class"] // "") | test("^Stream/Input/(Audio|Video)$"))
                  and .info.state == "running")
            ] | length' || echo 0)
        if [ "$n" -gt 0 ] && [ "$state" -eq 0 ]; then
          makoctl mode -a meeting >/dev/null
          state=1
          pkill -RTMIN+9 waybar || true
        elif [ "$n" -eq 0 ] && [ "$state" -eq 1 ]; then
          makoctl mode -r meeting >/dev/null
          state=0
          pkill -RTMIN+9 waybar || true
        fi
        sleep 5
      done
    '';
  };
in {
  systemd.user.services.meeting-guard = {
    Unit = {
      Description = "auto-DND while a call (mic/screenshare) is active";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${meeting-guard}/bin/meeting-guard";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
