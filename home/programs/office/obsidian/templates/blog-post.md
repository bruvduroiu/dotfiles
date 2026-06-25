<%*
// Blog Post — Hugo page-bundle scaffold.
// Backup of the vault file `9 - Templates/Blog Post.md`. Templates live in the vault
// (Syncthing-synced); this copy is version-controlled, like scripts/moedict_fetch.js.
const title = await tp.system.prompt("Post title");
const slug = title
  .toLowerCase()
  .replace(/[^a-z0-9]+/g, "-")
  .replace(/(^-|-$)/g, "");
// Move into a page bundle: 4 - Blogs/blog/<slug>/index.md (co-located images work).
await tp.file.rename("index");
await tp.file.move("/4 - Blogs/blog/" + slug + "/index");
-%>
---
title: "<% title %>"
date: <% tp.date.now("YYYY-MM-DDTHH:mm:ssZ") %>
topics: []
draft: true
---

<!--
Optional front matter (uncomment as needed):
categories: []
series: ""        # name of the series this post belongs to
tools: []         # technologies mentioned (taxonomy)
layout: "default" # default | tutorial | longform
description:      # auto-generated from first paragraph if unset
image:            # auto-detects cover.* in the page bundle
-->

## Introduction


## Main Content


## Conclusion
