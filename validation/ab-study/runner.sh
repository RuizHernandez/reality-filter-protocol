#!/usr/bin/env bash
# Runs one A/B cell and archives it with a chain of custody.
#
# Deliberately does NOT invoke any particular agent CLI. The agent command is
# injected, so the study is not welded to one vendor's tool and a run can be
# reproduced years later against whatever exists then:
#
#   AB_AGENT_CMD='claude -p --output-format stream-json --verbose' \
#   AB_MODEL='claude-sonnet-5' ./runner.sh t1-code-review A 1
#
# The command receives the composed prompt on stdin and runs with the task's
# freshly built fixture repository as its working directory; stdout and stderr
# are captured verbatim. Use a command whose stdout includes tool calls
# (e.g. stream-json): M1/M2 turn on whether the agent read an artifact, and a
# transcript with only the final answer cannot show that.
#
# Nothing here grades the output -- grading is blind and manual per
# PROTOCOL-AB.md, and a runner that scored its own runs would be the
# evaluator-immunity violation §5 names. The optional per-task check.sh records
# workspace facts (did a file change, does a script print X), never a score.
#
# Usage: runner.sh <task-id> <A|B> <run-number>
set -euo pipefail
cd "$(dirname "$0")"
STUDY_DIR="$(pwd -P)"

TASK="${1:-}"
COND="${2:-}"
RUN="${3:-}"

if [ -z "$TASK" ] || [ -z "$COND" ] || [ -z "$RUN" ]; then
  echo "usage: runner.sh <task-id> <A|B> <run-number>" >&2
  exit 2
fi
case "$COND" in A|B) ;; *) echo "condition must be A (control) or B (protocol)" >&2; exit 2 ;; esac
TDIR="tasks/$TASK"
[ -f "$TDIR/prompt.txt" ] && [ -f "$TDIR/fixture.sh" ] || {
  echo "no such task: need $TDIR/prompt.txt and $TDIR/fixture.sh" >&2; exit 2; }
[ -n "${AB_AGENT_CMD:-}" ] || { echo "set AB_AGENT_CMD to the agent command to run" >&2; exit 2; }
[ -n "${AB_MODEL:-}" ] || { echo "set AB_MODEL to the model identifier being run" >&2; exit 2; }

# No preregistration, no run. A study whose n, tasks and decision criteria are
# not frozen before the first run can be tuned to its own output -- the exact
# failure PROTOCOL-AB.md's decision criteria exist to prevent.
[ -f preregistration.json ] || {
  echo "no preregistration.json -- run ./preregister.sh <n> <model> [tasks] and commit it first" >&2
  exit 2
}

# AB_RUNS_DIR lets the sandbox map the repository read-only and only the
# results folder read-write, so an agent running with permissions bypassed
# cannot alter the host repository.
RUNS_DIR="${AB_RUNS_DIR:-$STUDY_DIR/runs}"
OUT="$RUNS_DIR/$TASK/$COND/run-$RUN"
[ -e "$OUT" ] && { echo "$OUT already exists; runs are never overwritten" >&2; exit 1; }
mkdir -p "$OUT"

# The workspace lives outside the study directory. tasks/<id>.md states the
# defect and the purpose of each task; an agent that could list its way up
# into it would be reading the answer key.
WORK_ROOT="${AB_WORK_ROOT:-${TMPDIR:-/tmp}/ab-work}"
mkdir -p "$WORK_ROOT"
# Opaque name: agent transcripts echo the working directory, and a path that
# spelled out the condition would unblind the grader.
WORK="$WORK_ROOT/ws-$( (date +%s%N; echo "$$ $RANDOM") | sha256sum | cut -c1-12)"
bash "$TDIR/fixture.sh" "$WORK" > "$OUT/fixture.log" 2>&1

PROMPT="$OUT/prompt.txt"
: > "$PROMPT"
# Condition B differs from A by exactly one thing: PROTOCOL.md is prepended.
# The agent sees tasks/<id>/prompt.txt only -- never tasks/<id>.md, which is
# the experimenter's spec and names the defect.
# CR is stripped so the prompt is byte-identical whatever line endings the
# checkout used.
if [ "$COND" = B ]; then
  tr -d '\r' < ../../PROTOCOL.md >> "$PROMPT"
  printf '\n\n---\n\n' >> "$PROMPT"
fi
tr -d '\r' < "$TDIR/prompt.txt" >> "$PROMPT"

# Record what was actually run, not what was intended: the protocol text and
# the task text can both change between runs, and a result that cannot be tied
# to the exact input it came from is not evidence.
{
  echo "task:      $TASK"
  echo "condition: $COND"
  echo "run:       $RUN"
  echo "model:     $AB_MODEL"
  echo "date:      $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "agent_cmd: $AB_AGENT_CMD"
  echo "protocol_sha:  $(git rev-parse --verify -q HEAD:PROTOCOL.md 2>/dev/null || echo uncommitted)"
  echo "prompt_txt_sha256:  $(tr -d '\r' < "$TDIR/prompt.txt" | sha256sum | cut -d' ' -f1)"
  echo "fixture_sha256:     $(tr -d '\r' < "$TDIR/fixture.sh" | sha256sum | cut -d' ' -f1)"
  echo "prompt_sha256:      $(sha256sum "$PROMPT" | cut -d' ' -f1)"
  echo "fixture_head:       $(git -C "$WORK" rev-parse HEAD)"
  echo "prompt_bytes:  $(wc -c < "$PROMPT" | tr -d ' ')"
  echo "preregistration_sha256: $(sha256sum preregistration.json | cut -d' ' -f1)"
  echo "workspace: $WORK"
} > "$OUT/metadata.txt"

set +e
# shellcheck disable=SC2086
( cd "$WORK" && $AB_AGENT_CMD < "$PROMPT" ) > "$OUT/stdout.log" 2> "$OUT/stderr.log"
echo "$?" > "$OUT/exit-code"
set -e

# What the agent left behind. Intent-to-add makes new files show in the diff;
# the workspace is disposable, so touching its index is harmless.
{
  echo "## git status"; git -C "$WORK" status --porcelain
  echo; echo "## git log (all branches)"; git -C "$WORK" log --oneline --all -10
  echo; echo "## diff vs HEAD (including new files)"
  git -C "$WORK" add -A -N . >/dev/null 2>&1 || true
  git -C "$WORK" -c core.autocrlf=false diff HEAD
} > "$OUT/workspace-after.txt" 2>&1

if [ -f "$TDIR/check.sh" ]; then
  bash "$TDIR/check.sh" "$WORK" > "$OUT/check.txt" 2>&1 || true
fi

# A run whose transcript mentions the study directory may have read the answer
# key. Flag it for the grader to inspect; do not silently discard it.
if grep -qiE "ab-study|PROTOCOL-AB|tasks/t[0-9]-|$(printf '%s' "$STUDY_DIR" | sed 's/[.[\*^$/]/\\&/g')" "$OUT/stdout.log"; then
  echo "transcript references the study directory -- inspect before grading" > "$OUT/CONTAMINATION-SUSPECT"
fi

# The graded copy has the condition stripped: protocol vocabulary and the
# prompt itself label which arm a transcript came from, and a grader who can
# see the arm is measuring their own expectation. See PROTOCOL-AB.md.
# lib/blind.js drops user-role prompt echoes (Gemini CLI emits them; in arm B
# the echo carries all of PROTOCOL.md), token/cost/duration fields (arm B's
# prompt is longer, so token counts alone reveal the arm) and system noise --
# while keeping every assistant message and tool call, including ones that
# quote the task prompt.
ECHO_KEY="$(tr -d '\r' < "$TDIR/prompt.txt" | head -c 40)"
node "$STUDY_DIR/lib/blind.js" "$ECHO_KEY" < "$OUT/stdout.log" \
  | sed -E 's/\[(E|I|S|U)\]/[?]/g; s/\[(Empirical|Inference|Speculation|Unverified)\]/[?]/g; s/Reality Filter/[redacted]/g; s/Filtro de Realidad/[redacted]/g; s/Anti-Sycophancy/[redacted]/g; s/§ ?[0-9]+(\.[0-9]+)*/§[redacted]/g' \
  > "$OUT/for-grading.txt" || true
if grep -qE "# PROTOCOL:|Universal core\. Protocol name" "$OUT/for-grading.txt"; then
  echo "PROTOCOL.md text survived into for-grading.txt -- the grader would see the arm" > "$OUT/BLINDING-SUSPECT"
fi

echo "archived: $OUT"
echo "grade $OUT/for-grading.txt blind; do not open metadata.txt until grading is recorded."
