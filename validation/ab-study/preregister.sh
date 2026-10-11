#!/usr/bin/env bash
# Writes preregistration.json: the frozen declaration of what the A/B study
# will run and what result it will accept, BEFORE any run happens.
# PROTOCOL-AB.md explains why this is a hashed file and not prose.
#
# Usage: preregister.sh <n-per-condition-per-task> <model-identifier> [task ...]
#
# AB_ARMS selects the arms (default "A B"). Arms beyond A/B are built by
# make_arms.sh and frozen here by hash, e.g.:
#   AB_ARMS="A B C ABL-no-s1 ABL-no-s2 ABL-no-s3 ABL-no-s4-6" ./preregister.sh 10 <model>
# AB_MODEL_PARAMS records sampling settings (temperature, max tokens, ...);
# without them a rerun cannot claim the same conditions.
set -euo pipefail
cd "$(dirname "$0")"

N="${1:-}"; MODEL="${2:-}"; shift 2 || true
TASKS=("$@")
[ -n "$N" ] && [ -n "$MODEL" ] || { echo "usage: preregister.sh <n> <model> [task ...]" >&2; exit 2; }
[[ $N =~ ^[0-9]+$ ]] && [ "$N" -ge 1 ] || { echo "n must be a positive integer" >&2; exit 2; }
# Both values are written into JSON verbatim; a quote or backslash would
# produce a file that is frozen and unparseable at once.
for v in "$MODEL" "${AB_MODEL_PARAMS:-}"; do
  case "$v" in *'"'*|*'\'*) echo "model id and AB_MODEL_PARAMS must not contain \" or \\" >&2; exit 2 ;; esac
done
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

# Every arm's prompt prefix is frozen by hash. A = none, B = PROTOCOL.md,
# others = arms/<id>.md from make_arms.sh.
read -r -a ARMS <<< "${AB_ARMS:-A B}"
arm_json=""
for a in "${ARMS[@]}"; do
  case "$a" in
    A) h="null" ;;
    B) h="\"$proto_hash\"" ;;
    *) [ -f "arms/$a.md" ] || { echo "arm $a has no prefix file arms/$a.md -- run ./make_arms.sh first" >&2; exit 2; }
       h="\"$(sha256sum "arms/$a.md" | cut -d' ' -f1)\"" ;;
  esac
  arm_json+="    { \"id\": \"$a\", \"prefix_sha256\": $h },
"
done
arm_json="${arm_json%,
}"

{
  echo "{"
  echo "  \"date\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
  echo "  \"n_per_condition_per_task\": $N,"
  echo "  \"model\": \"$MODEL\","
  echo "  \"model_params\": \"${AB_MODEL_PARAMS:-unspecified}\","
  echo "  \"protocol_sha256\": \"$proto_hash\","
  echo "  \"arms\": ["
  printf '%b
' "$arm_json"
  echo "  ],"
  echo "  \"tasks\": ["
  printf '%b
' "$task_json"
  echo "  ],"
  echo "  \"decision_criteria\": \"PROTOCOL-AB.md section 'Pre-registered decision criteria', frozen at this date\""
  echo "}"
} > preregistration.json
echo "written: preregistration.json -- commit this BEFORE the first run"
