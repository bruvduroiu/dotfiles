-- Rewrite ```mermaid fenced code blocks into <pre class="mermaid">…</pre> so the
-- browser-side mermaid.js (loaded by template.html) finds and renders them.
--
-- pandoc's default HTML would wrap the code in <pre><code class="mermaid">, whose
-- nested <code> and entity handling break mermaid's text extraction. Emitting a
-- bare <pre class="mermaid"> with HTML-escaped text means the browser's textContent
-- decodes back to the exact diagram source (arrows like -->, labels with <, & …).

local function html_escape(s)
  return (s:gsub("[&<>]", { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;" }))
end

function CodeBlock(el)
  if el.classes:includes("mermaid") then
    return pandoc.RawBlock("html", '<pre class="mermaid">' .. html_escape(el.text) .. "</pre>")
  end
end
