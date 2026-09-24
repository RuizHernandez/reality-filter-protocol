#!/usr/bin/env bash
# Writes preregistration.json: the frozen declaration of what the A/B study
# will run and what result it will accept, BEFORE any run happens.
# PROTOCOL-AB.md explains why this is a hashed file and not prose.
#
# Every file that shapes what the agent sees or what the run records is hashed:
# the experimenter spec, the agent-facing prompt, the fixture builder, and the
# workspace check. Changing any of them after preregistration is a new study.
#
# Usage: preregister.sh <n-per-condition-per-task> <model-identifier(s)> [task ...]
set -euo pipefail
cd "$(dirname "$0")"

N="${1:-}"; MODEL="${2:-}"; shift 2 || true
TASKS=("$@")
[ -n "$N" ] && [ -n "$MODEL" ] || { echo "usage: preregister.sh <n> <model> [task ...]" >&2; exit 2; }
[ -f preregistration.json ] && { echo "preregistration.json already exists -- it is frozen; editing it means a new study" >&2; exit 1; }
if [ ${#TASKS[@]} -eq 0 ]; then
  TASKS=()
  for d in tasks/*/; do [ -f "$d/prompt.txt" ] && TASKS+=("$(basename "$d")"); done
fi

# Hash with CR stripped: a Windows checkout may rewrite line endings, and the
# frozen hashes must match the same file on every platform.
h() { if [ -f "$1" ]; then tr -d '\r' < "$1" | sha256sum | cut -d' ' -f1; else echo "none"; fi; }

proto_hash=$(h ../../PROTOCOL.md)
lib_hash=$(h tasks/lib-fixture.sh)
task_json=""
for t in "${TASKS[@]}"; do
  [ -f "tasks/$t/prompt.txt" ] && [ -f "tasks/$t/fixture.sh" ] || { echo "incomplete task: tasks/$t" >&2; exit 2; }
  task_json+="    { \"id\": \"$t\", \"spec_sha256\": \"$(h "tasks/$t.md")\", \"prompt_sha256\": \"$(h "tasks/$t/prompt.txt")\", \"fixture_sha256\": \"$(h "tasks/$t/fixture.sh")\", \"check_sha256\": \"$(h "tasks/$t/check.sh")\" },
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
  echo "  \"fixture_lib_sha256\": \"$lib_hash\","
  echo "  \"tasks\": ["
  printf '%b\n' "$task_json"
  echo "  ],"
  echo "  \"decision_criteria\": \"PROTOCOL-AB.md section 'Pre-registered decision criteria', frozen at this date\""
  echo "}"
} > preregistration.json
echo "written: preregistration.json -- commit this BEFORE the first run"
