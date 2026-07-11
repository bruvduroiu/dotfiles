#!/usr/bin/env python3
"""Print a self-contained HTML file to PDF with headless chromium (playwright).

Waits for template.html's mermaid render to finish (window.__md2pdfReady) before
printing, so diagrams are never cut off. Page geometry + the page-number footer
live here; per-document visual style lives in the theme CSS.
"""
import sys

from playwright.sync_api import sync_playwright

FOOTER = (
    '<div style="width:100%;font-size:8px;color:#999;text-align:center;'
    'font-family:sans-serif;">'
    '<span class="pageNumber"></span> / <span class="totalPages"></span>'
    "</div>"
)


def main() -> int:
    if len(sys.argv) != 3:
        sys.stderr.write("usage: print.py INPUT.html OUTPUT.pdf\n")
        return 2
    html_path, out_path = sys.argv[1], sys.argv[2]

    with sync_playwright() as p:
        browser = p.chromium.launch(args=["--no-sandbox"])
        page = browser.new_page()
        page.goto(f"file://{html_path}", wait_until="networkidle")
        try:
            page.wait_for_function("window.__md2pdfReady === true", timeout=30000)
        except Exception:
            sys.stderr.write("md2pdf: mermaid render timed out; printing anyway\n")
        page.emulate_media(media="print")
        page.pdf(
            path=out_path,
            format="A4",
            print_background=True,
            margin={"top": "18mm", "bottom": "20mm", "left": "18mm", "right": "18mm"},
            display_header_footer=True,
            header_template="<span></span>",
            footer_template=FOOTER,
        )
        browser.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
