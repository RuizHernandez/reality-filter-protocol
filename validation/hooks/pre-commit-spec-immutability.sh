#!/bin/sh
# Implements PROTOCOL.md §3.2 (Specification immutability, coded rule) as a real
# git pre-commit hook, not prose. Rejects a commit that touches a protected spec
# path unless the committing role is an authorized spec author.
#
# Role source (trust boundary): this synthetic harness reads AGENT_ROLE from the
# environment for testability. In a real deployment this must come from an
# attested, non-agent-writable channel (the orchestration harness), not a
# self-set env var -- an adversarial agent can set its own env var. See
# validation/REPORT.md, "Limitations".

PROTECTED_SPEC_GLOBS="docs/ux/*impl-notes*.md docs/ux/*ACCEPTANCE*.md docs/ux/*acceptance*.md"
AUTHORIZED_ROLES="architect orchestrator"

role="${AGENT_ROLE:-unknown}"
staged=$(git diff --cached --name-only)

touches_spec=0
touched_files=""
for f in $staged; do
  for pat in $PROTECTED_SPEC_GLOBS; do
    case "$f" in
      $pat)
        touches_spec=1
        touched_files="$touched_files $f"
        ;;
    esac
  done
done

if [ "$touches_spec" -eq 1 ]; then
  authorized=0
  for r in $AUTHORIZED_ROLES; do
    [ "$role" = "$r" ] && authorized=1
  done
  if [ "$authorized" -ne 1 ]; then
    echo "REJECTED [spec-immutability PROTOCOL.md §3.2]: role '$role' is not an authorized spec author (allowed: $AUTHORIZED_ROLES)." >&2
    echo "Protected paths in this commit:$touched_files" >&2
    exit 1
  fi
fi

exit 0
