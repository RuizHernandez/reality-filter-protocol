#!/bin/sh
# Builds a disposable copy of a target repo with the v1.3.0 technical controls
# installed as real git hooks, ready for a live DevSwarm/Cursor session to be
# pointed at it instead of the production workspace.
#
# Usage: setup-isolated-repo.sh <source-repo> <dest-dir>
set -eu

SRC="${1:?usage: setup-isolated-repo.sh <source-repo> <dest-dir>}"
DEST="${2:?usage: setup-isolated-repo.sh <source-repo> <dest-dir>}"
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
VALIDATION_DIR="$(cd "$SELF_DIR/.." && pwd)"

if [ -d "$DEST" ]; then
  echo "refusing to overwrite existing $DEST" >&2
  exit 1
fi

git clone --no-hardlinks "$SRC" "$DEST"
cd "$DEST"

install -m 0755 "$VALIDATION_DIR/hooks/pre-commit-spec-immutability.sh" .git/hooks/pre-commit-spec-immutability.sh
install -m 0755 "$VALIDATION_DIR/hooks/pre-commit-technical-hold.sh" .git/hooks/pre-commit-hold
install -m 0755 "$VALIDATION_DIR/hooks/pre-commit-phase-branch-gate.sh" .git/hooks/commit-msg

cat > .git/hooks/pre-commit <<'WRAP'
#!/bin/sh
here="$(dirname "$0")"
"$here/pre-commit-spec-immutability.sh" || exit 1
"$here/pre-commit-hold" || exit 1
exit 0
WRAP
chmod +x .git/hooks/pre-commit

echo "Isolated repo ready at $DEST"
echo "Hooks installed: pre-commit (spec-immutability + technical-HOLD), commit-msg (phase/branch gate)."
echo "Point Cursor/DevSwarm at this directory, NOT the production workspace."
echo "Reminder: AGENT_ROLE must come from your orchestration harness's role assignment for each"
echo "agent's commits (export AGENT_ROLE=coder|architect|orchestrator|explorer before that agent"
echo "commits) -- these hooks trust that value; they do not attest it. See ../REPORT.md Limitations."
