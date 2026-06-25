{ pkgs, ... }:
# Unlike templater.nix / dataview.nix (which build from source), Shell commands is
# fetched as its prebuilt release artifacts. Obsidian plugins are distributed as just
# three files (main.js / manifest.json / styles.css), so fetching the release avoids an
# npm/rollup build and the per-release npmDeps-hash churn that comes with it.
let
  version = "0.23.0";
  base = "https://github.com/Taitava/obsidian-shellcommands/releases/download/${version}";

  mainJs = pkgs.fetchurl {
    url = "${base}/main.js";
    hash = "sha256-DF4kepHJbAr18+MzukO+QoVGlWbIGdWbfeEprTPRTYo=";
  };
  manifest = pkgs.fetchurl {
    url = "${base}/manifest.json";
    hash = "sha256-IK6Mz6iXICfTW0RX0htquGrryOOx3uXro02tGeRqJGI=";
  };
  styles = pkgs.fetchurl {
    url = "${base}/styles.css";
    hash = "sha256-O9g4DlqlP8RH6mpMFN37lBmPGm0APm5fmUtFnPloTFM=";
  };
in
pkgs.runCommandLocal "obsidian.plugins.shellcommands-${version}"
{
  inherit version;
  # The obsidian HM module reads `pkg.manifestId` (falling back to manifest.json's id)
  # to name the plugin's directory under .obsidian/plugins/.
  passthru.manifestId = "obsidian-shellcommands";
}
  ''
    mkdir -p $out
    cp ${mainJs} $out/main.js
    cp ${manifest} $out/manifest.json
    cp ${styles} $out/styles.css
  ''
