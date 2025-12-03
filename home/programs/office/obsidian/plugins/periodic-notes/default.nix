{ pkgs
, version ? "1.0.0-beta.3"
}:

pkgs.stdenv.mkDerivation rec {
  pname = "obsidian-periodic-notes";
  inherit version;

  srcs = [
    (pkgs.fetchurl {
      url = "https://github.com/liamcain/obsidian-periodic-notes/releases/download/${version}/manifest.json";
      sha256 = "sha256-vaKTI/ddOz/L2kiTNYJbl/5LV0kU0EY16afmfyQUBJw=";
      name = "manifest.json";
    })
    (pkgs.fetchurl {
      url = "https://github.com/liamcain/obsidian-periodic-notes/releases/download/${version}/main.js";
      sha256 = "sha256-k0ypQ1m2pLnwIJPUpE+lllTFI3sxzwLXuYLFgWiFG7E=";
      name = "main.js";
    })
    (pkgs.fetchurl {
      url = "https://github.com/liamcain/obsidian-periodic-notes/releases/download/${version}/styles.css";
      sha256 = "sha256-/ywAte550Y0C56j0jLLmUSyRL3X4juBT2UZoyQqWs5o=";
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
