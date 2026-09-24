#!/usr/bin/env bash
# Orchestration batch inside the sandbox: <orch-backend> orchestrates
# <worker-backend>. Each backend passes its own smoke gate, then the pair
# passes the delegation gate, then every cell runs in a seeded shuffle.
#
# Usage: bash sandbox/run-orch-batch.sh <orch-backend> <worker-backend> <n> [first-run]
#   e.g. bash sandbox/run-orch-batch.sh gemini deepseek 10
set -uo pipefail
cd "$(dirname "$0")/.."

OB="${1:-}"; WB="${2:-}"; N="${3:-}"; FIRST="${4:-1}"
[ -n "$OB" ] && [ -n "$WB" ] && [ -n "$N" ] || { echo "usage: run-orch-batch.sh <orch> <worker> <n> [first-run]" >&2; exit 2; }
for b in "$OB" "$WB"; do [ -f "sandbox/backends/$b.env" ] || { echo "no backend sandbox/backends/$b.env" >&2; exit 2; }; done
[ -f preregistration.json ] && grep -q '"design": "orch"' preregistration.json || { echo "need an orchestration preregistration.json (AB_DESIGN=orch ./preregister.sh ...)" >&2; exit 2; }

SECRETS="${AB_SECRETS:-/c/secrets/secrets.env}"
[ -f "$SECRETS" ] || { echo "no secrets file at $SECRETS" >&2; exit 2; }
load() { set -a; source <(tr -d '\r' < "$SECRETS"); source <(tr -d '\r' < "sandbox/backends/$1.env"); set +a; }
export AB_WORK_ROOT="${AB_WORK_ROOT:-$HOME/ab-work}"

# Each backend alone must read files (smoke.sh), in a clean subshell.
( load "$WB"; ./smoke.sh ) || { echo "worker backend $WB failed smoke; batch not started" >&2; exit 1; }
( load "$OB"; ./smoke.sh ) || { echo "orchestrator backend $OB failed smoke; batch not started" >&2; exit 1; }

# Resolve worker command/model in a subshell, then load the orchestrator.
eval "$(load "$WB"; printf 'export AB_WORKER_CMD=%q AB_WORKER_MODEL=%q\n' "$AB_AGENT_CMD" "$AB_MODEL")"
export AB_WORKER_ENV="$SECRETS $(pwd -P)/sandbox/backends/$WB.env"
load "$OB"
export AB_ORCH_CMD="$AB_AGENT_CMD" AB_ORCH_MODEL="$AB_MODEL"
unset AB_AGENT_CMD AB_MODEL

./smoke-orch.sh || { echo "delegation gate failed; batch not started" >&2; exit 1; }

TASKS=()
for d in tasks/*/; do [ -f "$d/orch-prompt.txt" ] && TASKS+=("$(basename "$d")"); done
SEED="${AB_SEED:-$(date +%s)}"
RUNS_DIR="${AB_RUNS_DIR:-runs}"
PLAN="$RUNS_DIR/batch-orch-$OB-$WB-$(date -u +%Y%m%dT%H%M%SZ).plan"
mkdir -p "$RUNS_DIR"
for t in "${TASKS[@]}"; do for c in A B; do
  for ((r = FIRST; r < FIRST + N; r++)); do echo "$t $c $r"; done
done; done | shuf --random-source=<(yes "$SEED") > "$PLAN"
echo "# orch: $AB_ORCH_MODEL  worker: $AB_WORKER_MODEL  seed: $SEED" > "$PLAN.meta"

total=$(wc -l < "$PLAN"); i=0
while read -r t c r; do
  i=$((i + 1)); echo "[$i/$total] $t $c run-$r"
  ./runner-orch.sh "$t" "$c" "$r" || echo "  runner error on $t $c $r (kept; reported, not retried)"
done < "$PLAN"
echo "batch done: $PLAN"
