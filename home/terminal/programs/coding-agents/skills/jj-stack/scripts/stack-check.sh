#!/usr/bin/env bash
# jj-stack-check — gate a jj stack on reviewability before it is pushed.
#
# For every revision in REVSET (default: the stack under @) print one row:
#   <change id>  <+added/-removed>  <flags>  <description>
# and fail (exit 1) if any revision is
#   TOO-BIG    more than LIMIT changed lines (added + removed)
#   NO-DESC    has no description
#   EMPTY      changes nothing (a leftover from a split/rebase)
#   CONFLICT   carries unresolved conflict markers
#   NOT-MINE   authored by someone else (you are about to rewrite their work)
# With -x CMD, also run CMD against each revision's tree, bottom-up — the
# bisectability gate. Each tree is exported read-only from the git store
# into a throwaway directory (no workspace, no checkout, @ is never moved):
#   BROKEN     CMD exited non-zero
#   UNTESTABLE CMD exited 125 (git/jj bisect's "skip"): a revision bisect
#              cannot judge is as bad as a broken one
# With --against COMMIT, also verify the *tree invariant*: the tip of the
# stack must be byte-for-byte the tree of COMMIT (the blob you carved up).
# Splitting must never change what the code does — only how it is read.
#
# Pure renames cost 0 lines in jj's stat, so moves are not penalised. A move
# that also edits the file counts only the edited lines.
#
# This file is shipped twice on purpose: as ~/.claude/skills/jj-stack/scripts/
# (so the skill can be copied to a colleague as-is and run with `bash`) and
# built by scripts.nix into a `jj-stack-check` binary on PATH. Keep the
# shebang and `set` line for the former; writeShellApplication prepends its
# own for the latter and the duplicates are harmless.
set -euo pipefail

# `@` is usually an empty scratch revision on top of the stack; leave it out
# so it is not reported as EMPTY/NO-DESC. A non-empty `@` is part of the stack.
revset='trunk()..@ ~ (@ & empty())'
limit=400
against=''
exec_cmd=''
repo_args=()

usage() {
  cat <<'EOF'
usage: jj-stack-check [-r REVSET] [-l LIMIT] [--against COMMIT] [-x CMD] [-R REPO]
  -r REVSET        stack to check              (default: trunk()..@ ~ (@ & empty()))
  -l LIMIT         max changed lines per rev   (default: 400)
  --against COMMIT verify heads(REVSET) has the same tree as COMMIT
  -x CMD           run `bash -c CMD` in a clean export of every revision;
                   non-zero fails it (125 = untestable, also fails)
  -R REPO          repository path (passed to jj)
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -r) revset=$2; shift 2 ;;
    -l) limit=$2; shift 2 ;;
    --against) against=$2; shift 2 ;;
    -x | --exec) exec_cmd=$2; shift 2 ;;
    -R) repo_args=(-R "$2"); shift 2 ;;
    -h | --help) usage; exit 0 ;;
    *) echo "jj-stack-check: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$limit" in
  '' | *[!0-9]*) echo "jj-stack-check: -l must be a non-negative integer" >&2; exit 2 ;;
esac

jj() { command jj "${repo_args[@]}" --no-pager --color never "$@"; }

# Unit separator between fields; the description's first line can hold
# anything printable, so a tab or pipe would be ambiguous.
us=$'\x1f'
tmpl="change_id.short(8) ++ \"$us\" ++ commit_id ++ \"$us\" ++ diff.stat().total_added() ++ \"$us\" ++ diff.stat().total_removed() ++ \"$us\" ++ if(empty, \"1\", \"0\") ++ \"$us\" ++ if(conflict, \"1\", \"0\") ++ \"$us\" ++ description.first_line() ++ \"\n\""

# --reversed: bottom of the stack first, the order a reviewer reads it in.
rows=$(jj log -r "$revset" --no-graph --reversed -T "$tmpl")
# mine() is a revset function, not a template one, so ask for the complement
# separately: revisions in the stack that you did not author.
not_mine=$(jj log -r "($revset) ~ mine()" --no-graph -T 'change_id.short(8) ++ "\n"')

if [ -z "$rows" ]; then
  echo "jj-stack-check: revset '$revset' is empty — nothing to check"
  exit 0
fi

# -x: every revision's tree comes out of the backing git store (the
# colocated .git, or .jj/repo/store/git) via `git archive`, which only reads.
# The export is what CI would see: tracked files only, no build leftovers,
# no ignored files, no .git/.jj. Commands that need VCS metadata (version
# from `git describe`, a flake that wants `self.rev`) must cope without it.
if [ -n "$exec_cmd" ]; then
  git_dir=$(jj git root)
  scratch=$(mktemp -d "${TMPDIR:-/tmp}/jj-stack-check.XXXXXX")
  trap 'chmod -R u+w "$scratch" 2>/dev/null; rm -rf "$scratch"' EXIT
fi

# run_at COMMIT → exit status of exec_cmd against that commit's tree; the
# log stays in $scratch/<commit>.log so a failure can be shown.
run_at() {
  local dir="$scratch/$1" log="$scratch/$1.log"
  mkdir -p "$dir"
  if ! git --git-dir="$git_dir" archive --format=tar "$1" | tar -x -C "$dir"; then
    echo "jj-stack-check: could not export $1 from $git_dir" >"$log"
    return 1
  fi
  # </dev/null: the caller is a `while read` loop over the stack; a CMD that
  # reads stdin would otherwise eat the remaining rows.
  (cd "$dir" && JJ_STACK_REV=$1 bash -c "$exec_cmd") </dev/null >"$log" 2>&1
}

fail=0
count=0
total=0
broken_logs=()
printf '%-9s %-13s %10s  %-28s %s\n' CHANGE COMMIT LINES FLAGS DESCRIPTION
while IFS="$us" read -r change commit added removed empty conflict desc; do
  count=$((count + 1))
  lines=$((added + removed))
  total=$((total + lines))
  flags=()
  [ "$lines" -gt "$limit" ] && flags+=(TOO-BIG)
  [ -z "$desc" ] && flags+=(NO-DESC)
  [ "$empty" = 1 ] && flags+=(EMPTY)
  [ "$conflict" = 1 ] && flags+=(CONFLICT)
  grep -qx "$change" <<<"$not_mine" && flags+=(NOT-MINE)
  if [ -n "$exec_cmd" ]; then
    status=0
    run_at "$commit" || status=$?
    case "$status" in
      0) ;;
      125) flags+=(UNTESTABLE) ;;
      *) flags+=(BROKEN) ;;
    esac
    if [ "$status" -ne 0 ]; then broken_logs+=("$commit"); fi
  fi
  [ ${#flags[@]} -gt 0 ] && fail=1
  printf '%-9s %-13s %+5d/-%-4d  %-28s %s\n' \
    "$change" "${commit:0:12}" "$added" "$removed" "${flags[*]:-ok}" "${desc:-(no description)}"
done <<<"$rows"

# A failing revision's output tail, so the fix does not need a re-run.
for commit in "${broken_logs[@]}"; do
  printf '\n--- %s: last 20 lines of "%s" ---\n' "${commit:0:12}" "$exec_cmd"
  tail -n 20 "$scratch/$commit.log"
done

printf '\n%d revision(s), %d changed lines total, limit %d per revision\n' \
  "$count" "$total" "$limit"

if [ -n "$against" ]; then
  # Multiple heads (a -p split, siblings) means "the tip" is ambiguous; the
  # invariant only makes sense for a linear stack.
  heads=$(jj log -r "heads($revset)" --no-graph -T 'commit_id ++ "\n"')
  if [ "$(printf '%s\n' "$heads" | grep -c .)" -ne 1 ]; then
    echo "tree invariant: SKIPPED — heads($revset) is not a single revision"
  else
    drift=$(jj diff --from "$against" --to "$heads" --summary)
    if [ -z "$drift" ]; then
      echo "tree invariant: OK — heads($revset) has the same tree as $against"
    else
      fail=1
      echo "tree invariant: FAILED — heads($revset) differs from $against:"
      printf '%s\n' "$drift" | sed 's/^/  /'
    fi
  fi
fi

if [ "$fail" -ne 0 ]; then
  echo "jj-stack-check: FAIL — fix the flagged revisions before pushing" >&2
  exit 1
fi
echo "jj-stack-check: OK"
