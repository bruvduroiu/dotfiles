#!@bash@/bin/bash
# md2pdf — Markdown -> styled PDF.
#
#   Markdown --(pandoc: GFM tables, images, math->MathML, mermaid filter)--> HTML
#            --(chromium via playwright: renders mermaid.js + MathML + CSS)--> PDF
#
# Everything is bundled in the nix store, so it runs offline (except remote
# ![](https://…) images, which chromium/pandoc fetch if reachable).
set -euo pipefail

# Absolute paths baked in at build time; also fix PATH for the coreutils/grep/sed
# we call, since Obsidian launches this with a minimal environment.
export PATH="@coreutils@/bin:@gnused@/bin:@gnugrep@/bin:$PATH"
export PLAYWRIGHT_BROWSERS_PATH="@browsers@"

PANDOC="@pandoc@"
PYTHON="@python@"
LIBDIR="@libdir@"
SHAREDIR="@sharedir@"

theme="report"
output=""

usage() {
  cat >&2 <<'EOF'
Usage: md2pdf [--theme NAME] [--output FILE.pdf] INPUT.md

  --theme NAME      style to apply (a themes/<NAME>.css); default: report
  -o, --output FILE output path; default: INPUT.pdf next to the source
EOF
  exit 1
}

args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --theme) theme="${2:?--theme needs a value}"; shift 2 ;;
    --theme=*) theme="${1#*=}"; shift ;;
    -o | --output) output="${2:?--output needs a value}"; shift 2 ;;
    --output=*) output="${1#*=}"; shift ;;
    -h | --help) usage ;;
    -*) echo "md2pdf: unknown option: $1" >&2; usage ;;
    *) args+=("$1"); shift ;;
  esac
done

[ "${#args[@]}" -eq 1 ] || usage
input="${args[0]}"
[ -f "$input" ] || { echo "md2pdf: no such file: $input" >&2; exit 1; }

theme_css="$SHAREDIR/themes/$theme.css"
if [ ! -f "$theme_css" ]; then
  echo "md2pdf: unknown theme '$theme' (no $theme_css)" >&2
  echo "md2pdf: available themes:" >&2
  for f in "$SHAREDIR"/themes/*.css; do echo "  - $(basename "$f" .css)" >&2; done
  exit 1
fi

[ -n "$output" ] || output="${input%.*}.pdf"

indir="$(cd "$(dirname "$input")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Document title: first level-1 heading, else the file stem. Drives <title> and
# can be surfaced by themes / running headers.
title="$(grep -m1 '^# ' "$input" | sed 's/^#[[:space:]]*//' || true)"
[ -n "$title" ] || title="$(basename "$input" .md)"

# --resource-path lets pandoc find relative images; --embed-resources inlines
# images + the theme CSS + mermaid.js into one self-contained HTML file so the
# print step has no path/network surprises. --mathml renders $x$/$$…$$ to MathML
# Core, which chromium draws natively (no KaTeX bundle needed).
"$PANDOC" "$input" \
  --from markdown+pipe_tables \
  --to html5 \
  --standalone \
  --embed-resources \
  --resource-path="$indir" \
  --mathml \
  --lua-filter="$LIBDIR/mermaid.lua" \
  --template="$LIBDIR/template.html" \
  --metadata title="$title" \
  --variable theme_css="$theme_css" \
  --variable mermaid_js="$SHAREDIR/mermaid.min.js" \
  --output "$tmp/doc.html"

"$PYTHON" "$LIBDIR/print.py" "$tmp/doc.html" "$output"

echo "md2pdf: wrote $output"
