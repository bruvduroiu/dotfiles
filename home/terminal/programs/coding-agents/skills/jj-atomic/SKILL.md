---
name: jj-atomic
description: Make every jj revision you produce atomic (one reason to exist), bisectable (builds and passes tests on its own, so `jj bisect run` never has to skip it) and revertable alone. Commit-as-you-go with `jj describe` + `jj new` at each seam, and groom your own unpushed revisions (split, absorb, squash --into) when a seam was missed. Use whenever you write code in a jj repo that will span more than one logical change, before handing work back, or when hunting a regression with `jj bisect run`.
metadata:
  origin: local
---

# jj-atomic — revisions that bisect, revert and review cleanly

## The mental model

Three properties, one test each:

| Property | Means | The test |
|---|---|---|
| **Atomic** | One reason to exist. Title fits one line with no "and". | Can you revert it without wanting to keep half? |
| **Bisectable** | Builds and its tests pass, with only its ancestors under it. | `jj bisect run` gets a real good/bad here, never a 125 skip. |
| **Revertable** | `jj revert -r <it>` alone leaves a working tree. | No later revision silently depends on a *half* of it. |

Bisect is a binary search that trusts every point it lands on. One broken
revision in the middle forces a skip, and a run of them leaves bisect
saying "somewhere in these 12". The cost of a non-atomic history is paid
months later, by whoever hunts the regression.

**In jj, commit-as-you-go is append-only.** At each seam you describe `@`
and start a fresh child:

```bash
<verify: build + tests for what this revision claims>
jj describe -m "<type>: <imperative title>" -m "<why>"
jj new
```

`jj describe` names your own working copy and `jj new` stacks an empty one
on top. Cutting seams going forward is the cheap path, but not the only one:
your local, unpushed revisions are yours to groom. When a seam was missed or
a fix belongs further down, rewrite instead of piling on:

| Situation | Command |
|---|---|
| `@` (or `<rev>`) mixes two changes | `jj split -r <rev> <paths>` |
| Fix in `@` belongs to the revision that last touched those lines | `jj absorb` |
| Fix belongs to a specific revision | `jj squash --into <owner> <paths>` |
| Revision in the wrong order | `jj rebase -r <rev> -A <other>` / `-B <other>` |
| Message is wrong or vague | `jj describe -r <rev> -m …` |

Bounds: only `trunk()..@ & mine() & ~immutable()`, named by revset, never
`jj edit`. Not another author's revisions, not anything pushed, not a
revision another workspace's `@` builds on while that agent runs.
`jj abandon`, `jj undo`, `jj op restore` and `jj git push` stay
human-only. Before the first rewrite, print the undo point:

```bash
jj op log --limit 1 --no-graph -T 'id.short() ++ "\n"'   # human's undo: jj op restore <id>
```

Every rewrite rebases the descendants, so a rewritten stack is unverified
until `jj-stack-check -x` passes over it again.

## Where the seams are

Cut a new revision **before** you start the next thing on this list, not
after you notice the mix:

1. **Mechanical vs semantic.** A rename, move, reformat, or regenerated
   file never shares a revision with a behaviour change. Mechanical first.
2. **Preparatory refactor vs feature.** "Make the change easy, then make
   the easy change." The refactor is its own green revision.
3. **Dependency / lockfile bump vs code that uses it.** The bump lands
   alone (and green); `flake.lock`, `uv.lock`, `go.sum` churn never hides
   inside a feature.
4. **Interface change, in three steps** (expand → migrate → contract): add
   the new function or option beside the old, move callers over, then
   delete the old. Every step builds. A signature change whose callers
   arrive "next revision" is a broken revision.
5. **A bug fix vs the feature you found it in.** The fix is its own
   revision, *below* the feature, so it can be cherry-picked or reverted
   independently.
6. **Unrelated drive-by fixes.** A typo in a file you happened to open goes
   into its own revision or is left alone, never folded in.

What does *not* get its own revision:

- **The test for a behaviour change.** It travels with the change. A test
  that fails until the next revision makes that revision the one bisect
  blames. (A test that pins *existing* behaviour may go first; it passes.)
- **Follow-up fixes to your own unpushed revision.** "Fix typo in previous
  commit" is not history, it is noise. Make the fix, then `jj absorb` or
  `jj squash --into <owner>` it.
- **Debug prints, scratch files, `TODO: remove`.** These never land.

## Verify at each seam, not at the end

Bisectability is only real if every revision was built, not just the tip.
Run the project's build + test command before each `jj describe`:
`nix flake check`, `go test ./...`, `cargo test`, or the repo's `tests` recipe
(see the `nix-app` skill). If the build is slow, run the narrowest check
that proves the revision's claim, then prove all of them at hand-off:

```bash
jj-stack-check -r '<first>::@-' -x '<build + test>'
```

That exports each revision's tree read-only from the git store and runs the
command there, so it touches no workspace and never moves `@`. It flags
`BROKEN` and `UNTESTABLE` (exit 125) rows, plus the usual size, empty,
no-description and conflict checks. It asks permission because it runs
shell, so say what it will run.

## Messages

Match the repo's existing style first (`jj log -r 'trunk()' -n 10`). Where
the repo uses conventional prefixes (`fix:`, `feat:`, `chore:`,
`refactor:`, `test:`, `docs:`, `revert:`), use them. Otherwise:

- **Title**: imperative, ≤ 72 chars, says *what* at the level a changelog
  would. "Add retry to the sync client", not "changes" or "wip".
- **Body**: *why* the change exists and what the reader can't see in the
  diff, such as the constraint, the bug's symptom, or the alternative rejected.
- **Mechanical revisions name their reproducer**: `chore: nix fmt` with
  body "Generated by `nix fmt`; no manual edits." A reviewer can then
  re-run it instead of reading 800 lines.
- Trailers per the session's attribution instructions.

## Hunting a regression: `jj bisect run`

```bash
jj bisect run --range '<good>..<bad>' -- bash -c '<build + test that fails on the bug>'
```

Exit 0 = good, 125 = skip (untestable), anything else = bad. **It moves
`@` in the current workspace** to each candidate, so never run it in a
workspace holding uncommitted or in-progress work. Ask the human for a
dedicated workspace (`jj workspace add`, see the parallel-agents rules).
Every skip it reports is a revision that violated this skill.

## Hand-off

Report the revisions you made, bottom-up, with each one's title and the
verification you ran on it:

```bash
jj log -r '<first>::@-' -T 'change_id.short() ++ " " ++ description.first_line() ++ "\n"'
```

If one revision ended up mixed (you noticed the seam late), split it
before hand-off; for a large blob follow the `/jj-stack` procedure. Report
the op id you printed before grooming, so the human can roll it all back.

## Anti-pattern clinic

| Old reflex | Why it breaks here | Instead |
|---|---|---|
| One big `@` for the whole task, "the human will split it" | Splitting after the fact is expensive and guesswork; only you know the seams | `jj describe` + `jj new` at each seam |
| `nix fmt` / formatter run in the same revision as logic | Real change hidden in whitespace; blame and bisect point at the wrong line | Formatter output = its own `chore` revision, title names the command |
| Failing test first ("TDD commit"), fix next | Bisect lands on the test revision and calls it the culprit | Test and fix in one revision |
| Change a signature, fix callers next revision | The revision in between does not build, so bisect has to skip it | expand → migrate → contract |
| `fix: typo from previous commit` | Unrevertable pair; history noise | `jj absorb` / `jj squash --into <owner>` |
| Lockfile bump inside a feature | A dependency change hidden by a feature; can't revert one without the other | Bump alone, green, first |
| Only building the tip | Middle revisions untested, so bisectability is unproven | `jj-stack-check -x` over your range |
| Leaving a mixed revision for the human to split | You know the seams, they would be guessing | `jj split` it yourself, then re-run `jj-stack-check -x` |
| Grooming a pushed or other-author revision | Rewrites what others already fetched or own | Only `trunk()..@ & mine() & ~immutable()`, unpushed |
| `jj bisect run` in your working workspace | Moves `@`; work in progress gets parked on an old revision | Dedicated workspace |
