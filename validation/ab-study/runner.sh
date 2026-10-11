#!/usr/bin/env bash
# Runs one A/B cell and archives it with a chain of custody.
#
# Deliberately does NOT invoke any particular agent CLI. The agent command is
# injected, so the study is not welded to one vendor's tool and a run can be
# reproduced years later against whatever exists then:
#
#   AB_AGENT_CMD='cursor-agent --print --force' AB_MODEL_ID='<exact id>' \
#     ./runner.sh t1-code-review A 1
#
# The command receives the composed prompt on stdin; stdout and stderr are
# captured verbatim. Nothing here interprets or grades the output -- grading is
# blind and manual per PROTOCOL-AB.md, and a runner that scored its own runs
# would be the evaluator-immunity violation §5 names.
#
# Conditions: A (no protocol), B (PROTOCOL.md), and any further arm frozen in
# preregistration.json and built by make_arms.sh (C-placebo, ABL-no-s<N>).
#
# Usage: runner.sh <task-id> <condition> <run-number>
set -euo pipefail
cd "$(dirname "$0")"

TASK="${1:-}"
COND="${2:-}"
RUN="${3:-}"

if [ -z "$TASK" ] || [ -z "$COND" ] || [ -z "$RUN" ]; then
  echo "usage: runner.sh <task-id> <condition> <run-number>" >&2
  exit 2
fi
case "$COND" in
  A|B|C-placebo|ABL-*) ;;
  *) echo "condition must be A (control), B (protocol), C-placebo or ABL-<id>" >&2; exit 2 ;;
esac
[ -f "tasks/$TASK.md" ] || { echo "no such task: tasks/$TASK.md" >&2; exit 2; }
[ -n "${AB_AGENT_CMD:-}" ] || { echo "set AB_AGENT_CMD to the agent command to run" >&2; exit 2; }
# The model name a CLI defaults to changes under the same label ("auto",
# "latest"). The exact identifier the provider reports is part of the result.
[ -n "${AB_MODEL_ID:-}" ] || { echo "set AB_MODEL_ID to the exact model identifier the provider reports" >&2; exit 2; }

# No preregistration, no run. A study whose n, tasks and decision criteria are
# not frozen before the first run can be tuned to its own output -- the exact
# failure PROTOCOL-AB.md's decision criteria exist to prevent.
[ -f preregistration.json ] || {
  echo "no preregistration.json -- run ./preregister.sh <n> <model> [tasks] and commit it first" >&2
  exit 2
}

# The preregistration's hashes are checked, not just its existence: before
# this, PROTOCOL.md or a task could change after preregistration and the run
# proceeded, recording only the HEAD blob of what it might not have used.
proto_now=$(sha256sum ../../PROTOCOL.md | cut -d' ' -f1)
task_now=$(sha256sum "tasks/$TASK.md" | cut -d' ' -f1)
grep -q "\"protocol_sha256\": \"$proto_now\"" preregistration.json || {
  echo "PROTOCOL.md changed since preregistration -- a new study, not another run of this one" >&2; exit 2; }
grep -q "{ \"id\": \"$TASK\", \"sha256\": \"$task_now\" }" preregistration.json || {
  echo "task $TASK is not preregistered, or changed since preregistration" >&2; exit 2; }

case "$COND" in
  A) PREFIX=""; prefix_hash="null" ;;
  B) PREFIX="../../PROTOCOL.md"; prefix_hash="$proto_now" ;;
  *) PREFIX="arms/$COND.md"
     [ -f "$PREFIX" ] || { echo "arm $COND has no prefix file $PREFIX -- run ./make_arms.sh" >&2; exit 2; }
     prefix_hash=$(sha256sum "$PREFIX" | cut -d' ' -f1) ;;
esac
if [ "$prefix_hash" = null ]; then arm_line="{ \"id\": \"$COND\", \"prefix_sha256\": null }"
else arm_line="{ \"id\": \"$COND\", \"prefix_sha256\": \"$prefix_hash\" }"; fi
grep -qF "$arm_line" preregistration.json || {
  echo "arm $COND is not preregistered, or its prefix changed since preregistration" >&2; exit 2; }

OUT="runs/$TASK/$COND/run-$RUN"
[ -e "$OUT" ] && { echo "$OUT already exists -- runs are append-only; use a new run number" >&2; exit 2; }
mkdir -p "$OUT"

PROMPT="$OUT/prompt.txt"
: > "$PROMPT"

# Arms differ by exactly one thing: the prefix. Anything else added here
# silently changes what the study measures.
if [ -n "$PREFIX" ]; then
  cat "$PREFIX" >> "$PROMPT"
  printf '\n\n---\n\n' >> "$PROMPT"
fi
cat "tasks/$TASK.md" >> "$PROMPT"

# Record what was actually run, not what was intended: hashes of the bytes
# used, not of whatever HEAD holds.
{
  echo "task:      $TASK"
  echo "condition: $COND"
  echo "run:       $RUN"
  echo "date:      $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "agent_cmd: $AB_AGENT_CMD"
  echo "model_id:  $AB_MODEL_ID"
  echo "model_params: ${AB_MODEL_PARAMS:-unspecified}"
  echo "host:      $(uname -srm 2>/dev/null || echo unknown)"
  echo "protocol_sha256: $proto_now"
  echo "protocol_blob:   $(git rev-parse --verify -q HEAD:PROTOCOL.md 2>/dev/null || echo uncommitted)"
  echo "task_sha256:     $task_now"
  echo "prefix_sha256:   $prefix_hash"
  echo "prefix_bytes:    $([ -n "$PREFIX" ] && wc -c < "$PREFIX" | tr -d ' ' || echo 0)"
  echo "prompt_sha256:   $(sha256sum "$PROMPT" | cut -d' ' -f1)"
  echo "prompt_bytes:    $(wc -c < "$PROMPT" | tr -d ' ')"
  echo "runner_sha256:   $(sha256sum runner.sh | cut -d' ' -f1)"
  echo "preregistration_sha256: $(sha256sum preregistration.json | cut -d' ' -f1)"
} > "$OUT/metadata.txt"

set +e
start=$(date +%s)
# shellcheck disable=SC2086
$AB_AGENT_CMD < "$PROMPT" > "$OUT/stdout.log" 2> "$OUT/stderr.log"
echo "$?" > "$OUT/exit-code"
echo "wall_seconds:    $(( $(date +%s) - start ))" >> "$OUT/metadata.txt"
set -e

# The graded copy has the condition stripped: protocol vocabulary labels which
# arm a transcript came from, and a grader who can see the arm is measuring
# their own expectation. Short AND full-form labels, the mandatory correction
# template, and section references are stripped; only [E]-style short tags
# were before, so "[Empirical]" and "> Correction: ... It was wrong because"
# went to the grader intact.
sed -E \
  -e 's/\[(E|I|S|U|e|i|s|u)\]/[?]/g' \
  -e 's/\[(Empirical|Inference|Speculation|Unverified|Empírico|Inferencia|Especulación|No verificado)\]/[?]/gI' \
  -e 's/\**Correction\**:\**/[note]:/gI' \
  -e 's/It was wrong because/[reason]/gI' \
  -e 's/(Reality Filter|Filtro de Realidad|Anti-Sycophancy|PROTOCOL\.md|peer-unverified|evidence decay)/[redacted]/gI' \
  -e 's/§ ?[0-9]+(\.[0-9]+)*/§?/g' \
  "$OUT/stdout.log" > "$OUT/for-grading.txt"

# What the stripping could not catch is measured, not assumed away: residual
# protocol vocabulary is listed for the study lead (not the grader), so leakage
# is a reported number rather than an unexamined threat to blinding.
grep -nEi 'empirical|inference|speculation|unverified|verify before|sycophan|reality filter|evaluator-immunity|handoff|correction|wrong because' \
  "$OUT/for-grading.txt" > "$OUT/leak-report.txt" || true

echo "archived: $OUT"
echo "grade $OUT/for-grading.txt blind; do not open metadata.txt or leak-report.txt until grading is recorded."
