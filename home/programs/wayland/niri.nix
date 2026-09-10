{ inputs, pkgs, ... }:

let
  noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # Validate first login without colors and both generated theme modes.
  # Only config.kdl is installed: Noctalia owns the writable color include.
  configDir = pkgs.runCommand "niri-config" {
    nativeBuildInputs = [ pkgs.niri noctalia ];
  } ''
    mkdir -p $out
    export GSETTINGS_BACKEND=memory
    export NOCTALIA_CONFIG_HOME="$TMPDIR" NOCTALIA_STATE_HOME="$TMPDIR"
    cp ${./niri.kdl} $out/config.kdl
    niri validate -c $out/config.kdl
    for mode in dark light; do
      noctalia theme ${../../wallpapers/taipei-toner-4k-negative.png} \
        --default-mode "$mode" \
        -r ${inputs.noctalia}/assets/templates/niri/niri.kdl:$out/noctalia.kdl > /dev/null
      niri validate -c $out/config.kdl
    done
  '';
in {
  xdg.configFile."niri/config.kdl".source = "${configDir}/config.kdl";
}
