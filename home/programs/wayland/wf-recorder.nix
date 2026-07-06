{ pkgs, ... }:

let
  wf-recorder-toggle = pkgs.writeShellApplication {
    name = "wf-recorder-toggle";
    runtimeInputs = with pkgs; [
      wf-recorder
      slurp
      libnotify
      coreutils
      procps # pgrep, pkill
    ];
    text = ''
      RECORDINGS_DIR="''${HOME}/Videos/Recordings"
      LOOPBACK_PID_FILE="/tmp/wf-recorder-loopback.pid"
      mkdir -p "$RECORDINGS_DIR"

      cleanup_loopback() {
        if [ -f "$LOOPBACK_PID_FILE" ]; then
          kill "$(cat "$LOOPBACK_PID_FILE")" 2>/dev/null || true
          rm -f "$LOOPBACK_PID_FILE"
        fi
      }

      # If already recording, stop and exit
      if pgrep -x wf-recorder > /dev/null; then
        pkill -SIGINT wf-recorder
        cleanup_loopback
        notify-send "Recording stopped" "Saved to $RECORDINGS_DIR"
        exit 0
      fi

      # Clean up any leftover loopback from a previous crashed session
      cleanup_loopback

      FILENAME="$RECORDINGS_DIR/recording-$(date +%Y%m%d-%H%M%S).mp4"

      # Get the PipeWire object ID of the default audio sink.
      # We use pw-loopback to capture the sink's audio output (what you hear)
      # because PipeWire doesn't expose .monitor sources for Bluetooth sinks
      # through PulseAudio compat — making pactl-based approaches unreliable.
      SINK_ID="$(wpctl inspect @DEFAULT_AUDIO_SINK@ | head -1 | awk '{print $2}' | tr -d ',')"

      if [ -z "$SINK_ID" ]; then
        notify-send "Recording failed" "No default audio sink found"
        exit 1
      fi

      # Create a PipeWire loopback that captures the sink's monitor output
      # and exposes it as a virtual source for wf-recorder.
      pw-loopback \
        --capture-props="target.object=$SINK_ID stream.capture.sink=true" \
        --playback-props="media.class=Audio/Source node.name=wf-recorder-audio" &
      echo $! > "$LOOPBACK_PID_FILE"
      sleep 0.5

      ARGS=(--audio --audio-device=wf-recorder-audio -f "$FILENAME")

      if [ "''${1:-}" = "area" ]; then
        GEOMETRY=$(slurp)
        if [ -z "$GEOMETRY" ]; then
          cleanup_loopback
          exit 1
        fi
        ARGS+=(-g "$GEOMETRY")
      fi

      wf-recorder "''${ARGS[@]}" &
      disown

      if [ "''${1:-}" = "area" ]; then
        notify-send "Recording started" "Area recording..."
      else
        notify-send "Recording started" "Screen recording..."
      fi
    '';
  };
in
{
  home.packages = [
    wf-recorder-toggle
  ];
}
