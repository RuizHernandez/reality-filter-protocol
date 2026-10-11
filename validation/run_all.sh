#!/usr/bin/env bash
# Runs every suite and document check and ties each result to the conditions
# it was obtained under: commit, dirty state, OS, tool versions, date, wall
# time. A "13/13" without those is a claim about some environment, not
# necessarily this one -- on a Windows checkout with a long path the same
# replay printed 5 PASS / 8 FAIL with no repository ever created.
#
# Usage: validation/run_all.sh [scratch-dir]
# Exit:  0 = every step exited 0;  1 = some step failed
set -u
cd "$(dirname "$0")/.."
SCRATCH="${1:-$(mktemp -d "${TMPDIR:-/tmp}/rfp-all-XXXXXX")}"
mkdir -p "$SCRATCH" || exit 2

ver() { command -v "$1" >/dev/null 2>&1 || { echo absent; return; }; "$@" 2>/dev/null | head -1 | tr -d '\r'; }
echo "== Environment =="
echo "date_utc:   $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "commit:     $(git rev-parse HEAD 2>/dev/null || echo none)"
echo "branch:     $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo none)"
echo "dirty:      $(git status --porcelain 2>/dev/null | grep -c . | tr -d ' ') path(s) differ from HEAD"
echo "os:         $(uname -srm 2>/dev/null)"
echo "bash:       $(ver bash --version)"
echo "git:        $(ver git --version)"
echo "jq:         $(command -v jq >/dev/null 2>&1 && ver jq --version || echo absent)"
echo "curl:       $(ver curl --version)"
echo "scratch:    $SCRATCH"
echo

status=0
step() {
  # step <name> <command...>
  local name="$1"; shift
  local log="$SCRATCH/$name.log" t0 t1 rc=0
  t0=$(date +%s)
  "$@" > "$log" 2>&1 || rc=$?
  t1=$(date +%s)
  local summary
  summary=$(grep -E '^PASS=[0-9]+ FAIL=[0-9]+|passed|FAILED|ENVIRONMENT ERROR' "$log" | tail -1 | tr -d '\r')
  printf 'STEP | %-22s | exit=%s | seconds=%s | %s\n' "$name" "$rc" "$((t1 - t0))" "$summary"
  [ "$rc" -eq 0 ] || status=1
}

step replay        bash validation/replay_incident.sh "$SCRATCH/replay"
step peer          bash validation/peer_verification_suite.sh "$SCRATCH/peer"
step skill-gates   bash validation/skill_gates_suite.sh "$SCRATCH/gates"
step audit         bash validation/audit_suite.sh "$SCRATCH/audit"
step sync-check    bash scripts/sync-check.sh
step adapter-cov   bash scripts/adapter-coverage.sh
step citations     bash scripts/check-citations.sh
step claim-support bash scripts/check-claim-support.sh
step claims        bash scripts/check-claims.sh

echo
echo "logs: $SCRATCH"
exit "$status"
