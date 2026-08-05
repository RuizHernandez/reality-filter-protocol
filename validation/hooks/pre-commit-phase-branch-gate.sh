#!/bin/sh
# Models the "fifth compounding failure" from PROTOCOL.md (branch-mismatch /
# stash evidence, DevSwarm P2 incident): P2 work landed uncommitted on a P1
# branch. This hook requires the commit message to declare a `Phase: P<N>`
# trailer that matches the current branch's `p<N>` token, so phase/branch
# drift is rejected at commit time instead of discovered later via stash
# archaeology.

branch=$(git rev-parse --abbrev-ref HEAD)
branch_phase=$(echo "$branch" | grep -oE 'p[0-9]+' | head -1)

msg_file="$1"
msg=$(cat "$msg_file" 2>/dev/null)
msg_phase=$(echo "$msg" | grep -oE 'Phase: *P[0-9]+' | grep -oE '[0-9]+' | head -1)

if [ -z "$branch_phase" ] || [ -z "$msg_phase" ]; then
  # Branch or commit doesn't participate in the phase-tagging convention; not
  # this hook's concern (e.g. docs-only or infra branches).
  exit 0
fi

branch_num=$(echo "$branch_phase" | grep -oE '[0-9]+')

if [ "$branch_num" != "$msg_phase" ]; then
  echo "REJECTED [phase-branch-gate, incident-derived]: commit declares Phase: P$msg_phase but branch '$branch' is tagged p$branch_num." >&2
  echo "This is the exact shape of the DevSwarm P2 branch-mismatch failure (P2 WIP on a P1 branch)." >&2
  exit 1
fi

exit 0
