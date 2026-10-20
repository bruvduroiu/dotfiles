# Hister search for people and coding agents

Hister owns file watching, keyword search, semantic indexing, the browser UI and
MCP. Its existing LAN EmbeddingGemma endpoint is shared by human and agent
searches. Claude, Codex and OpenCode receive `http://127.0.0.1:4433/mcp` through
the shared `coding-mcps` definitions on hosts running Hister.

`Mod+Alt+Space` on framework13 and the **Hister Search** desktop entry open
`http://127.0.0.1:4433/?q=-label:Code`. Keep that filter in the search box to
exclude code from keyword results, or remove it to include code. This is a
removable launch preset, not a persistent default on every visit to Hister.

Agents retain unrestricted access to the mixed corpus. Use `semantic=true` with
plain-English descriptions of behavior, then `get_preview` for selected results.
Use `semantic=false` with `url:`, `url_re:` or label filters for precise scoped
lookup. Agents must verify indexed code against live files.

**v0.20 limitation:** semantic results can escape label/path filters and exceed
the requested limit. The web preset reliably excludes code only with semantic
search off. There is no supported configuration for a web-only semantic filter
or per-query CodeRetrieval prefix. We keep the general EmbeddingGemma-2 search
prefix, 768 dimensions and the measured 0.62 threshold. This package contains no
custom search patches, reranker, query cache or replacement retrieval service.

The watched roots are declared in `../hister.nix`: development projects, Keep,
and text documents under Papers, Personal and Work. Code is indexed as text,
without syntax-aware chunking. Hidden directories, dependencies, build outputs
and common secret filenames are excluded; exclusions are basename globs, not
recursive path globs. They are not an access-control boundary. Hister's native
file indexing can follow file symlinks. Only add roots whose contents are
appropriate for the configured LAN embedding service.

## Docling

`hister-docling.service` submits PDFs, DOCX and other declared document/image
types to the existing Docling server at `http://192.168.1.193:8080`. OCR is enabled
without forcing OCR on digital PDFs. A timer runs two minutes after boot and
five minutes after each completed run, with at most ten conversions per run.

The worker writes Markdown beneath `~/.local/state/hister/docling/converted/`,
which Hister watches directly. It retains original paths and PDF page headings.
Search results open the generated Markdown; agents should cite the original
path and page from its contents. There is no custom opener or search wrapper.

Conversion state and cached structured results live beside that directory.
Unchanged documents are skipped, identical content is reused after renames,
pending server jobs resume, and failed conversions preserve the previous text.
Missing/unreadable roots do not cause generated documents to be deleted.
Original documents are never modified. Hister removes generated entries when
their Markdown files are removed.

Inspect conversion failures and pending work in
`~/.local/state/hister/docling/manifest.json` and the journal:

```sh
systemctl --user status hister hister-docling.timer
journalctl --user -u hister-docling
systemctl --user start hister-docling
```

Previously indexed native PDFs can remain in Hister after switching to converted
Markdown. Once conversion has caught up, review `hister cleanup --help` before
reconciling stale local entries. Activation does not delete those old entries.

## Validation

Conversion regression tests:

```sh
nix shell --impure --expr \
  'with import <nixpkgs> {}; python3.withPackages (ps: [ ps.requests ps.docling-core ps.pytest ])' \
  -c python -m pytest home/programs/hister/tests
```

Test Hister using a separate configuration, database, data directory and port.
Do not run trial imports or cleanup against the live index.
