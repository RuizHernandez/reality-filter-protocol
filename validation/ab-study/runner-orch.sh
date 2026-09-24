#!/usr/bin/env bash
# Runs one A/B cell of the ORCHESTRATION design: an orchestrator agent that can
# delegate to a worker agent through a `worker` command.
#
#   AB_ORCH_CMD, AB_ORCH_MODEL      orchestrator (prompt on stdin, cwd = workspace)
#   AB_WORKER_CMD, AB_WORKER_MODEL  worker (prompt on stdin, cwd = workspace)
#   AB_WORKER_ENV                   file(s) sourced ONLY inside the worker script,
#                                   so worker credentials are not in the
#                                   orchestrator's environment
#
# Condition B prepends PROTOCOL.md to BOTH agents' prompts; A gives neither.
# The worker script is generated per run, outside the workspace, and in arm A
# contains no reference to the protocol: an orchestrator that inspects its own
# tools must not discover the manipulation.
#
# Usage: runner-orch.sh <task-id> <A|B> <run-number>
set -euo pipefail
cd "$(dirname "$0")"
STUDY_DIR="$(pwd -P)"

TASK="${1:-}"; COND="${2:-}"; RUN="${3:-}"
[ -n "$TASK" ] && [ -n "$COND" ] && [ -n "$RUN" ] || { echo "usage: runner-orch.sh <task-id> <A|B> <run-number>" >&2; exit 2; }
case "$COND" in A|B) ;; *) echo "condition must be A or B" >&2; exit 2 ;; esac
TDIR="tasks/$TASK"
[ -f "$TDIR/orch-prompt.txt" ] && [ -f "$TDIR/fixture.sh" ] || { echo "need $TDIR/orch-prompt.txt and fixture.sh" >&2; exit 2; }
for v in AB_ORCH_CMD AB_ORCH_MODEL AB_WORKER_CMD AB_WORKER_MODEL AB_WORKER_ENV; do
  [ -n "${!v:-}" ] || { echo "set $v" >&2; exit 2; }
done
[ -f preregistration.json ] || { echo "no preregistration.json" >&2; exit 2; }
grep -q '"design": "orch"' preregistration.json || { echo "preregistration.json is not for the orchestration design" >&2; exit 2; }

RUNS_DIR="${AB_RUNS_DIR:-$STUDY_DIR/runs}"
OUT="$RUNS_DIR/orch/$TASK/$COND/run-$RUN"
[ -e "$OUT" ] && { echo "$OUT exists; runs are never overwritten" >&2; exit 1; }
mkdir -p "$OUT"

rand() { (date +%s%N; echo "$$ $RANDOM $1") | sha256sum | cut -c1-12; }
WORK_ROOT="${AB_WORK_ROOT:-${TMPDIR:-/tmp}/ab-work}"
WORK="$WORK_ROOT/ws-$(rand w)"
BIN="$WORK_ROOT/bin-$(rand b)"
LOG="$WORK_ROOT/log-$(rand l)"
mkdir -p "$WORK_ROOT" "$BIN" "$LOG"
bash "$TDIR/fixture.sh" "$WORK" > "$OUT/fixture.log" 2>&1
FIXTURE_HEAD=$(git -C "$WORK" rev-parse HEAD)

# Orchestrator prompt.
PROMPT="$OUT/prompt.txt"; : > "$PROMPT"
if [ "$COND" = B ]; then tr -d '\r' < ../../PROTOCOL.md >> "$PROMPT"; printf '\n\n---\n\n' >> "$PROMPT"; fi
tr -d '\r' < "$TDIR/orch-prompt.txt" >> "$PROMPT"

# Worker preamble exists only in arm B.
if [ "$COND" = B ]; then
  { tr -d '\r' < ../../PROTOCOL.md; printf '\n\n---\n\n'; } > "$BIN/preamble.md"
fi

# The worker script must not reference the study directory: an orchestrator
# that reads its own tool would learn it is in an experiment. Helper and any
# env file living inside the study directory are copied to the opaque bin dir.
cp lib/final-report.js "$BIN/report.js"
WENV=""; i=0
for f in $AB_WORKER_ENV; do
  i=$((i + 1))
  case "$(cd "$(dirname "$f")" && pwd -P)/" in
    "$STUDY_DIR"/*) grep -v '^[[:space:]]*#' "$f" > "$BIN/env-$i"; WENV+=" '$BIN/env-$i'" ;;
    *) WENV+=" '$f'" ;;
  esac
done

# The worker script. Everything it references is an opaque path; arm A's copy
# has no preamble line at all.
{
  echo '#!/usr/bin/env bash'
  echo '# worker: delegate a task to a coding agent in this repository.'
  echo '# usage: worker "<instructions>"   (instructions may also come on stdin)'
  echo 'set -uo pipefail'
  echo 'if [ $# -gt 0 ]; then instr="$*"; else instr="$(cat)"; fi'
  echo '[ -n "$instr" ] || { echo "usage: worker \"<instructions>\"" >&2; exit 2; }'
  echo "n=\$(ls '$LOG'/worker-*.jsonl 2>/dev/null | wc -l); n=\$((n + 1))"
  echo "p='$LOG'/prompt-\$n.txt"
  if [ "$COND" = B ]; then echo "cat '$BIN/preamble.md' > \"\$p\""; else echo ': > "$p"'; fi
  echo 'printf "%s\n" "$instr" >> "$p"'
  echo "set -a; for f in$WENV; do source <(tr -d '\\r' < \"\$f\"); done; set +a"
  # The orchestrator's credentials must not ride along into the worker's
  # environment, where the worker could print them to its own provider.
  echo "unset ${AB_WORKER_UNSET:-GEMINI_API_KEY GOOGLE_API_KEY}"
  echo "$AB_WORKER_CMD < \"\$p\" > '$LOG'/worker-\$n.jsonl 2> '$LOG'/worker-\$n.err"
  echo "code=\$?"
  echo "node '$BIN/report.js' '$LOG'/worker-\$n.jsonl"
  echo 'exit $code'
} > "$BIN/worker"
chmod +x "$BIN/worker"
# Windows shells resolve commands by extension; give cmd/PowerShell-based
# harnesses a shim too.
printf '@echo off\r\nbash "%s" %%*\r\n' "$(cygpath -w "$BIN/worker" 2>/dev/null || echo "$BIN/worker")" > "$BIN/worker.cmd"

{
  echo "design:    orchestration"
  echo "task:      $TASK"
  echo "condition: $COND"
  echo "run:       $RUN"
  echo "orch_model:   $AB_ORCH_MODEL"
  echo "worker_model: $AB_WORKER_MODEL"
  echo "date:      $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "orch_cmd:   $AB_ORCH_CMD"
  echo "worker_cmd: $AB_WORKER_CMD"
  echo "protocol_sha:  $(git rev-parse --verify -q HEAD:PROTOCOL.md 2>/dev/null || echo uncommitted)"
  echo "orch_prompt_txt_sha256: $(tr -d '\r' < "$TDIR/orch-prompt.txt" | sha256sum | cut -d' ' -f1)"
  echo "fixture_sha256: $(tr -d '\r' < "$TDIR/fixture.sh" | sha256sum | cut -d' ' -f1)"
  echo "fixture_head:   $FIXTURE_HEAD"
  echo "preregistration_sha256: $(sha256sum preregistration.json | cut -d' ' -f1)"
  echo "workspace: $WORK"
} > "$OUT/metadata.txt"

# The worker's credentials are loaded by the worker script itself; they are
# removed from the orchestrator's environment so an orchestrator that prints
# its environment cannot send another provider's key to its own provider.
ORCH_UNSET=()
for k in ${AB_ORCH_UNSET:-DEEPSEEK_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY ANTHROPIC_BASE_URL}; do ORCH_UNSET+=(-u "$k"); done

set +e
( cd "$WORK" && env "${ORCH_UNSET[@]}" PATH="$BIN:$PATH" $AB_ORCH_CMD < "$PROMPT" ) > "$OUT/stdout.log" 2> "$OUT/stderr.log"
echo "$?" > "$OUT/exit-code"
set -e

# Collect worker transcripts.
nw=0
for f in "$LOG"/worker-*.jsonl; do
  [ -e "$f" ] || continue
  nw=$((nw + 1)); k="${f##*/worker-}"; k="${k%.jsonl}"
  cp "$f" "$OUT/worker-$k.jsonl"; cp "$LOG/worker-$k.err" "$OUT/worker-$k.err" 2>/dev/null || true
  cp "$LOG/prompt-$k.txt" "$OUT/worker-prompt-$k.txt"
done
echo "$nw" > "$OUT/worker-calls"

{
  echo "## git status"; git -C "$WORK" status --porcelain
  echo; echo "## git log (all branches)"; git -C "$WORK" log --oneline --all -10
  echo; echo "## diff vs fixture HEAD $FIXTURE_HEAD (including new files)"
  git -C "$WORK" add -A -N . >/dev/null 2>&1 || true
  git -C "$WORK" -c core.autocrlf=false diff "$FIXTURE_HEAD"
} > "$OUT/workspace-after.txt" 2>&1
[ -f "$TDIR/check.sh" ] && { bash "$TDIR/check.sh" "$WORK" "$FIXTURE_HEAD" > "$OUT/check.txt" 2>&1 || true; }

ALL=("$OUT/stdout.log"); for f in "$OUT"/worker-*.jsonl; do [ -e "$f" ] && ALL+=("$f"); done
if grep -qiE "ab-study|PROTOCOL-AB|tasks/t[0-9]-" "${ALL[@]}"; then
  echo "a transcript references the study directory -- inspect before grading" > "$OUT/CONTAMINATION-SUSPECT"
fi
# Credentials must never reach a transcript (and thereby another provider).
# Checked against the live values; the values are never written anywhere.
for k in GEMINI_API_KEY DEEPSEEK_API_KEY ANTHROPIC_API_KEY; do
  v="${!k:-}"; [ ${#v} -ge 12 ] || continue
  grep -qF -- "$v" "${ALL[@]}" && echo "$k value appears in a transcript -- rotate it" >> "$OUT/KEY-EXPOSED"
done

VOCAB='s/\[(E|I|S|U)\]/[?]/g; s/\[(Empirical|Inference|Speculation|Unverified)\]/[?]/g; s/Reality Filter/[redacted]/g; s/Filtro de Realidad/[redacted]/g; s/Anti-Sycophancy/[redacted]/g; s/§ ?[0-9]+(\.[0-9]+)*/§[redacted]/g'
ECHO_KEY="$(tr -d '\r' < "$TDIR/orch-prompt.txt" | head -c 40)"
node lib/blind.js "$ECHO_KEY" < "$OUT/stdout.log" | sed -E "$VOCAB" > "$OUT/for-grading.txt" || true
for f in "$OUT"/worker-*.jsonl; do
  [ -e "$f" ] || continue
  node lib/blind.js "" < "$f" | sed -E "$VOCAB" > "${f%.jsonl}.for-grading.txt" || true
done
if grep -qE "# PROTOCOL:|Universal core\. Protocol name" "$OUT"/*for-grading.txt 2>/dev/null; then
  echo "PROTOCOL.md text survived into a graded copy" > "$OUT/BLINDING-SUSPECT"
fi

echo "archived: $OUT (worker calls: $nw)"
