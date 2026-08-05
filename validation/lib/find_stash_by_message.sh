#!/bin/sh
# Implements PROTOCOL.md §3.3 (Stash identifier stability). stash@{n} is not a
# stable identifier across worktrees or time; locate by message content.
#
# Usage: find_stash_by_message.sh "<substring>"
set -e
substr="$1"
if [ -z "$substr" ]; then
  echo "usage: find_stash_by_message.sh <message-substring>" >&2
  exit 2
fi
match=$(git stash list | grep -F "$substr" || true)
count=$(printf '%s\n' "$match" | grep -c . || true)

if [ "$count" -eq 0 ]; then
  echo "NOT FOUND: no stash message contains '$substr'."
  exit 1
elif [ "$count" -gt 1 ]; then
  echo "AMBIGUOUS: $count stashes match '$substr' -- message not unique enough:"
  echo "$match"
  exit 1
else
  echo "$match" | cut -d: -f1
  exit 0
fi
