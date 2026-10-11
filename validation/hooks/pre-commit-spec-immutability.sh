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

# Git for Windows treats a hook killed by a signal as success. If whoever
# reads stderr closes the pipe, the first message would SIGPIPE this script
# and the commit would go through. Ignore SIGPIPE so the exit code decides.
trap '' PIPE

# --no-renames: with rename detection on (git's default), moving a spec out of
# its protected path lists only the NEW path, and the move passed unchecked.
# -z + newline: one path per line even when the path contains spaces, which
# the old word-split `for f in $staged` cut into fragments no glob matched.
# Through a file, not a pipe: piped into tr, a failing `git diff` would read
# as "nothing staged" and the hook would allow.
list=$(mktemp "${TMPDIR:-/tmp}/rfp-spec-XXXXXX") || exit 1
trap 'rm -f "$list"' EXIT INT TERM
if ! git diff --cached --name-only --no-renames -z > "$list"; then
  echo "REJECTED [spec-immutability PROTOCOL.md §3.2]: could not list staged paths -- fail closed (§4.1)." >&2
  exit 1
fi
staged=$(tr '\0' '\n' < "$list")

# set -f: the globs below are case patterns, not filenames. Left unquoted with
# globbing on, the shell expanded each one against the worktree first; with a
# second spec on disk, `docs/ux/*impl-notes*.md` became that file's literal
# name, and deleting or renaming a DIFFERENT spec matched nothing.
set -f
touches_spec=0
touched_files=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  for pat in $PROTECTED_SPEC_GLOBS; do
    case "$f" in
      $pat)
        touches_spec=1
        touched_files="$touched_files '$f'"
        ;;
    esac
  done
done <<STAGED
$staged
STAGED

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
