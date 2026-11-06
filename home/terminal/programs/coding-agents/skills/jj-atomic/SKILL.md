---
name: jj-atomic
description: Make every jj revision you produce atomic (one independently meaningful outcome, with its implementation, supporting refactors, tests and docs), bisectable (builds and passes tests on its own, so `jj bisect run` never has to skip it) and revertable alone. Commit-as-you-go with `jj describe` + `jj new` at each seam, and groom your own unpushed revisions (split, absorb, squash --into) when a seam was missed. Use whenever you write code in a jj repo that will span more than one logical change, before handing work back, or when hunting a regression with `jj bisect run`.
metadata:
  origin: local
---

# jj-atomic — revisions that bisect, revert and review cleanly

## The mental model

> Prefer one revision per independently meaningful issue or outcome. Combine
> implementation, supporting refactors, tests, documentation, and corrections
> that belong to that outcome. Split unrelated issues, not implementation
> stages. Revision size is a review signal, not a hard limit. Every revision
> must build and pass its relevant checks.

Three properties, one test each:

| Property | Means | The test |
|---|---|---|
| **Atomic** | One outcome, complete: the change plus everything that exists only to serve it. Title fits one line with no "and". | Can you revert it without wanting to keep half, and without leaving orphaned helpers behind? |
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
| `@` (or `<rev>`) mixes two outcomes | `jj split -r <rev> <paths>` |
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

A seam sits between **outcomes**, not between steps of building one. Ask
"would someone want this revision without the other one?" If yes, they are
two revisions. If one only exists to serve the other, they are one.

Cut a new revision before you start a different outcome:

1. **A bug fix vs the feature you found it in.** The fix is its own outcome:
   its own revision, *below* the feature, so it can be cherry-picked or
   reverted independently.
2. **Unrelated drive-by fixes.** A typo in a file you happened to open goes
   into its own revision or is left alone, never folded in.
3. **Repo-wide mechanical churn.** A formatter run over the whole tree, a
   mass rename or a regenerated file nobody asked for is its own outcome.
   Name the reproducer in the message.
4. **A broad dependency update.** `nix flake update` or a general
   `uv lock --upgrade` changes many things at once and lands alone, green.
   An input added or pinned *only* for this feature travels with it.

What stays **in** the outcome's revision:

- **Supporting refactors.** Extracting a helper or reshaping a function so
  the feature fits is part of the feature. Reverting the feature should take
  the scaffolding with it.
- **Every stage of an interface change.** Adding the new API, moving the
  callers and deleting the old one are one outcome. Split into
  expand → migrate → contract only when the size or risk of the whole calls
  for it (see below), and then each step must build on its own.
- **The test for a behaviour change.** A test that fails until the next
  revision makes that revision the one bisect blames. (A test that pins
  *existing* behaviour may go first; it passes.)
- **Documentation** of the behaviour the revision introduces.
- **Corrections to your own unpushed revision.** "Fix typo in previous
  commit" is not history, it is noise. Make the fix, then `jj absorb` or
  `jj squash --into <owner>` it.

What never lands: debug prints, scratch files, `TODO: remove`.

### Size is a signal, not a limit

A large revision is a prompt to ask whether it holds more than one outcome.
It is not an order to split. If it really is one outcome, keep it whole and
help the reviewer through the message body (what moved, what changed, where
to start reading). Split an oversized single outcome along **its** structure
(expand → migrate → contract, or one subsystem per revision) only when every
piece builds and passes on its own and each one reads as a step toward the
outcome. Never split into a half that would not be kept alone.

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

If one revision ended up holding two outcomes (you noticed the seam late),
split it before hand-off; for a large blob of several outcomes follow the
`/jj-stack` procedure. Report
the op id you printed before grooming, so the human can roll it all back.

## Anti-pattern clinic

| Old reflex | Why it breaks here | Instead |
|---|---|---|
| One big `@` for the whole task, "the human will split it" | Unrelated outcomes tangled; only you know where they separate | `jj describe` + `jj new` when you start a different outcome |
| A revision per implementation step (refactor, then feature, then tests, then docs) | Half-outcomes that nobody would keep alone; reverting the feature leaves orphaned scaffolding | One revision per outcome, with its refactors, tests and docs |
| Splitting because the diff passed some line count | Size is a review signal; a forced split produces halves that only make sense together | Check for a second outcome; if there is none, keep it whole and explain it in the body |
| Repo-wide `nix fmt` in the same revision as logic | Real change hidden in whitespace; blame and bisect point at the wrong line | Formatter output = its own `chore` revision, title names the command |
| Failing test first ("TDD commit"), fix next | Bisect lands on the test revision and calls it the culprit | Test and fix in one revision |
| Change a signature, fix callers next revision | The revision in between does not build, so bisect has to skip it | Same revision; or expand → migrate → contract where each step builds |
| `fix: typo from previous commit` | Unrevertable pair; history noise | `jj absorb` / `jj squash --into <owner>` |
| Broad lockfile update inside a feature | Unrelated dependency changes hidden by a feature; can't revert one without the other | Broad update alone, green, first; a feature-only pin travels with the feature |
| Bug fix folded into the feature that exposed it | Can't cherry-pick or revert the fix independently | Fix in its own revision, below the feature |
| Only building the tip | Middle revisions untested, so bisectability is unproven | `jj-stack-check -x` over your range |
| Leaving a mixed revision for the human to split | You know the outcomes, they would be guessing | `jj split` it yourself, then re-run `jj-stack-check -x` |
| Grooming a pushed or other-author revision | Rewrites what others already fetched or own | Only `trunk()..@ & mine() & ~immutable()`, unpushed |
| `jj bisect run` in your working workspace | Moves `@`; work in progress gets parked on an old revision | Dedicated workspace |
