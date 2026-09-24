#!/usr/bin/env bash
# Runs a full batch on the host with every agent in Docker.
#
#   run-batch-docker.sh single <backend> <n> [first-run]
#   run-batch-docker.sh orch <orch-backend> <worker-backend> <n> [first-run]
#
# Refuses to start unless preregistration.json exists for the same design and
# every backend (and, for orch, the delegation path) passes its smoke gate.
# Cells run in a seeded shuffle so A and B interleave in time instead of
# confounding the condition with API-side drift.
set -uo pipefail
cd "$(dirname "$0")"

DESIGN="${1:-}"; shift || true
case "$DESIGN" in
  single) export AB_AGENT="${1:?backend}"; N="${2:?n}"; FIRST="${3:-1}"; PFILE=prompt.txt; LABEL="$AB_AGENT" ;;
  orch)   export AB_ORCH="${1:?orch backend}" AB_WORKER="${2:?worker backend}"; N="${3:?n}"; FIRST="${4:-1}"; PFILE=orch-prompt.txt; LABEL="$AB_ORCH-$AB_WORKER" ;;
  *) echo "usage: run-batch-docker.sh single <backend> <n> | orch <orch> <worker> <n>" >&2; exit 2 ;;
esac
[ -f preregistration.json ] || { echo "no preregistration.json; preregister and commit first" >&2; exit 2; }
if grep -q '"design": "orch"' preregistration.json; then P=orch; else P=single; fi
[ "$P" = "$DESIGN" ] || { echo "preregistration.json is for design '$P', not '$DESIGN'" >&2; exit 2; }

if [ "$DESIGN" = single ]; then
  ./smoke-docker.sh read "$AB_AGENT" || { echo "backend failed the read gate; batch not started" >&2; exit 1; }
else
  ./smoke-docker.sh read "$AB_WORKER" || { echo "worker backend failed the read gate" >&2; exit 1; }
  ./smoke-docker.sh read "$AB_ORCH" || { echo "orchestrator backend failed the read gate" >&2; exit 1; }
  ./smoke-docker.sh delegate "$AB_ORCH" "$AB_WORKER" || { echo "delegation gate failed" >&2; exit 1; }
fi

TASKS=()
for d in tasks/*/; do [ -f "$d/$PFILE" ] && TASKS+=("$(basename "$d")"); done
SEED="${AB_SEED:-$(date +%s)}"
RUNS_DIR="${AB_RUNS_DIR:-/c/ab-runs}"; mkdir -p "$RUNS_DIR"
PLAN="$RUNS_DIR/batch-$DESIGN-$LABEL-$(date -u +%Y%m%dT%H%M%SZ).plan"
for t in "${TASKS[@]}"; do for c in A B; do
  for ((r = FIRST; r < FIRST + N; r++)); do echo "$t $c $r"; done
done; done | shuf --random-source=<(yes "$SEED") > "$PLAN"
echo "# design: $DESIGN  backends: $LABEL  seed: $SEED" > "$PLAN.meta"

total=$(wc -l < "$PLAN"); i=0
while read -r t c r; do
  i=$((i + 1)); echo "[$i/$total] $t $c run-$r"
  ./runner-docker.sh "$t" "$c" "$r" || echo "  runner error on $t $c $r (kept; reported, not retried)"
done < "$PLAN"
echo "batch done: $PLAN"
