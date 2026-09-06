---
name: jj-stack-push
description: Publish a verified jj stack as a chain of stacked pull requests — one bookmark per revision, one lease-safe push, one PR per revision based on the PR below it, each carrying a review guide with a human-written Why. Refuses to push a stack that fails jj-stack-check. Follow with /jj-stack-sync after review.
argument-hint: "<topic> [--limit N] [--draft] [--remote NAME]"
disable-model-invocation: true
metadata:
  origin: local
---

# jj-stack-push — publish a stack as stacked PRs

## The mental model

- **A bookmark is the branch name the forge sees.** jj has no checkout; a
  bookmark is a label you set on a revision. `<topic>-01-<slug>` on revision
  1, `<topic>-02-<slug>` on revision 2, and so on. Bookmarks follow their
  revision through later rewrites, so you set them once.
- **PR *k* is based on bookmark *k-1*.** The forge then shows only revision
  *k*'s diff. PR 1 is based on trunk. That is the entire trick.
- **`jj git push` is force-with-lease by nature.** It refuses to move a
  remote bookmark that changed since your last fetch. There is no
  `--force`, and you never need one.
- **The size gate is a gate.** `jj-stack-check` must pass before anything
  leaves the machine.

## Scope of authority

`jj bookmark set`, `jj git push -b 'glob:<topic>-*'`, and PR creation for
revisions in `trunk()..@ & mine()`. Nothing else is rewritten here.

## Procedure

### 0. Gate

```bash
jj-stack-check                    # default revset trunk()..@ ~ (@ & empty()); add -l N if the plan overrode the limit
```

Non-zero exit: stop and send the user back to `/jj-stack`. Do not push a
stack with `TOO-BIG`, `EMPTY`, `NO-DESC`, `CONFLICT`, or `NOT-MINE` rows.

### 1. Forge and tool

```bash
jj git remote list                # url → forge
```

| URL contains | CLI | if missing on this machine |
|---|---|---|
| `github.com` | `gh` | `nix run nixpkgs#gh -- …` |
| `gitlab` | `glab` | `nix run nixpkgs#glab -- …` |
| anything else (Forgejo/Gitea) | `fj` | `nix run nixpkgs#forgejo-cli -- …` |

Check reachability before planning on it: `command -v gh`. Auth is the
human's problem; if the CLI says it is not logged in, ask them to run the
login with the `!` prefix.

### 2. Gather the human's Why — before any bookmark exists

Ask once, for the stack as a whole: *why does this change exist, in your own
words?* Never write the Why yourself. A PR whose rationale was generated is
exactly the PR reviewers in the thread refused to read. The per-revision
What comes from each revision's description body, which was written during
`/jj-stack` with the human's approval.

### 3. Name the bookmarks

`<topic>-<nn>-<slug>`: topic from `$ARGUMENTS`, `nn` two digits bottom-up,
slug from the description's first line (kebab-case, drop the `feat:` style
prefix, at most 30 chars).

```bash
jj log -r 'trunk()..@ ~ (@ & empty())' --reversed --no-graph \
  -T 'change_id.short() ++ "\t" ++ description.first_line() ++ "\n"'
jj bookmark set <topic>-01-<slug> -r <change id>     # idempotent: re-running moves, not duplicates
jj bookmark set <topic>-02-<slug> -r <change id>
```

Trunk's bookmark name (`main`, `master`, …): `jj log -r 'trunk()' -T 'bookmarks'`,
strip the `@origin`.

### 4. Push, once

```bash
jj git push -b 'glob:<topic>-*' --dry-run
jj git push -b 'glob:<topic>-*'                  # --remote NAME if $ARGUMENTS says so
```

If `git.sign-on-push` is on, this is one signing touch per new revision; warn
the human before the real push so the YubiKey prompt is expected.

### 5. Open the PRs, bottom-up

Write each body to a scratch file first (the scratchpad directory, never the
repo), then create. Base for PR 1 is trunk's bookmark; base for PR *k* is
bookmark *k-1*.

```bash
# GitHub
gh pr create --base <base> --head <bookmark> --title "<first line>" --body-file <file> [--draft]
# GitLab
glab mr create --source-branch <bookmark> --target-branch <base> --title "<first line>" --description "$(cat <file>)" [--draft]
# Forgejo / Gitea
fj pr create --base <base> --head <bookmark> --body-file <file> "<first line>"     # "WIP: " prefix = draft
```

Body template — short, and every section earns its place:

```markdown
## Why
<the human's words from step 2, verbatim>

## What
<this revision's description body>

## Stack <n>/<N> — read bottom-up
| # | branch | kind | lines |
|---|---|---|---|
| 1 | <topic>-01-… | refactor | +40/-12 |
| … | | | |
Below: <base>. Above: <topic>-<nn+1>-… (or "top of stack").

## Kind
refactor (no behaviour change) | behaviour change | tests | docs | chore

## Verified
<build/test command that ran on this revision>; tree invariant vs <blob commit id> holds for the stack.

## Review notes
<where to start, what to be suspicious of, what is deliberately out of scope>

---
Carved with jj from one change; each PR builds on the one below. AI-assisted: <no | yes — which parts>.
```

Where the CLI can edit bodies (`gh pr edit N --body-file`, `glab mr update`),
do a second pass once all numbers exist and replace branch names in the
stack table with `#N` links. `fj pr edit` takes no flags, so on Forgejo the
table stays branch-named; that is fine.

### 6. Report

One table, nothing else: `#`, bookmark, base, `+a/-d`, URL. Then point at
`/jj-stack-sync <topic>` for what happens after review.

## Anti-pattern clinic

- **One PR per file, or one PR for the whole stack.** The unit is the
  revision the plan approved, nothing smaller or larger.
- **PR *k* based on trunk.** Then the forge shows the cumulative diff and
  the stack was pointless. Every base except the first is a bookmark.
- **`jj git push --all` or `--tracked`.** Pushes bookmarks that are not this
  stack's. Always the topic glob.
- **`jj git push -c @`.** Auto-named `push-<change id>` branches are
  unreadable to colleagues. Name them.
- **Writing the Why.** Ask. Paste. Attribute.
- **Retrying a rejected push with more force.** A rejection means the remote
  moved: `jj git fetch`, look at `jj bookmark list -a`, and go to
  `/jj-stack-sync`.
