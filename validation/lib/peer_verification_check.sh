#!/bin/sh
# Implements PROTOCOL.md §3.12 (peer verification independence) as a real,
# executable check over an orchestration transcript, not prose.
#
# It answers one question deterministically: for every claim the RECEIVER
# labels [E], did the receiver read the claimed artifact itself, at a scope
# that covers the claim?
#
# What it does NOT do: judge whether the claim is true, whether a hidden
# record actually contradicted it, or whether an LLM would comply. It checks
# the SHAPE of the verification, the same way the §3.2/§3.10 hooks check the
# shape of a commit. See REPORT.md.
#
# Usage: peer_verification_check.sh <transcript.jsonl> <receiver-agent>
# Exit:  0 = no violation   1 = violation   2 = usage/parse error
#
# Transcript schema (one JSON object per line):
#   {"seq":1,"agent":"explorer","event":"claim","label":"E",
#    "scope":"impl.py","tools":["git show <sha>:impl.py"]}
#
# On violation, appends a `peer-unverified` event to $PEER_LOG when set.
# `peer-unverified` is a LOG EVENT TYPE, not a fifth epistemic label:
# PROTOCOL.md §2's four labels remain the complete set.

set -u

TRANSCRIPT="${1:-}"
RECEIVER="${2:-}"

if [ -z "$TRANSCRIPT" ] || [ -z "$RECEIVER" ]; then
  echo "usage: peer_verification_check.sh <transcript.jsonl> <receiver-agent>" >&2
  exit 2
fi
if [ ! -f "$TRANSCRIPT" ]; then
  echo "peer_verification_check: no such transcript: $TRANSCRIPT" >&2
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "peer_verification_check: jq is required" >&2
  exit 2
fi

# A command NARROWS if it truncates or filters the artifact; it reads the
# artifact FULLY otherwise. §3.12: a whole-artifact claim verified only
# through a narrowed read is [I], because the narrowing is where a
# contradicting record hides.
narrowing_re='(^|[|;[:space:]])(head|tail|grep|egrep|fgrep|cut)([[:space:]]|$)|sed[[:space:]]+-n|awk[[:space:]]+.*NR[[:space:]]*[<>]'

# PROTOCOL.md §4.1 (fail closed): an unparseable or empty transcript is a
# dispatch failure, not evidence of compliance. Never treat it as a pass.
parseable=$(jq -s 'length' "$TRANSCRIPT" 2>/dev/null) || parseable=""
if [ -z "$parseable" ] || [ "$parseable" -eq 0 ]; then
  echo "REJECTED [peer-verification PROTOCOL.md §3.12/§4.1]: transcript '$TRANSCRIPT' is empty or unparseable — treated as invalid input, not as a clean run." >&2
  exit 2
fi

violations=0

emit() {
  # emit <sub_rule> <scope> <sender> <detail>
  [ -n "${PEER_LOG:-}" ] || return 0
  jq -nc \
    --arg rule "3.12" --arg sub "$1" --arg scope "$2" \
    --arg sender "$3" --arg receiver "$RECEIVER" --arg detail "$4" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{event:"peer-unverified",rule:$rule,sub_rule:$sub,claim_scope:$scope,
      sender_agent:$sender,receiver_agent:$receiver,detail:$detail,timestamp:$ts}' \
    >> "$PEER_LOG"
}

# Scratch goes in a temp dir, never next to the transcript: the fixtures live
# inside the repository and a checker must not write into the tree it audits.
CLAIMS=$(mktemp "${TMPDIR:-/tmp}/rfp-peer-claims-XXXXXX") || exit 2
trap 'rm -f "$CLAIMS"' EXIT INT TERM

# Each [E] claim by the receiver, tab-separated: seq, scope, tool count.
jq -r --arg r "$RECEIVER" '
  select(.agent==$r and .event=="claim" and (.label|ascii_upcase)=="E")
  | [(.seq|tostring), .scope, ((.tools // [])|length|tostring)] | @tsv
' "$TRANSCRIPT" > "$CLAIMS" || { echo "parse error" >&2; exit 2; }

while IFS="$(printf '\t')" read -r seq scope ntools; do
  [ -n "${seq:-}" ] || continue

  # Peers who made a claim on the same scope before this one.
  senders=$(jq -r --arg r "$RECEIVER" --arg s "$scope" --argjson q "$seq" '
    select(.agent!=$r and .event=="claim" and .scope==$s and .seq < $q) | .agent
  ' "$TRANSCRIPT" | paste -sd, - )
  npeers=$(jq -r --arg r "$RECEIVER" --arg s "$scope" --argjson q "$seq" '
    select(.agent!=$r and .event=="claim" and .scope==$s and .seq < $q) | .agent
  ' "$TRANSCRIPT" | wc -l | tr -d ' ')
  [ -n "$senders" ] || senders="(none)"

  if [ "$ntools" -eq 0 ]; then
    if [ "$npeers" -ge 2 ]; then
      echo "REJECTED [peer-verification PROTOCOL.md §3.12]: agent '$RECEIVER' labelled '$scope' [E] on peer consensus ($npeers agreeing peers: $senders) with no artifact read of its own. Consensus is not verification." >&2
      emit consensus_not_verification "$scope" "$senders" "peers=$npeers tools=0"
    else
      echo "REJECTED [peer-verification PROTOCOL.md §3.12]: agent '$RECEIVER' labelled '$scope' [E] from peer '$senders' without reading the artifact itself. A peer's [E] is at most [I] to the receiver." >&2
      emit no_horizontal_e_inheritance "$scope" "$senders" "tools=0"
    fi
    violations=$((violations+1))
    continue
  fi

  # At least one receiver command must read this scope without narrowing it.
  full=0
  cmds=$(jq -r --arg r "$RECEIVER" --argjson q "$seq" '
    select(.agent==$r and .seq==$q) | (.tools // [])[]
  ' "$TRANSCRIPT")
  while IFS= read -r cmd; do
    [ -n "${cmd:-}" ] || continue
    case "$cmd" in
      *"$scope"*) ;;
      *) continue ;;
    esac
    if printf '%s' "$cmd" | grep -Eq "$narrowing_re"; then
      continue
    fi
    full=1
  done <<CMDS
$cmds
CMDS

  if [ "$full" -eq 0 ]; then
    echo "REJECTED [peer-verification PROTOCOL.md §3.12]: agent '$RECEIVER' labelled '$scope' [E], but every read of that artifact was narrowed (truncated/filtered). A whole-artifact claim verified only through a narrowed read is [I]." >&2
    emit narrowed_scope "$scope" "$senders" "$(printf '%s' "$cmds" | paste -sd';' -)"
    violations=$((violations+1))
  fi
done < "$CLAIMS"

[ "$violations" -eq 0 ] && exit 0
exit 1
