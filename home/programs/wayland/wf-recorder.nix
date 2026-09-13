{ pkgs, ... }:

let
  wf-recorder-toggle = pkgs.writeShellApplication {
    name = "wf-recorder-toggle";
    runtimeInputs = with pkgs; [
      wf-recorder
      slurp
      libnotify
      coreutils
      jq
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

      # Niri and Hyprland each report the focused monitor over their own IPC.
      # Neither is a runtimeInput (this module is shared with the ISO profile),
      # so probe the ambient PATH and return empty if neither answers.
      focused_output() {
        if [ -n "''${NIRI_SOCKET:-}" ] && command -v niri > /dev/null; then
          niri msg --json focused-output 2>/dev/null | jq -r '.name // empty'
        elif [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl > /dev/null; then
          hyprctl -j monitors 2>/dev/null | jq -r 'map(select(.focused)) | .[0].name // empty'
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

      # The device is an argument to --audio itself; a separate --audio-device
      # flag does not exist and makes wf-recorder fall back to the default
      # PulseAudio source (the microphone), silently ignoring the loopback.
      ARGS=(--audio=wf-recorder-audio -f "$FILENAME")

      if [ "''${1:-}" = "area" ]; then
        GEOMETRY=$(slurp)
        if [ -z "$GEOMETRY" ]; then
          cleanup_loopback
          exit 1
        fi
        # wf-recorder picks the output containing the region on its own.
        ARGS+=(-g "$GEOMETRY")
      else
        # Given neither -g nor -o with several outputs connected, wf-recorder
        # prompts on stdin for which one to capture. Spawned from the
        # compositor there is no stdin, so it exits at once and the toggle
        # silently "starts" again on every press. Name the output instead.
        # Empty is safe: wf-recorder only prompts when there is a choice.
        OUTPUT=$(focused_output || true)
        if [ -n "$OUTPUT" ]; then
          ARGS+=(-o "$OUTPUT")
        fi
      fi

      wf-recorder "''${ARGS[@]}" &
      RECORDER_PID=$!
      disown

      # wf-recorder can still die just after launch (busy encoder, gone
      # output). Confirm it survived rather than claiming a recording that
      # no later press can stop.
      sleep 0.5
      if ! kill -0 "$RECORDER_PID" 2>/dev/null; then
        cleanup_loopback
        notify-send -u critical "Recording failed" "wf-recorder exited immediately"
        exit 1
      fi

      if [ "''${1:-}" = "area" ]; then
        notify-send "Recording started" "Area recording — press again to stop"
      else
        notify-send "Recording started" "Recording ''${OUTPUT:-screen} — press again to stop"
      fi
    '';
  };
in
{
  home.packages = [
    wf-recorder-toggle
  ];
}
