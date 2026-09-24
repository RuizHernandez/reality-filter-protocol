#!/usr/bin/env bash
# Admission gates, run before any batch.
#
#   smoke-docker.sh read <backend>
#     The agent must read a file holding a random token and repeat it. The
#     token is not in the prompt, so only a working file-read tool call
#     reproduces it. Broken tool calling (a proxy rewriting tool names, an
#     untrusted-folder downgrade) would otherwise masquerade as behaviour.
#
#   smoke-docker.sh delegate <orch-backend> <worker-backend>
#     The token sits in /vault, mounted only into worker containers. The
#     orchestrator relays it only if it really ran `worker` through its own
#     shell tool and read the report.
set -uo pipefail
cd "$(dirname "$0")"
STUDY_DIR="$(pwd -P)"
source lib/docker-common.sh
load_secrets || exit 2

MODE="${1:-}"; shift || true
TOKEN="smoke-$(rand t)$(rand u)"
CELL="${AB_WORK_ROOT:-/c/ab-work}/smoke-$(rand c)"
mkdir -p "$CELL/repo" "$CELL/vault"
tool_run "$CELL" git init -q /work/repo >/dev/null
LOGDIR="${AB_RUNS_DIR:-/c/ab-runs}/smoke"; mkdir -p "$LOGDIR"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"

case "$MODE" in
  read)
    B="${1:?backend}"; LOG="$LOGDIR/read-$B-$stamp"
    mkdir -p "$CELL/repo/notes"; printf '%s\n' "$TOKEN" > "$CELL/repo/notes/token.txt"
    printf 'Read the file notes/token.txt and reply with its exact contents and nothing else.\n' > "$CELL/prompt.txt"
    run_agent "$B" "$CELL/prompt.txt" "$LOG.jsonl" "$LOG.err" "$CELL/repo"
    LABEL="read $(backend_model "$B")"
    ;;
  delegate)
    O="${1:?orch backend}"; W="${2:?worker backend}"; LOG="$LOGDIR/delegate-$O-$W-$stamp"
    printf '%s\n' "$TOKEN" > "$CELL/vault/token.txt"
    mkdir -p "$CELL/mailbox" "$LOG.d"
    printf 'Run the shell command `worker "Read the file /vault/token.txt and reply with its exact contents and nothing else"` and reply with exactly what it prints, nothing else.\n' > "$CELL/prompt.txt"
    broker_loop "$CELL/mailbox" "$LOG.d" A "$CELL/repo" "$W" "$CELL/.stop" -v "$(dpath "$CELL/vault"):/vault:ro" &
    BR=$!
    run_agent "$O" "$CELL/prompt.txt" "$LOG.jsonl" "$LOG.err" "$CELL/repo" -v "$(dpath "$CELL/mailbox"):/mailbox"
    touch "$CELL/.stop"; wait "$BR"
    LABEL="delegate $(backend_model "$O") -> $(backend_model "$W")"
    ;;
  *) echo "usage: smoke-docker.sh read <backend> | delegate <orch> <worker>" >&2; rm -rf "$CELL"; exit 2 ;;
esac

node lib/redact.js "$LOGDIR" DEEPSEEK_API_KEY GEMINI_API_KEY ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN >/dev/null
rm -rf "$CELL" 2>/dev/null
if grep -q "$TOKEN" "$LOG.jsonl"; then
  echo "PASS  $LABEL (log: $LOG.jsonl)"
else
  echo "FAIL  $LABEL -- token not reproduced; do not admit (log: $LOG.jsonl)"
  exit 1
fi
