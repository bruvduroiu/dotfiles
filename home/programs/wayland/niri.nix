{ config, inputs, lib, pkgs, ... }:

let
  cfg = config.desktop.niri;
  baseConfig = builtins.readFile ./niri.kdl;
  # Preserve the hand-written shared config; portable hosts omit only the
  # Framework output section, output pins and panel-specific brightness target.
  beforeOutputs = builtins.head (lib.splitString "// ----- outputs (framework13)" baseConfig);
  afterOutputs = builtins.elemAt (lib.splitString "// ----- layout" baseConfig) 1;
  portableConfig = lib.concatStringsSep "\n" (builtins.filter
    (line: !(lib.hasInfix "open-on-output " line))
    (lib.splitString "\n" (beforeOutputs + "// ----- layout" + afterOutputs)));
  configText = lib.concatStringsSep "\n" (builtins.filter
    (line: !(builtins.any (command: lib.hasInfix ("spawn \"" + command + "\"") line
      || line == "spawn-at-startup \"${command}\"") cfg.omittedApplications))
    (lib.splitString "\n" (if cfg.portable then lib.replaceStrings
      [ "\"brightness-up\" \"eDP-1\"" "\"brightness-down\" \"eDP-1\"" ]
      [ "\"brightness-up\"" "\"brightness-down\"" ] portableConfig else baseConfig)));
  source = pkgs.writeText "niri-config.kdl" (configText + "\n" + cfg.extraConfig);
  noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # Validate first login without colors and both generated theme modes.
  # Only config.kdl is installed: Noctalia owns the writable color include.
  configDir = pkgs.runCommand "niri-config" {
    nativeBuildInputs = [ pkgs.niri noctalia ];
  } ''
    mkdir -p $out
    export GSETTINGS_BACKEND=memory
    export NOCTALIA_CONFIG_HOME="$TMPDIR" NOCTALIA_STATE_HOME="$TMPDIR"
    cp ${source} $out/config.kdl
    niri validate -c $out/config.kdl
    for mode in dark light; do
      noctalia theme ${../../wallpapers/taipei-toner-4k-negative.png} \
        --default-mode "$mode" \
        -r ${inputs.noctalia}/assets/templates/niri/niri.kdl:$out/noctalia.kdl > /dev/null
      niri validate -c $out/config.kdl
    done
  '';
in {
  options.desktop.niri = {
    portable = lib.mkEnableOption "automatic output placement without Framework monitor pins";
    omittedApplications = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Applications whose shared launch bindings and autostarts are omitted.";
    };
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Host-specific Niri configuration appended to the shared layout.";
    };
  };
  config.xdg.configFile."niri/config.kdl".source = "${configDir}/config.kdl";
}
