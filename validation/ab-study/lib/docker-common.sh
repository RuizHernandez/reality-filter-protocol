#!/usr/bin/env bash
# Shared helpers for the Docker runner and smoke gates. Sourced, not executed.
#
# Isolation is by construction: an agent container mounts only its workspace
# (/work/repo) and, for an orchestrator, a delegation mailbox (/mailbox). The
# study directory, task specs, other runs, secrets files and PROTOCOL.md never
# exist inside an agent container. Each container receives only its own
# provider's credentials, passed by variable name so values never appear on a
# command line.

AB_IMAGE="${AB_IMAGE:-ab-agent:1}"
AB_AGENT_TIMEOUT="${AB_AGENT_TIMEOUT:-1800}"

# Host path -> form docker.exe accepts under Git Bash; MSYS path conversion is
# disabled on every docker call so container paths like /work stay literal.
dpath() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi; }
d() { MSYS_NO_PATHCONV=1 docker "$@"; }
rand() { (date +%s%N; echo "$$ $RANDOM $1") | sha256sum | cut -c1-12; }

load_secrets() {
  local f="${AB_SECRETS:-/c/ab-secrets/secrets.env}"
  [ -f "$f" ] || { echo "no secrets file at $f" >&2; return 2; }
  set -a; source <(tr -d '\r' < "$f"); set +a
}

# Runs a tools-only container over a host directory mounted at /work.
# Used for fixture building, checks and git inspection -- never with an agent.
tool_run() { # <host-dir> <cmd...>
  local dir="$1"; shift
  d run --rm -v "$(dpath "$STUDY_DIR/tasks"):/fx:ro" -v "$(dpath "$dir"):/work" "$AB_IMAGE" "$@"
}

# Runs one agent. Prompt on stdin, JSONL transcript to <out>.
run_agent() { # <backend-name> <prompt-file> <out> <err> <repo-host-dir> [extra docker args...]
  local backend="$1" prompt="$2" out="$3" err="$4" repo="$5"; shift 5
  (
    set -e
    source "${AB_BACKENDS_DIR:-$STUDY_DIR/docker/backends}/$backend.sh"
    envargs=(); for n in "${BACKEND_ENV[@]}"; do envargs+=(-e "$n"); done
    name="ab-$(rand a)"
    set +e
    timeout "$AB_AGENT_TIMEOUT" env MSYS_NO_PATHCONV=1 docker run --rm -i --name "$name" \
      --cap-drop ALL --security-opt no-new-privileges --cpus 2 --memory 4g --hostname ws \
      -v "$(dpath "$repo"):/work/repo" -w /work/repo "$@" "${envargs[@]}" \
      "$AB_IMAGE" "${BACKEND_CMD[@]}" < "$prompt" > "$out" 2> "$err"
    code=$?
    [ "$code" -eq 124 ] && { d kill "$name" >/dev/null 2>&1; echo "agent timed out after ${AB_AGENT_TIMEOUT}s" >> "$err"; }
    exit "$code"
  )
}

backend_model() { ( source "${AB_BACKENDS_DIR:-$STUDY_DIR/docker/backends}/$1.sh" >/dev/null && printf '%s' "$BACKEND_MODEL" ); }

# Serves the orchestrator's `worker` requests until <stop-file> exists.
# Each request becomes one worker container over the same repository; the
# worker prompt gets PROTOCOL.md prepended in arm B. The orchestrator sees
# only the worker's final report, written back to the mailbox.
broker_loop() { # <mailbox> <logdir> <cond> <repo> <worker-backend> <stop-file> [extra docker args for worker...]
  local mb="$1" log="$2" cond="$3" repo="$4" wb="$5" stop="$6"; shift 6
  local k=0 r id p
  while :; do
    for r in "$mb"/req-*.txt; do
      [ -e "$r" ] || continue
      id="${r##*/req-}"; id="${id%.txt}"
      mv "$r" "$log/worker-request-$id.txt"
      k=$((k + 1))
      p="$log/worker-prompt-$k.txt"; : > "$p"
      if [ "$cond" = B ]; then tr -d '\r' < "$STUDY_DIR/../../PROTOCOL.md" >> "$p"; printf '\n\n---\n\n' >> "$p"; fi
      tr -d '\r' < "$log/worker-request-$id.txt" >> "$p"
      run_agent "$wb" "$p" "$log/worker-$k.jsonl" "$log/worker-$k.err" "$repo" "$@"
      node "$STUDY_DIR/lib/final-report.js" "$log/worker-$k.jsonl" > "$mb/resp-$id.tmp" 2>&1
      mv "$mb/resp-$id.tmp" "$mb/resp-$id.txt"
    done
    [ -f "$stop" ] && break
    sleep 1
  done
  echo "$k" > "$log/worker-calls"
}
