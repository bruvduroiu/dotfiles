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
repo_args=()

usage() {
  cat <<'EOF'
usage: jj-stack-check [-r REVSET] [-l LIMIT] [--against COMMIT] [-R REPO]
  -r REVSET        stack to check              (default: trunk()..@ ~ (@ & empty()))
  -l LIMIT         max changed lines per rev   (default: 400)
  --against COMMIT verify heads(REVSET) has the same tree as COMMIT
  -R REPO          repository path (passed to jj)
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -r) revset=$2; shift 2 ;;
    -l) limit=$2; shift 2 ;;
    --against) against=$2; shift 2 ;;
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
tmpl="change_id.short(8) ++ \"$us\" ++ commit_id.short(12) ++ \"$us\" ++ diff.stat().total_added() ++ \"$us\" ++ diff.stat().total_removed() ++ \"$us\" ++ if(empty, \"1\", \"0\") ++ \"$us\" ++ if(conflict, \"1\", \"0\") ++ \"$us\" ++ description.first_line() ++ \"\n\""

# --reversed: bottom of the stack first, the order a reviewer reads it in.
rows=$(jj log -r "$revset" --no-graph --reversed -T "$tmpl")
# mine() is a revset function, not a template one, so ask for the complement
# separately: revisions in the stack that you did not author.
not_mine=$(jj log -r "($revset) ~ mine()" --no-graph -T 'change_id.short(8) ++ "\n"')

if [ -z "$rows" ]; then
  echo "jj-stack-check: revset '$revset' is empty — nothing to check"
  exit 0
fi

fail=0
count=0
total=0
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
  [ ${#flags[@]} -gt 0 ] && fail=1
  printf '%-9s %-13s %+5d/-%-4d  %-28s %s\n' \
    "$change" "$commit" "$added" "$removed" "${flags[*]:-ok}" "${desc:-(no description)}"
done <<<"$rows"

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
