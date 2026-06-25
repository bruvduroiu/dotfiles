{ pkgs
, version ? "0.5.70"
}:

pkgs.stdenv.mkDerivation rec {
  pname = "obsidian-dataview";
  inherit version;

  srcs = [
    (pkgs.fetchurl {
      url = "https://github.com/blacksmithgu/obsidian-dataview/releases/download/${version}/manifest.json";
      sha256 = "sha256-kjXbRxEtqBuFWRx57LmuJXTl5yIHBW6XZHL5BhYoYYU=";
      name = "manifest.json";
    })
    (pkgs.fetchurl {
      url = "https://github.com/blacksmithgu/obsidian-dataview/releases/download/${version}/main.js";
      sha256 = "sha256-a7HPcBCvrYMOc1dfyg4r+9MnnFYuPZ0k8tL0UWHrfQA=";
      name = "main.js";
    })
    (pkgs.fetchurl {
      url = "https://github.com/blacksmithgu/obsidian-dataview/releases/download/${version}/styles.css";
      sha256 = "sha256-MwbdkDLgD5ibpyM6N/0lW8TT9DQM7mYXYulS8/aqHek=";
      name = "styles.css";
    })
  ];

  dontBuild = true;
  dontStrip = true;

  unpackPhase = ''
    for src in $srcs; do
      cp $src ./
    done
    find . -name "*manifest.json" -exec mv {} manifest.json \;
    find . -name "*main.js" -exec mv {} main.js \;
    find . -name "*styles.css" -exec mv {} styles.css \;
  '';

  installPhase = ''
    mkdir -p $out
    cp manifest.json main.js styles.css $out/
  '';
}
