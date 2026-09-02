#!/usr/bin/env bash
# Writes preregistration.json: the frozen declaration of what the A/B study
# will run and what result it will accept, BEFORE any run happens.
# PROTOCOL-AB.md explains why this is a hashed file and not prose.
#
# Usage: preregister.sh <n-per-condition-per-task> <model-identifier> [task ...]
set -euo pipefail
cd "$(dirname "$0")"

N="${1:-}"; MODEL="${2:-}"; shift 2 || true
TASKS=("$@")
[ -n "$N" ] && [ -n "$MODEL" ] || { echo "usage: preregister.sh <n> <model> [task ...]" >&2; exit 2; }
[ -f preregistration.json ] && { echo "preregistration.json already exists -- it is frozen; editing it means a new study" >&2; exit 1; }
if [ ${#TASKS[@]} -eq 0 ]; then
  TASKS=()
  for f in tasks/*.md; do TASKS+=("$(basename "$f" .md)"); done
fi

proto_hash=$(sha256sum ../../PROTOCOL.md | cut -d' ' -f1)
task_json=""
for t in "${TASKS[@]}"; do
  [ -f "tasks/$t.md" ] || { echo "no such task: tasks/$t.md" >&2; exit 2; }
  h=$(sha256sum "tasks/$t.md" | cut -d' ' -f1)
  task_json+="    { \"id\": \"$t\", \"sha256\": \"$h\" },
"
done
task_json="${task_json%,
}"

{
  echo "{"
  echo "  \"date\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
  echo "  \"n_per_condition_per_task\": $N,"
  echo "  \"model\": \"$MODEL\","
  echo "  \"protocol_sha256\": \"$proto_hash\","
  echo "  \"tasks\": ["
  printf '%b
' "$task_json"
  echo "  ],"
  echo "  \"decision_criteria\": \"PROTOCOL-AB.md section 'Pre-registered decision criteria', frozen at this date\""
  echo "}"
} > preregistration.json
echo "written: preregistration.json -- commit this BEFORE the first run"
