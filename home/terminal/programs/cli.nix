{ pkgs, config, ... }:

let
  # Script to combine Steam recording chunks into a single video file
  steam-recording-combine = pkgs.writeShellScriptBin "steam-recording-combine" ''
    set -euo pipefail

    if [ $# -lt 2 ]; then
      echo "Usage: steam-recording-combine <chunks-folder> <output-file>"
      echo ""
      echo "Combines Steam game recording chunks into a single video file."
      echo ""
      echo "Arguments:"
      echo "  chunks-folder  Directory containing init-stream*.m4s and chunk-stream*.m4s files"
      echo "  output-file    Output video file path (e.g., ~/Videos/gameplay.mp4)"
      exit 1
    fi

    CHUNKS_DIR="$1"
    OUTPUT_FILE="$2"

    if [ ! -d "$CHUNKS_DIR" ]; then
      echo "Error: Directory '$CHUNKS_DIR' does not exist"
      exit 1
    fi

    # Check for required files
    if [ ! -f "$CHUNKS_DIR/init-stream0.m4s" ]; then
      echo "Error: init-stream0.m4s not found in '$CHUNKS_DIR'"
      exit 1
    fi

    # Create temp directory for intermediate files
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    echo "Combining video chunks..."
    cat "$CHUNKS_DIR"/init-stream0.m4s "$CHUNKS_DIR"/chunk-stream0-*.m4s > "$TEMP_DIR/video.mp4"

    echo "Combining audio chunks..."
    cat "$CHUNKS_DIR"/init-stream1.m4s "$CHUNKS_DIR"/chunk-stream1-*.m4s > "$TEMP_DIR/audio.mp4"

    echo "Muxing audio and video..."
    ${pkgs.ffmpeg}/bin/ffmpeg -y -i "$TEMP_DIR/video.mp4" -i "$TEMP_DIR/audio.mp4" -c copy "$OUTPUT_FILE"

    echo "Done! Output saved to: $OUTPUT_FILE"
  '';
in
{
  home.packages = with pkgs; [
    zip
    unzip

    libnotify
    ripgrep
    ripdrag

    steam-recording-combine
    
    age-plugin-yubikey
  ];

  programs = {
    ssh = {
      enable = true;
      enableDefaultConfig = false;
    };
  };
}
