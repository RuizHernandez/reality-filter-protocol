#!/usr/bin/env bash
# Runs a full batch for one backend inside the sandbox:
#   1. loads secrets and the backend definition,
#   2. refuses to start unless the backend passes smoke.sh,
#   3. runs every (task, condition, run) cell in a shuffled order so A and B
#      are interleaved in time -- running all of A then all of B would
#      confound the condition with API-side drift over the batch.
#
# Usage: bash sandbox/run-batch.sh <backend> <n> [first-run-number]
#   backend = a file sandbox/backends/<backend>.env
set -uo pipefail
cd "$(dirname "$0")/.."

BACKEND="${1:-}"; N="${2:-}"; FIRST="${3:-1}"
[ -n "$BACKEND" ] && [ -n "$N" ] || { echo "usage: run-batch.sh <backend> <n> [first-run]" >&2; exit 2; }
BFILE="sandbox/backends/$BACKEND.env"
[ -f "$BFILE" ] || { echo "no backend file $BFILE" >&2; exit 2; }
[ -f preregistration.json ] || { echo "no preregistration.json; preregister and commit first" >&2; exit 2; }

SECRETS="${AB_SECRETS:-/c/secrets/secrets.env}"
[ -f "$SECRETS" ] || { echo "no secrets file at $SECRETS" >&2; exit 2; }
set -a
# shellcheck disable=SC1090
source <(tr -d '\r' < "$SECRETS")
# shellcheck disable=SC1090
source <(tr -d '\r' < "$BFILE")
set +a
[ -n "${AB_AGENT_CMD:-}" ] && [ -n "${AB_MODEL:-}" ] || { echo "$BFILE must set AB_AGENT_CMD and AB_MODEL" >&2; exit 2; }
export AB_WORK_ROOT="${AB_WORK_ROOT:-$HOME/ab-work}"

./smoke.sh || { echo "backend $BACKEND failed the admission gate; batch not started" >&2; exit 1; }

TASKS=()
for d in tasks/*/; do [ -f "$d/prompt.txt" ] && TASKS+=("$(basename "$d")"); done

SEED="${AB_SEED:-$(date +%s)}"
RUNS_DIR="${AB_RUNS_DIR:-runs}"
PLAN="$RUNS_DIR/batch-$BACKEND-$(date -u +%Y%m%dT%H%M%SZ).plan"
mkdir -p "$RUNS_DIR"
for t in "${TASKS[@]}"; do
  for c in A B; do
    for ((r = FIRST; r < FIRST + N; r++)); do echo "$t $c $r"; done
  done
done | shuf --random-source=<(yes "$SEED") > "$PLAN"
{ echo "# backend: $BACKEND  model: $AB_MODEL  seed: $SEED"; } >> "$PLAN.meta"

total=$(wc -l < "$PLAN"); i=0
while read -r t c r; do
  i=$((i + 1))
  echo "[$i/$total] $t $c run-$r"
  AB_AGENT_CMD="$AB_AGENT_CMD" AB_MODEL="$AB_MODEL" ./runner.sh "$t" "$c" "$r" \
    || echo "  runner error on $t $c $r (kept; reported, not retried)"
done < "$PLAN"
echo "batch done: $PLAN"
