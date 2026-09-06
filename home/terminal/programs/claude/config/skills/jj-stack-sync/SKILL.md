---
name: jj-stack-sync
description: Keep a pushed jj stack healthy after review — fold fixes into the revisions that own them with jj absorb, rebase onto a moved trunk, drop revisions whose PRs merged (squash-merges included), re-push with lease safety, and post each PR a "what changed since your last look" interdiff.
argument-hint: "<topic> [fix | rebase | merged]"
disable-model-invocation: true
metadata:
  origin: local
---

# jj-stack-sync — maintain a stack through review and merges

## The mental model

- **Fixes go to the revision that owns the lines.** `jj absorb` splits the
  working copy hunk by hunk and squashes each into the nearest ancestor that
  last touched those lines. No fixup commits, no `--autosquash`, and you
  never need to know which revision a fix belongs to.
- **Bookmarks follow rewrites.** After absorb or rebase, every
  `<topic>-nn-*` bookmark already points at the rewritten revision. You
  re-push; you do not re-set.
- **`<bookmark>@origin` is what the reviewer last saw.** Until you push, it
  is a stable name for the old commit, so `jj interdiff --from <bm>@origin
  --to <bm>` is exactly "what changed since your review". Capture it *before*
  pushing, because pushing makes the two equal.
- **A merged revision becomes empty when rebased onto trunk**, whether the
  forge merged, rebased, or squash-merged it, because its content is now in
  trunk. `--skip-emptied` drops it. This is what makes squash-merge stacks
  painless in jj and painful in git.
- **Conflicts live in the revision that created them** and resolving them
  there heals every descendant.

## Scope of authority

`jj absorb`, `jj squash --into`, `jj rebase -b`, `jj bookmark set/delete`,
`jj git fetch`, `jj git push -b 'glob:<topic>-*'`, PR comments and base
retargeting — for `trunk()..@ & mine()` only. `jj abandon`, `jj undo`,
`jj op restore` stay human-only; print the op id before starting.

```bash
jj op log --limit 1 --no-graph -T 'id.short() ++ "\n"'
STACK='bookmarks(glob:"<topic>-*")'
```

## Mode: fix — review feedback came in

1. Work on top of the stack. If `@` is not an empty child of the tip:
   `jj new 'heads(<STACK>)'`.
2. Make every fix, across all revisions, in this one working copy.
3. Route them:

   ```bash
   jj absorb --into 'trunk()..@-'         # bounded to this stack
   jj st                                  # what absorb could not attribute stays in @
   jj op show -p                          # audit where each hunk went
   ```

   Leftovers in `@` are either new lines that no revision touched — route
   by hand with `jj squash --into <rev> -u <paths>` — or genuinely new work,
   which becomes a new revision on top (`jj describe`, then it gets its own
   bookmark and PR in step 6).
4. Gate again: `jj-stack-check`.
5. Capture the per-PR interdiff **before pushing**:

   ```bash
   for bm in $(jj bookmark list -T 'if(self.remote(), "", name ++ "\n")' | grep '^<topic>-'); do
     jj interdiff --from "$bm@origin" --to "$bm" --git > <scratch>/$bm.diff
   done
   ```

   An empty file means that PR did not change; say nothing on it.
6. Push and comment:

   ```bash
   jj git push -b 'glob:<topic>-*'
   gh pr comment <n> --body-file <file>      # glab mr note <n> -m "…" / fj pr comment <n> …
   ```

   Comment shape: *"Since your last review: <one line per interdiff hunk,
   in words>. Full interdiff below."* then the diff in a fenced block.
   Reviewers should never have to re-read a whole PR to find the fix.

## Mode: rebase — trunk moved under the stack

```bash
jj git fetch
jj rebase -b "$STACK" -o 'trunk()'         # whole stack, one operation, descendants follow
jj log -r 'conflicts()'
```

For each conflicted revision, resolve *there*, not at the tip:

```bash
jj new <conflicted rev>       # child of the conflicted revision
# edit the files: remove markers, keep the intended result
jj squash                     # into its parent; the parent's description is kept, no editor
```

Then gate, capture interdiffs (a pure rebase usually yields empty ones), and
push with the topic glob. The push moves every bookmark "sideways"; that is
the lease-safe update, not a force push.

## Mode: merged — a PR at the bottom (or middle) landed

```bash
jj git fetch                                        # tracked bookmark deleted upstream disappears locally
jj rebase -b "$STACK" -o 'trunk()' --skip-emptied   # merged content is in trunk → that revision empties → dropped
jj log -r 'trunk()..@'                              # the merged revision should be gone
```

If the forge kept the branch, delete the bookmark locally and push the
deletion by name:

```bash
jj bookmark delete <topic>-01-<slug>
jj git push -b <topic>-01-<slug>
```

Retarget the next PR's base to trunk. GitHub does this on its own when the
base branch is deleted; otherwise `gh pr edit <n> --base main` or
`glab mr update <n> --target-branch main`. Forgejo's `fj pr edit` has no
flags: tell the human to change the base in the web UI.

Then gate and push the topic glob.

## Someone pushed to your branch

A reviewer applied a suggestion, or pushed a commit onto `<bm>`. After
`jj git fetch` the bookmark is *conflicted* (`jj bookmark list -a` shows
two targets). Take their commit into your stack rather than overwriting it:

```bash
jj log -r '<bm>@origin'                         # their commit sits on your old push
jj rebase -r '<bm>@origin' -o '<bm>'            # bring it on top of your current revision
jj absorb -f '<bm>@origin' --into 'trunk()..<bm>'   # fold it into the revision it belongs to
jj bookmark set <bm> -r '<bm>'                  # resolve the bookmark conflict onto your side
```

Then gate, interdiff, push.

## Anti-pattern clinic

- **A "fix review comments" revision at the top.** That is a fixup commit
  wearing a hat; absorb it.
- **`jj edit <rev>` to fix it in place.** Works, but every keystroke
  rebases the stack and the diff you meant to make is invisible. Fix on top,
  absorb, audit with `jj op show -p`.
- **Resolving a conflict at the tip.** It heals nothing below and the
  conflicted PR stays conflicted. Resolve in the owning revision.
- **Pushing, then trying to produce "what changed".** `<bm>@origin` is now
  equal to `<bm>`; the interdiff is gone. Capture first, push second.
- **Deleting and re-creating a workspace over staleness.** `jj workspace
  update-stale`, then re-read `jj diff`.
- **`jj git push --deleted` to clean up.** Pushes *every* deleted bookmark,
  including ones that are not this stack's. Name the bookmark.
- **Force-pushing over a reviewer's commit.** jj will refuse anyway; the
  section above is the path.
