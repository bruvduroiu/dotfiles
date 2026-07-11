{
  lib,
  stdenv,
  makeBinaryWrapper,
  pandoc,
  python3,
  playwright-driver,
  fetchurl,
  jetbrains-mono,
  bash,
  coreutils,
  gnused,
  gnugrep,
}:

let
  pythonEnv = python3.withPackages (ps: [ ps.playwright ]);

  # Single offline asset: the browser-side mermaid bundle. Rendered client-side
  # by the same chromium that prints the PDF (exactly how the Claude web UI draws
  # diagrams), so no mermaid-cli / mmdc is needed. Pinned + embedded into the HTML
  # by pandoc's --embed-resources, so builds and renders work with no network.
  mermaidJs = fetchurl {
    url = "https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.min.js";
    hash = "sha256-pDvBr9RG+cTMZqxd1F0C6NZeJvxTROwO94f4jW3bb54=";
  };

  # Geist Sans drives the display/body look (Vercel's typeface). Variable woff2 —
  # one file covers all weights (100–900); referenced by absolute store path in the
  # themes so headless chromium loads it directly.
  geistSans = fetchurl {
    url = "https://cdn.jsdelivr.net/npm/geist@1.3.1/dist/fonts/geist-sans/Geist-Variable.woff2";
    hash = "sha256-KCWNBiEhaUhBaoWdMkh6tq0cnv+g0IeVaY5wvjyRdjA=";
  };
  # JetBrains Mono for code + ASCII diagrams: full-cell box-drawing glyphs so
  # ├─┐│→ line up. Variable [wght] file, taken straight from nixpkgs (no pinning).
  jbMonoVariable = "${jetbrains-mono}/share/fonts/WOFF2/JetBrainsMono[wght].woff2";
in
stdenv.mkDerivation {
  pname = "md2pdf";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ makeBinaryWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/md2pdf $out/share/md2pdf/themes $out/share/md2pdf/fonts

    cp template.html mermaid.lua print.py $out/lib/md2pdf/
    cp themes/*.css $out/share/md2pdf/themes/
    cp ${mermaidJs} $out/share/md2pdf/mermaid.min.js
    cp ${geistSans} $out/share/md2pdf/fonts/Geist-Variable.woff2
    cp "${jbMonoVariable}" $out/share/md2pdf/fonts/JetBrainsMono-Variable.woff2

    # Point each theme's @font-face at the bundled fonts by absolute path.
    substituteInPlace $out/share/md2pdf/themes/*.css \
      --subst-var-by fontdir $out/share/md2pdf/fonts

    # Bake absolute tool + data paths into the orchestrator. PLAYWRIGHT_BROWSERS_PATH
    # points chromium at the nix-managed browser (same trick as uber-receipts), so the
    # print step needs no browser download and works when launched from Obsidian's
    # minimal environment.
    substitute ${./md2pdf.sh} $out/bin/md2pdf \
      --subst-var-by bash ${bash} \
      --subst-var-by pandoc ${pandoc}/bin/pandoc \
      --subst-var-by python ${pythonEnv}/bin/python3 \
      --subst-var-by libdir $out/lib/md2pdf \
      --subst-var-by sharedir $out/share/md2pdf \
      --subst-var-by browsers ${playwright-driver.browsers} \
      --subst-var-by coreutils ${coreutils} \
      --subst-var-by gnused ${gnused} \
      --subst-var-by gnugrep ${gnugrep}
    chmod +x $out/bin/md2pdf

    runHook postInstall
  '';

  meta = {
    description = "Render Markdown (tables, images, LaTeX math, Mermaid) to a styled PDF via pandoc + headless chromium";
    license = lib.licenses.mit;
    mainProgram = "md2pdf";
    platforms = lib.platforms.linux;
  };
}
