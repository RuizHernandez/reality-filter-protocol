#!/usr/bin/env bash
# Runs one A/B cell and archives it with a chain of custody.
#
# Deliberately does NOT invoke any particular agent CLI. The agent command is
# injected, so the study is not welded to one vendor's tool and a run can be
# reproduced years later against whatever exists then:
#
#   AB_AGENT_CMD='cursor-agent --print --force'  ./runner.sh t1-code-review A 1
#
# The command receives the composed prompt on stdin; stdout and stderr are
# captured verbatim. Nothing here interprets or grades the output -- grading is
# blind and manual per PROTOCOL-AB.md, and a runner that scored its own runs
# would be the evaluator-immunity violation §5 names.
#
# Usage: runner.sh <task-id> <A|B> <run-number>
set -euo pipefail
cd "$(dirname "$0")"

TASK="${1:-}"
COND="${2:-}"
RUN="${3:-}"

if [ -z "$TASK" ] || [ -z "$COND" ] || [ -z "$RUN" ]; then
  echo "usage: runner.sh <task-id> <A|B> <run-number>" >&2
  exit 2
fi
case "$COND" in A|B) ;; *) echo "condition must be A (control) or B (protocol)" >&2; exit 2 ;; esac
[ -f "tasks/$TASK.md" ] || { echo "no such task: tasks/$TASK.md" >&2; exit 2; }
[ -n "${AB_AGENT_CMD:-}" ] || { echo "set AB_AGENT_CMD to the agent command to run" >&2; exit 2; }

# No preregistration, no run. A study whose n, tasks and decision criteria are
# not frozen before the first run can be tuned to its own output -- the exact
# failure PROTOCOL-AB.md's decision criteria exist to prevent.
[ -f preregistration.json ] || {
  echo "no preregistration.json -- run ./preregister.sh <n> <model> [tasks] and commit it first" >&2
  exit 2
}

OUT="runs/$TASK/$COND/run-$RUN"
mkdir -p "$OUT"

PROMPT="$OUT/prompt.txt"
: > "$PROMPT"

# Condition B differs from A by exactly one thing: PROTOCOL.md is prepended.
# Anything else added here silently changes what the study measures.
if [ "$COND" = B ]; then
  cat ../../PROTOCOL.md >> "$PROMPT"
  printf '\n\n---\n\n' >> "$PROMPT"
fi
cat "tasks/$TASK.md" >> "$PROMPT"

# Record what was actually run, not what was intended: the protocol text and
# the task text can both change between runs, and a result that cannot be tied
# to the exact input it came from is not evidence.
{
  echo "task:      $TASK"
  echo "condition: $COND"
  echo "run:       $RUN"
  echo "date:      $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "agent_cmd: $AB_AGENT_CMD"
  echo "protocol_sha:  $(git rev-parse --verify -q HEAD:PROTOCOL.md 2>/dev/null || echo uncommitted)"
  echo "task_sha:      $(git rev-parse --verify -q "HEAD:validation/ab-study/tasks/$TASK.md" 2>/dev/null || echo uncommitted)"
  echo "prompt_bytes:  $(wc -c < "$PROMPT" | tr -d ' ')"
  echo "preregistration_sha256: $(sha256sum preregistration.json | cut -d' ' -f1)"
} > "$OUT/metadata.txt"

set +e
# shellcheck disable=SC2086
$AB_AGENT_CMD < "$PROMPT" > "$OUT/stdout.log" 2> "$OUT/stderr.log"
echo "$?" > "$OUT/exit-code"
set -e

# The graded copy has the condition stripped: protocol vocabulary and the
# prompt itself label which arm a transcript came from, and a grader who can
# see the arm is measuring their own expectation. See PROTOCOL-AB.md.
sed -E 's/\[(E|I|S|U)\]/[?]/g; s/Reality Filter/[redacted]/g; s/Filtro de Realidad/[redacted]/g' \
  "$OUT/stdout.log" > "$OUT/for-grading.txt"

echo "archived: $OUT"
echo "grade $OUT/for-grading.txt blind; do not open metadata.txt until grading is recorded."
