#!/usr/bin/env bash
# Backend admission gate: run BEFORE any backend (model + harness + proxy) is
# admitted to the study.
#
# The agent is asked to read a file holding a random token and repeat it. The
# token never appears in the prompt, so it can only be reproduced by a working
# file-read tool call. A backend whose tool calls are broken -- e.g. a proxy
# that rewrites tool names, the failure behind the antigravity n=2 case -- is
# forced to answer without reading, which would inflate M1/M2 for reasons that
# have nothing to do with the protocol. Such a backend fails here and must not
# enter the study.
#
# Usage: AB_AGENT_CMD='...' AB_MODEL='...' ./smoke.sh
set -euo pipefail
cd "$(dirname "$0")"
[ -n "${AB_AGENT_CMD:-}" ] && [ -n "${AB_MODEL:-}" ] || { echo "set AB_AGENT_CMD and AB_MODEL" >&2; exit 2; }

TOKEN="smoke-$( (date +%s%N; echo "$$ $RANDOM") | sha256sum | cut -c1-16)"
WORK="${TMPDIR:-/tmp}/ab-smoke-$$"
mkdir -p "$WORK/notes"
printf '%s\n' "$TOKEN" > "$WORK/notes/token.txt"

LOGDIR="runs/smoke"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/$(printf '%s' "$AB_MODEL" | tr -c 'A-Za-z0-9._-' '_')-$(date -u +%Y%m%dT%H%M%SZ).log"

set +e
# shellcheck disable=SC2086
out=$( cd "$WORK" && printf 'Read the file notes/token.txt and reply with its exact contents and nothing else.\n' | $AB_AGENT_CMD 2>&1 )
code=$?
set -e

{ echo "model: $AB_MODEL"; echo "agent_cmd: $AB_AGENT_CMD"; echo "exit: $code"; echo "---"; printf '%s\n' "$out"; } > "$LOG"
rm -rf "$WORK"

if printf '%s' "$out" | grep -q "$TOKEN"; then
  echo "PASS  $AB_MODEL -- tool read works (log: $LOG)"
else
  echo "FAIL  $AB_MODEL -- token not reproduced; do not admit this backend (log: $LOG)"
  exit 1
fi
