#!/usr/bin/env bash
# Admission gate for an orchestrator/worker pair. Only the worker can read the
# token (it sits in a directory the orchestrator is told nothing about, and
# the prompt never contains it), so the orchestrator reproduces it only if it
# actually invoked `worker` through its own shell tool and read the report.
# This catches a harness that cannot execute the delegation command on this OS
# (PATH, shims, quoting) -- which would leave the orchestrator deciding blind.
#
# Env: AB_ORCH_CMD AB_ORCH_MODEL AB_WORKER_CMD AB_WORKER_MODEL AB_WORKER_ENV
set -uo pipefail
cd "$(dirname "$0")"
for v in AB_ORCH_CMD AB_ORCH_MODEL AB_WORKER_CMD AB_WORKER_MODEL AB_WORKER_ENV; do
  [ -n "${!v:-}" ] || { echo "set $v" >&2; exit 2; }
done

rand() { (date +%s%N; echo "$$ $RANDOM $1") | sha256sum | cut -c1-12; }
ROOT="${TMPDIR:-/tmp}/ab-smoke-orch-$(rand r)"
WORK="$ROOT/ws"; BIN="$ROOT/bin"; SECRETDIR="$ROOT/vault"
mkdir -p "$WORK" "$BIN" "$SECRETDIR"
TOKEN="smoke-$(rand t)"
printf '%s\n' "$TOKEN" > "$SECRETDIR/token.txt"
git -C "$WORK" init -q

{
  echo '#!/usr/bin/env bash'
  echo 'set -uo pipefail'
  echo 'if [ $# -gt 0 ]; then instr="$*"; else instr="$(cat)"; fi'
  echo "set -a; for f in $AB_WORKER_ENV; do source <(tr -d '\\r' < \"\$f\"); done; set +a"
  echo "unset ${AB_WORKER_UNSET:-GEMINI_API_KEY GOOGLE_API_KEY}"
  echo "printf 'Read the file %s and reply with its exact contents and nothing else. (Request from the coordinator: %s)\\n' '$SECRETDIR/token.txt' \"\$instr\" | $AB_WORKER_CMD > '$ROOT/worker.jsonl' 2>&1"
  echo "node '$PWD/lib/final-report.js' '$ROOT/worker.jsonl'"
} > "$BIN/worker"
chmod +x "$BIN/worker"
printf '@echo off\r\nbash "%s" %%*\r\n' "$(cygpath -w "$BIN/worker" 2>/dev/null || echo "$BIN/worker")" > "$BIN/worker.cmd"

ORCH_UNSET=()
for k in ${AB_ORCH_UNSET:-DEEPSEEK_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY ANTHROPIC_BASE_URL}; do ORCH_UNSET+=(-u "$k"); done

LOGDIR="${AB_RUNS_DIR:-runs}/smoke"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/orch-$(printf '%s' "$AB_ORCH_MODEL-$AB_WORKER_MODEL" | tr -c 'A-Za-z0-9._-' '_')-$(date -u +%Y%m%dT%H%M%SZ).log"
out=$( cd "$WORK" && printf 'Run the shell command `worker "fetch the token"` and reply with exactly what it prints, nothing else.\n' \
  | env "${ORCH_UNSET[@]}" PATH="$BIN:$PATH" $AB_ORCH_CMD 2>&1 )
{ echo "orch: $AB_ORCH_MODEL  worker: $AB_WORKER_MODEL"; echo "--- orchestrator"; printf '%s\n' "$out"; echo "--- worker"; cat "$ROOT/worker.jsonl" 2>/dev/null; } > "$LOG"
rm -rf "$ROOT"

if printf '%s' "$out" | grep -q "$TOKEN"; then
  echo "PASS  delegation $AB_ORCH_MODEL -> $AB_WORKER_MODEL works (log: $LOG)"
else
  echo "FAIL  delegation $AB_ORCH_MODEL -> $AB_WORKER_MODEL -- token not relayed; do not run this pair (log: $LOG)"
  exit 1
fi
