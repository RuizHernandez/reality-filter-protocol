#!/usr/bin/env bash
# Runs one A/B cell with every agent in its own Docker container.
# The design (single agent, or orchestrator + worker) comes from
# preregistration.json.
#
#   single:  AB_AGENT=<backend>                        prompt: tasks/<id>/prompt.txt
#   orch:    AB_ORCH=<backend> AB_WORKER=<backend>     prompt: tasks/<id>/orch-prompt.txt
#
# Backends live in docker/backends/<name>.sh. Secrets come from AB_SECRETS
# (default /c/ab-secrets/secrets.env). Results go to AB_RUNS_DIR (default
# /c/ab-runs), outside the repository and outside any synced folder.
#
# Usage: runner-docker.sh <task-id> <A|B> <run-number>
set -euo pipefail
cd "$(dirname "$0")"
STUDY_DIR="$(pwd -P)"
source lib/docker-common.sh

TASK="${1:-}"; COND="${2:-}"; RUN="${3:-}"
[ -n "$TASK" ] && [ -n "$COND" ] && [ -n "$RUN" ] || { echo "usage: runner-docker.sh <task-id> <A|B> <run-number>" >&2; exit 2; }
case "$COND" in A|B) ;; *) echo "condition must be A or B" >&2; exit 2 ;; esac
[ -f preregistration.json ] || { echo "no preregistration.json" >&2; exit 2; }
if grep -q '"design": "orch"' preregistration.json; then DESIGN=orch; PFILE=orch-prompt.txt; else DESIGN=single; PFILE=prompt.txt; fi
TDIR="tasks/$TASK"
[ -f "$TDIR/$PFILE" ] && [ -f "$TDIR/fixture.sh" ] || { echo "task $TASK has no $PFILE for design $DESIGN" >&2; exit 2; }
if [ "$DESIGN" = single ]; then
  [ -n "${AB_AGENT:-}" ] || { echo "set AB_AGENT" >&2; exit 2; }
else
  [ -n "${AB_ORCH:-}" ] && [ -n "${AB_WORKER:-}" ] || { echo "set AB_ORCH and AB_WORKER" >&2; exit 2; }
fi
load_secrets

RUNS_DIR="${AB_RUNS_DIR:-/c/ab-runs}"
OUT="$RUNS_DIR/$DESIGN/$TASK/$COND/run-$RUN"
[ -e "$OUT" ] && { echo "$OUT exists; runs are never overwritten" >&2; exit 1; }
mkdir -p "$OUT"
CELL="${AB_WORK_ROOT:-/c/ab-work}/cell-$(rand c)"
REPO="$CELL/repo"
mkdir -p "$CELL"

# Fixture, built in a tools-only container so it is identical on every host.
tool_run "$CELL" bash "/fx/$TASK/fixture.sh" /work/repo > "$OUT/fixture.log" 2>&1
FIXTURE_HEAD="$(tool_run "$CELL" git -C /work/repo rev-parse HEAD | tr -d '\r')"

PROMPT="$OUT/prompt.txt"; : > "$PROMPT"
if [ "$COND" = B ]; then tr -d '\r' < ../../PROTOCOL.md >> "$PROMPT"; printf '\n\n---\n\n' >> "$PROMPT"; fi
tr -d '\r' < "$TDIR/$PFILE" >> "$PROMPT"

if [ "$DESIGN" = single ]; then
  MODELS="agent_model: $(backend_model "$AB_AGENT")"
else
  MODELS="orch_model: $(backend_model "$AB_ORCH")
worker_model: $(backend_model "$AB_WORKER")"
fi
{
  echo "design:    $DESIGN"
  echo "task:      $TASK"
  echo "condition: $COND"
  echo "run:       $RUN"
  echo "$MODELS"
  echo "date:      $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "image:     $AB_IMAGE $(d image inspect "$AB_IMAGE" --format '{{.Id}}')"
  echo "protocol_sha:  $(git rev-parse --verify -q HEAD:PROTOCOL.md 2>/dev/null || echo uncommitted)"
  echo "prompt_file_sha256: $(tr -d '\r' < "$TDIR/$PFILE" | sha256sum | cut -d' ' -f1)"
  echo "fixture_sha256:     $(tr -d '\r' < "$TDIR/fixture.sh" | sha256sum | cut -d' ' -f1)"
  echo "fixture_head:       $FIXTURE_HEAD"
  echo "prompt_sha256:      $(sha256sum "$PROMPT" | cut -d' ' -f1)"
  echo "preregistration_sha256: $(sha256sum preregistration.json | cut -d' ' -f1)"
} > "$OUT/metadata.txt"

set +e
if [ "$DESIGN" = single ]; then
  run_agent "$AB_AGENT" "$PROMPT" "$OUT/stdout.log" "$OUT/stderr.log" "$REPO"
  echo "$?" > "$OUT/exit-code"
else
  MB="$CELL/mailbox"; STOP="$CELL/.stop"; mkdir -p "$MB"
  broker_loop "$MB" "$OUT" "$COND" "$REPO" "$AB_WORKER" "$STOP" &
  BROKER=$!
  run_agent "$AB_ORCH" "$PROMPT" "$OUT/stdout.log" "$OUT/stderr.log" "$REPO" -v "$(dpath "$MB"):/mailbox"
  echo "$?" > "$OUT/exit-code"
  touch "$STOP"; wait "$BROKER"
fi
set -e

{
  echo "## git status"; tool_run "$CELL" git -C /work/repo status --porcelain
  echo; echo "## git log (all branches)"; tool_run "$CELL" git -C /work/repo log --oneline --all -10
  echo; echo "## diff vs fixture HEAD $FIXTURE_HEAD (including new files)"
  tool_run "$CELL" bash -c "git -C /work/repo add -A -N . >/dev/null 2>&1; git -C /work/repo -c core.autocrlf=false diff $FIXTURE_HEAD"
} > "$OUT/workspace-after.txt" 2>&1
if [ -f "$TDIR/check.sh" ]; then
  tool_run "$CELL" bash "/fx/$TASK/check.sh" /work/repo "$FIXTURE_HEAD" > "$OUT/check.txt" 2>&1 || true
fi

# Credentials out of the archive, whatever the agents printed.
REDACT=$(node lib/redact.js "$OUT" DEEPSEEK_API_KEY GEMINI_API_KEY ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN)
if printf '%s' "$REDACT" | grep -qE ':[1-9]'; then
  echo "credential values appeared in transcripts and were redacted: $REDACT" > "$OUT/KEY-EXPOSED"
fi

TRANSCRIPTS=("$OUT/stdout.log"); for f in "$OUT"/worker-*.jsonl; do [ -e "$f" ] && TRANSCRIPTS+=("$f"); done
if grep -qiE "ab-study|PROTOCOL-AB|reality-filter-protocol|tasks/t[0-9]-" "${TRANSCRIPTS[@]}"; then
  echo "a transcript references the study -- inspect before grading" > "$OUT/CONTAMINATION-SUSPECT"
fi

VOCAB='s/\[(E|I|S|U)\]/[?]/g; s/\[(Empirical|Inference|Speculation|Unverified)\]/[?]/g; s/Reality Filter/[redacted]/g; s/Filtro de Realidad/[redacted]/g; s/Anti-Sycophancy/[redacted]/g; s/§ ?[0-9]+(\.[0-9]+)*/§[redacted]/g'
node lib/blind.js < "$OUT/stdout.log" | sed -E "$VOCAB" > "$OUT/for-grading.txt" || true
for f in "$OUT"/worker-*.jsonl; do
  [ -e "$f" ] || continue
  node lib/blind.js < "$f" | sed -E "$VOCAB" > "${f%.jsonl}.for-grading.txt" || true
done
if grep -qE "# PROTOCOL:|Universal core\. Protocol name" "$OUT"/*for-grading.txt 2>/dev/null; then
  echo "PROTOCOL.md text survived into a graded copy" > "$OUT/BLINDING-SUSPECT"
fi

[ -n "${AB_KEEP_WORK:-}" ] || rm -rf "$CELL" 2>/dev/null || true
echo "archived: $OUT${DESIGN:+ ($DESIGN)}$([ -f "$OUT/worker-calls" ] && echo ", worker calls: $(cat "$OUT/worker-calls")")"
