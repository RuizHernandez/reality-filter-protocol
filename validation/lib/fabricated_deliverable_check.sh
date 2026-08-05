#!/bin/sh
# Implements PROTOCOL.md §3.8 (Fabricated deliverable detection).
# A file is a valid agent deliverable only if it traces to a commit reachable
# from that agent's claimed branch/worktree. A loose untracked file, or one
# only present on an unrelated branch, is not evidence.
#
# Usage: fabricated_deliverable_check.sh <path> <claimed-branch>
set -e

path="$1"
branch="$2"

if [ -z "$path" ] || [ -z "$branch" ]; then
  echo "usage: fabricated_deliverable_check.sh <path> <claimed-branch>" >&2
  exit 2
fi

if ! git rev-parse --verify "$branch" >/dev/null 2>&1; then
  echo "FABRICATED [§3.8]: claimed branch '$branch' does not exist."
  exit 1
fi

if git log --oneline "$branch" -- "$path" 2>/dev/null | grep -q .; then
  echo "OK [§3.8]: $path traces to a commit reachable from '$branch'."
  exit 0
fi

if [ -f "$path" ]; then
  echo "FABRICATED [§3.8]: $path exists in the worktree but is not committed on '$branch' -- loose file, not a deliverable."
else
  echo "FABRICATED [§3.8]: $path is not committed on '$branch' and not present in the worktree."
fi
exit 1
