#!/usr/bin/env bash
# Synthetic validation of PROTOCOL.md §3.12 (peer verification independence).
#
# Every PASS/FAIL below is the exit code of an actual invocation of
# validation/lib/peer_verification_check.sh against a fixture transcript —
# not a prediction, and not a comparison of two string literals. Same
# standard as replay_incident.sh.
#
# What this validates: that the §3.12 checker accepts protocol-compliant
# peer verification and rejects the four non-compliant shapes. What it does
# NOT validate: that any LLM agent complies with §3.12, that a flagged claim
# was actually false, or that this checker is wired into any adapter. See
# REPORT.md.
#
# Usage: peer_verification_suite.sh [scratch-workdir]
set -u

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECK="$SELF_DIR/lib/peer_verification_check.sh"
# validation/lib/mutate_check.sh substitutes a mutant through these two
# variables. A suite that ignores them makes every mutant "survive" -- which
# is what happened before they were honoured here.
if [ -n "${RFP_CHECKER_UNDER_TEST:-}" ]; then
  [ "${RFP_CHECKER_TARGET:-}" = "$(basename "$CHECK")" ] || {
    echo "ENVIRONMENT ERROR: RFP_CHECKER_TARGET='${RFP_CHECKER_TARGET:-}' is not a checker this suite runs" >&2; exit 2; }
  CHECK="$RFP_CHECKER_UNDER_TEST"
fi
FIX="$SELF_DIR/fixtures/peer-transcripts"
WORKDIR="${1:-$(mktemp -d "${TMPDIR:-/tmp}/rfp-peer-XXXXXX")}"

# The checker exits 2 without jq. Run anyway and PV7/PV8 "pass" -- invalid
# input reported as invalid input -- while nothing was parsed at all. A
# missing dependency is an environment error, not a scenario result.
command -v jq >/dev/null 2>&1 || {
  echo "ENVIRONMENT ERROR: jq is required by the checker under test; no scenario was evaluated" >&2
  exit 2
}

mkdir -p "$WORKDIR"
export PEER_LOG="$WORKDIR/peer-unverified.jsonl"
: > "$PEER_LOG"

PASS=0
FAIL=0
RESULTS=()

record() {
  local name="$1" expect="$2" got="$3"
  if [ "$expect" = "$got" ]; then
    RESULTS+=("PASS | $name | expected=$expect got=$got")
    PASS=$((PASS+1))
  else
    RESULTS+=("FAIL | $name | expected=$expect got=$got")
    FAIL=$((FAIL+1))
  fi
}

run() {
  # run <label> <fixture> <receiver> <expected-exit>
  local name="$1" fixture="$2" receiver="$3" expect="$4" got=0
  local err="$WORKDIR/stderr.txt"
  echo "=== $name ==="
  sh "$CHECK" "$FIX/$fixture" "$receiver" 2>"$err" || got=$?
  cat "$err" >&2
  # A non-zero exit counts only when the checker states the reason the
  # scenario is about; any other cause (a crash, a missing tool) is
  # reported as `<code>(untagged)` and cannot match the expectation.
  case "$got" in
    1) grep -q 'REJECTED \[peer-verification PROTOCOL.md §3.12\]' "$err" || got="1(untagged)" ;;
    2) grep -q 'empty or unparseable' "$err" || got="2(untagged)" ;;
  esac
  record "$name" "$expect" "$got"
  echo
}

run "PV1 peer's [E] adopted with no artifact read of the receiver's own"        pv1-horizontal-inheritance.jsonl implementer 1
run "PV2 two agreeing peers, receiver claims [E] with no artifact trace"        pv2-consensus.jsonl             deployer    1
run "PV3 receiver re-runs the sender's canonical git show (§3.1 form, allowed)" pv3-canonical-reread.jsonl      reviewer    0
run "PV4 receiver verifies the same artifact by a different method"            pv4-independent-method.jsonl    reviewer    0
run "PV5 receiver's only read of the artifact is truncated (head -5)"          pv5-narrowed-read.jsonl         reviewer    1
run "PV6 same artifact, same sender, receiver reads it in full"                pv6-full-read.jsonl             reviewer    0
run "PV7 empty transcript is invalid input, not a clean run (§4.1)"            pv7-empty.jsonl                 reviewer    2
run "PV8 unparseable transcript is invalid input, not a clean run (§4.1)"      pv8-corrupt.jsonl               reviewer    2

echo "=== Results ==="
for r in "${RESULTS[@]}"; do echo "$r"; done
echo
echo "PASS=$PASS FAIL=$FAIL"
echo "peer-unverified events logged: $(wc -l < "$PEER_LOG" | tr -d ' ') -> $PEER_LOG"

[ "$FAIL" -eq 0 ] || exit 1
