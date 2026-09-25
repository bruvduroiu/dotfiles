{ config, lib, pkgs, ... }:

# Push-to-talk dictation: hold a key, talk, release, and the transcript is
# typed at the cursor -- a Claude Code prompt, a chat box, anything.
#
# THE SHAPE. voxtype (nixpkgs) owns the hotkey (evdev, hence the `input`
# group), the PipeWire capture (16 kHz mono) and the typing. It does NOT run a
# model here: `backend = "remote"` ships each clip to the Qwen3-ASR server on
# the mbp (homelab: modules/qwen3-asr.nix, docs/qwen3-asr.md), an
# OpenAI-shaped POST /v1/audio/transcriptions with a bearer token. One model
# covers en/ro/zh at ~0.5-0.7 s per 10 s clip on that M1 Pro, against the
# laptop CPU's 8-9 s for whisper-turbo (measured 2026-10-08).
#
# voxtype-onnx rather than plain voxtype: same binary plus the Parakeet/ONNX
# engine, so a LOCAL fallback (parakeet-tdt-0.6b-v3-int8: 0.32 s per 13 s
# clip on this CPU, English only) is a config swap away when the Mac is
# unreachable. Not wired by default -- it would pin 640 MB of weights in the
# store for a path that is off most of the time.
#
# TYPING GOES THROUGH dotool, NOT wtype. niri implements the virtual-keyboard
# protocol, but niri-wm/niri#2314 ("wtype makes input unusable" -- the focused
# app stops receiving keys after wtype exits) is open as of 2026-10 and the
# fix (PR #4548) has not landed. dotool types through /dev/uinput instead,
# which needs the `uinput` group (hosts/framework13/default.nix) and a
# re-login after the first switch. wtype stays second in the chain for the day
# that PR lands; clipboard is the last resort.
#
# HOTKEY: F19, held -- a key that exists only on the ZSA Voyager, where one
# Oryx layer key sends it. F19 is the one key in F13-F24 that xkeyboard-config
# leaves as itself (F20 is XF86AudioMicMute, the ThinkPad mic-mute key: it
# MUTED THE MIC on every hold before this was found; F21-F23 are touchpad
# toggles, F13-F18 launchers), so holding it means nothing to niri or any app
# and leaks no modifier into the focused window while you talk. The internal
# keyboard has no F19 and is deliberately NOT remapped (a kanata tap-hold was
# tried and dropped as not worth the machinery): on it, Mod+V toggles. niri
# binds cannot fire on key RELEASE, so hold-to-talk has to be evdev.
let
  cfg = config.services.dictation;

  configFile = (pkgs.formats.toml { }).generate "voxtype.toml" {
    engine = "whisper"; # the engine that owns the remote backend
    hotkey = {
      key = cfg.hotkey;
      modifiers = [ ];
      mode = "push_to_talk";
      enabled = true;
    };
    audio = {
      device = "default";
      sample_rate = 16000;
      # Safety cap; a Claude prompt is seconds, not minutes. The server's own
      # limit is hours.
      max_duration_secs = 90;
      feedback = {
        enabled = true;
        theme = "subtle";
        volume = 0.5;
      };
    };
    whisper = {
      mode = "remote"; # "backend" is the deprecated spelling of the same switch
      # "auto": the language field is omitted and Qwen3-ASR detects per clip.
      # Pinning "en" here would make it decode Romanian AS English.
      language = "auto";
      translate = false;
      remote_endpoint = cfg.endpoint;
      # Accepted for compatibility and ignored: the server serves one model.
      remote_model = "qwen3-asr-0.6b";
      remote_timeout_secs = cfg.timeoutSecs;
    };
    # The nixpkgs build ships no voxtype-osd-* helper; left enabled, the daemon
    # spawns it three times at every start and logs an ERROR before giving up.
    osd.enabled = false;
    output = {
      mode = "type";
      fallback_to_clipboard = true;
      driver_order = [ "dotool" "wtype" "clipboard" ];
      type_delay_ms = 0;
      # Reads modifier state over evdev so a still-held Ctrl cannot turn the
      # first typed letter into a shortcut.
      wait_for_modifier_release = true;
      modifier_release_timeout_ms = 750;
      notification = {
        on_recording_start = false;
        on_recording_stop = false;
        # The typed text is its own feedback; a toast per utterance is noise.
        # Failures (server down, 401) still notify.
        on_transcription = false;
        urgency = "low";
      };
    };
  };

  # The bearer token is read at start, never written into the unit or the
  # config (both end up in the store). A missing file degrades to "no auth"
  # with a warning rather than failing the unit, so a fresh host without the
  # secret still gets a daemon -- it just gets 401s until the key exists.
  daemon = pkgs.writeShellApplication {
    name = "voxtype-daemon";
    runtimeInputs = [ cfg.package pkgs.coreutils ];
    text = ''
      ${lib.optionalString (cfg.apiKeyFile != null) ''
        if [ -r ${lib.escapeShellArg cfg.apiKeyFile} ]; then
          VOXTYPE_WHISPER_API_KEY=$(cat ${lib.escapeShellArg cfg.apiKeyFile})
          export VOXTYPE_WHISPER_API_KEY
        else
          echo "voxtype-daemon: API key file ${cfg.apiKeyFile} unreadable; remote requests will be unauthenticated" >&2
        fi
      ''}
      # Global flags go BEFORE the subcommand: `voxtype daemon -c` is rejected.
      exec voxtype -c ${configFile} daemon
    '';
  };
in
{
  options.services.dictation = {
    enable = lib.mkEnableOption "push-to-talk dictation via voxtype and the mbp Qwen3-ASR server";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.voxtype-onnx;
      defaultText = lib.literalExpression "pkgs.voxtype-onnx";
      description = "voxtype build to run; the -onnx variant keeps a local Parakeet fallback possible.";
    };

    endpoint = lib.mkOption {
      type = lib.types.str;
      # The mbp's DHCP lease. It has moved twice (homelab docs/fleet.md); the
      # day the router's dnsmasq carries a name for it, put that here.
      default = "http://192.168.1.193:8082";
      description = "Base URL of the OpenAI-compatible transcription server (no path).";
    };

    apiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        File holding the bearer token (the mbp's `qwen3-asr/api-key` clan var).
        Read at daemon start into VOXTYPE_WHISPER_API_KEY. null sends no
        Authorization header.
      '';
    };

    hotkey = lib.mkOption {
      type = lib.types.str;
      default = "F19";
      description = "evdev key name to hold for push-to-talk (`evtest` lists them). F19 is what the Voyager sends.";
    };

    timeoutSecs = lib.mkOption {
      type = lib.types.int;
      default = 15;
      description = "Remote request timeout. A 90 s clip is ~5 s of inference; the default 30 only hides a dead server longer.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package # `voxtype record toggle` from niri binds, `voxtype status` for the bar
      pkgs.dotool
    ];

    systemd.user.services.voxtype = {
      Unit = {
        Description = "voxtype push-to-talk dictation";
        After = [ "graphical-session.target" "pipewire.service" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${daemon}/bin/voxtype-daemon";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # Compositor-side controls. Hold-to-talk itself is evdev (above), because
    # niri binds fire on press only.
    desktop.niri.extraBinds = ''
      Mod+V hotkey-overlay-title="Dictate: toggle recording" { spawn "voxtype" "record" "toggle"; }
      Mod+Alt+V hotkey-overlay-title="Dictate: cancel" { spawn "voxtype" "record" "cancel"; }
    '';
  };
}
