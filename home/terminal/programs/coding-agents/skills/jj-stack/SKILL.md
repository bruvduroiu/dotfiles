---
name: jj-stack
description: Carve one oversized jj revision (an agent blob, a day of work) into a stack of reviewable revisions of under ~400 changed lines each, refactors first and behaviour last, then prove the split changed nothing with a tree-invariant check. Run before opening PRs; follow with /jj-stack-push.
argument-hint: "[BLOB revset, default @ (or @- when @ is empty)] [--limit N]"
disable-model-invocation: true
metadata:
  origin: local
---

# jj-stack — carve a blob into a reviewable stack

A 6,000-line PR is not reviewable, by a human or by anyone supervising an AI
review. The fix is not a smarter reviewer; it is a sequence of small revisions
that each tell one story. jj makes producing that sequence cheap, and makes it
*provable* that the split did not change the code.

## The mental model

- **A stack is a linear chain of revisions on top of trunk.** Each one is a
  future PR. Reviewers read bottom-up. `trunk()..@` is the stack.
- **Splitting is replay, not surgery.** You rebuild the blob's final tree one
  step at a time from its parent, then rebase the blob itself on top. Whatever
  you replayed correctly merges cleanly (identical hunks on both sides never
  conflict); whatever you missed is left over in the blob as a remainder.
- **The tree invariant is the proof.** The tip of the finished stack must have
  the byte-for-byte tree of the original blob. `jj-stack-check --against
  <blob commit id>` verifies it. A split that changes behaviour is a bug.
- **Commit ids are anchors, change ids are handles.** A commit id survives
  every rewrite as a way to name "the tree as it was"; the change id is how
  you refer to the revision as it moves.
- **Descendants follow automatically.** Every jj rewrite rebases what is
  above it. There is no interrupted state, no `--continue`, no stash.

## Scope of authority

Invoking this skill authorises history surgery **only** on revisions that
are in the blob's stack and yours: `(<blob>-)::@ & mine()`. Concretely:
`jj new`, `jj restore --from`, `jj split`, `jj squash --from/--into`,
`jj rebase -r <blob>`, `jj describe`. Never: `jj edit`, `jj abandon`,
`jj undo`, `jj op restore`, any revision that is not `mine()`, any pushed
revision that another person has commented on. The human keeps the undo:
print the operation id first.

## Procedure

### 0. Anchor

```bash
jj op log --limit 1 --no-graph -T 'id.short() ++ "\n"'   # human's undo: jj op restore <id>
BLOB=$(jj log -r '<blob>' --no-graph -T 'change_id.short() ++ "\n"')
BLOB_COMMIT=$(jj log -r "$BLOB" --no-graph -T 'commit_id ++ "\n"')
BASE="$BLOB-"                                            # the blob's parent
```

The blob is `$ARGUMENTS` if given, else `@`, else `@-` when `@` is empty.
If `@` holds uncommitted scratch on top of the blob, stop and ask: the
snapshot would become part of the stack.

Record both ids in your reply. The commit id is what `--against` checks.

### 1. Read the blob

```bash
jj diff -r "$BLOB" --stat            # blast radius
jj diff -r "$BLOB" --summary         # A/M/D/R per file
jj dt   -r "$BLOB"                   # difftastic skim if the alias exists: refactor noise collapses
jj diff -r "$BLOB" <fileset>         # close read, one area at a time
```

Build a picture of *concerns*, not files: what was renamed, what was moved,
what new behaviour appeared, what tests pin it, what is generated or vendored.

### 2. Plan the stack, then stop for approval

Present a plan table and wait for the human to approve or edit it. The human
carves; you propose and execute. Do not start step 3 on your own judgement.

| # | kind | title (one line, imperative) | paths or hunks | ~lines |
|---|---|---|---|---|
| 1 | refactor | Rename `a()` to `alpha()` | `a.py`, callers | 40 |
| 2 | chore | Regenerate lockfile | `flake.lock` | 300 |
| 3 | behaviour | Add `feature()` | `b.py` | 120 |
| 4 | test | Cover `feature()` edge cases | `test_b.py` | 90 |

Kinds: `refactor` (no behaviour change), `move` (pure relocation, costs 0
lines), `chore` (deps, lockfiles, generated code), `behaviour`, `test`, `docs`.

**Taste rules** — these are where splits go wrong, so apply them deliberately:

1. **Refactors first, behaviour last.** Change the world until the feature is
   inevitable. Reviewer attention is a budget; spend it on the `behaviour`
   revisions and let the refactors be skimmed with difftastic.
2. **Seam by concern, not by file.** A file may be touched by several
   revisions. Splitting by file is the lazy split and the one reviewers
   complain about.
3. **Every revision stands alone — atomic and bisectable.** It builds, its
   tests pass, its message says *why*, and reverting it alone leaves a working
   tree. If two revisions cannot be described without naming each other, they
   are one revision. If you cannot say what one does in a line, it is two.
   The full contract is in the `jj-atomic` skill; step 4 enforces it.
4. **Tests travel with the behaviour they test**, or come just before it when
   they pin behaviour that already existed. A test that *fails* until a later
   revision never lands on its own: bisect would blame the test.
5. **Change interfaces in three moves, not one** (expand → migrate →
   contract): add the new API alongside the old, move callers over, delete
   the old. Each step is green; a "rename the signature" step whose callers
   arrive two revisions later is not.
6. **Generated, vendored and formatter churn gets its own `chore` revision**
   so it cannot hide a behaviour change, and its message names the command
   that reproduces it (`nix fmt`, `go generate ./...`). Pure moves are free
   (renames cost 0 lines).
7. **No `misc`, `cleanup`, or `address review` revisions.** Those are absorb
   material, not stack members.
8. **Reviewable order beats chronological order** — as long as every prefix
   of the stack still builds. The stack is a narrative for the reader, not a
   log of how the code was written.
9. **Independent work is not a stack.** If two concerns share no lines,
   propose two stacks (or siblings via `jj split -p`), not one chain.

Size: the default limit is 400 changed lines. It is a reviewability
heuristic, not a law; dense languages want less, boilerplate-heavy ones bear
more. Override with `--limit`, and say why in the plan.

### 3. Replay forward

For each planned step, bottom-up:

```bash
jj new "$BASE" -m "<title>" -m "<why, in a paragraph>"   # first step; later steps: jj new -m ... (on top of @)
jj restore --from "$BLOB" <paths that belong entirely to this step>
# partial files: edit them by hand to the intermediate state (any state is
# fine — the only 3-way merge happens at the end, against the blob itself)
jj diff --stat                                           # confirm size before moving on
```

Whole-file steps are `jj restore --from`; partial-file steps are hand edits.
`jj restore` also creates files the blob added and deletes files it removed.

When the last step is in place, put the blob on top and let it shrink to
whatever you did not replay:

```bash
jj rebase -r "$BLOB" -o @ --skip-emptied     # blob becomes the remainder, or vanishes
jj new 'heads(@::)'                          # clean scratch @ on top of the stack
```

Two fast paths when the partition is by whole file: `jj split -r <rev> -m
"<title for the selected part>" <fileset>` keeps `<fileset>` in `<rev>` under
the new message and moves the rest into a child that keeps the old message;
`jj squash --from <rev> --into <other> -u <fileset>` moves files between
existing revisions. Neither opens an editor.

### 4. Verify

```bash
jj-stack-check --against "$BLOB_COMMIT" -x '<build + test command>'
#   or: bash ~/.claude/skills/jj-stack/scripts/stack-check.sh …
jj log -r 'conflicts()'                          # must be empty
```

The check fails on: a revision over the limit, an empty revision, a missing
description, a conflict, a revision you did not author, tip tree ≠ blob
tree, and with `-x`, a revision where the command fails (`BROKEN`) or exits
125 (`UNTESTABLE`, bisect's "skip"). A surviving remainder still titled like
the blob means the plan missed something: either describe it as a real step
or fold it down with `jj squash --from <remainder> --into <step> -u <paths>`.

**`-x` is the bisectability proof, not an option.** Pick the command the
project's CI would run (`nix flake check`, `go test ./...`, `cargo test`),
the one that decides whether `jj bisect run` could later judge a revision.
Each revision's tree is exported read-only from the git store into a temp
dir: no workspace, no checkout, `@` never moves, nothing snapshots. The
export holds tracked files only, so a step that builds only thanks to an
ignored or untracked file is caught. `-x` is an ask-permission command; say
what it will run. Skip it only when the human says so, and say it was skipped.

A `BROKEN` revision usually means a seam in the wrong place: a caller moved
before its callee, a test before its fix, an import before the module.
Move the hunk with `jj squash --from <later> --into <broken> -u <paths>`
(or reorder), never by adding a "fix build" revision on top.

### 5. Hand off

Report: the op id, the blob commit id, the final `jj log -r 'trunk()..@'`,
the check output, and any remainder. Then suggest `/jj-stack-push <topic>`.

## Anti-pattern clinic (old reflexes that break here)

- **`jj new -B <rev>` to peel a hunk off a commit.** Looks elegant, conflicts
  the moment your intermediate hunk is a prefix of the final one (both sides
  insert at the same spot with different text). Replay forward instead.
- **`jj edit` into the middle of the stack to fix something.** That is the
  git reflex. Fix on top of the stack and `jj absorb` (see /jj-stack-sync).
- **`git add -p`, `git rebase -i`, `git stash`.** None exist here and a
  git-side commit in a colocated repo diverges from jj's view.
- **Splitting by file because it is easy.** A rename that touches 40 callers
  is one refactor revision spanning 40 files, not 40 revisions.
- **`jj squash` everything back "to simplify".** That recreates the blob.
- **Inventing a third version of a line** in a partial step and then
  forgetting to bring it to the blob's version in a later step. The tree
  invariant catches it; the fix is another `jj restore --from "$BLOB"`.
- **Rewriting a revision that is not `mine()`.** The stack may sit on
  someone else's branch. The check flags it; stop at the flag.
- **Pushing before the check passes.** Size gates only work if they gate.

## Cheat sheet

| Need | Command |
|---|---|
| stack | `jj log -r 'trunk()..@'` |
| sizes | `jj log -r 'trunk()..@' -T 'change_id.short() ++ " " ++ diff.stat().total_added() ++ "+/" ++ diff.stat().total_removed() ++ "- " ++ description.first_line() ++ "\n"'` |
| whole files into a step | `jj restore --from <blob> <paths>` |
| file between revisions | `jj squash --from <a> --into <b> -u <paths>` |
| split by fileset | `jj split -r <rev> -m "<selected title>" <fileset>` |
| reorder | `jj rebase -r <rev> -A <other>` / `-B <other>` |
| remainder onto top | `jj rebase -r <blob> -o @ --skip-emptied` |
| prove nothing changed | `jj-stack-check --against <blob commit id>` |
| prove every revision builds | `jj-stack-check -x '<build + test>'` |
| what did absorb/split do | `jj op show -p` |
