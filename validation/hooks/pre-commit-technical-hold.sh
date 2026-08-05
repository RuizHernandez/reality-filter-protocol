#!/bin/sh
# Implements PROTOCOL.md §3.10 (HOLD is a technical stop). A HOLD marker file at
# the repo root blocks commits from every role except the orchestrator, instead
# of relying on a markdown STOP notice an implementer agent could ignore.

HOLD_FILE="$(git rev-parse --show-toplevel)/.HOLD"
role="${AGENT_ROLE:-unknown}"

if [ -f "$HOLD_FILE" ] && [ "$role" != "orchestrator" ]; then
  echo "REJECTED [technical-HOLD PROTOCOL.md §3.10]: repository is under HOLD:" >&2
  cat "$HOLD_FILE" >&2
  echo "Role '$role' may not commit while HOLD is active." >&2
  exit 1
fi

exit 0
