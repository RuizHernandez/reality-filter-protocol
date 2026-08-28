#!/usr/bin/env bash
# Synthetic validation of the two domain-skill gates:
#   validation/lib/secret_scan_check.sh          (cybersecurity §2.3)
#   validation/lib/dependency_manifest_check.sh  (computational-arch §2.2)
#
# Every PASS/FAIL below is the exit code of an actual invocation of a checker
# against a fixture -- not a prediction, and not a comparison of two string
# literals. Same standard as replay_incident.sh and peer_verification_suite.sh.
#
# What this validates: that each checker accepts the compliant shapes and
# rejects the non-compliant ones, including the false-positive shapes a
# scanner has to stay quiet about (environment indirection, documentation
# placeholders) because a gate that cries wolf gets switched off.
#
# What it does NOT validate: that any LLM agent obeys either skill, that a
# flagged string is a live credential, that an unflagged file has no secret,
# or that an existing package is the right or safe one. Existence and shape
# are the floor. See REPORT.md.
#
# Package resolution is injected (RFP_PKG_RESOLVER) so the suite exercises the
# real decision logic deterministically without network: a gate whose tests
# need the internet stops running the first time CI is offline.
#
# Usage: skill_gates_suite.sh [scratch-workdir]
set -u

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
SECRET="$SELF_DIR/lib/secret_scan_check.sh"
DEPS="$SELF_DIR/lib/dependency_manifest_check.sh"
SFIX="$SELF_DIR/fixtures/secrets"
MFIX="$SELF_DIR/fixtures/manifests"
WORKDIR="${1:-$(mktemp -d "${TMPDIR:-/tmp}/rfp-gates-XXXXXX")}"
mkdir -p "$WORKDIR"

export RFP_PKG_RESOLVER="sh $MFIX/fake-resolver.sh"

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
  # run <label> <checker> <arg> <expected-exit>
  local name="$1" checker="$2" arg="$3" expect="$4" got=0
  echo "=== $name ==="
  sh "$checker" "$arg" || got=$?
  record "$name" "$expect" "$got"
  echo
}

# --- secret scanner: must reject ------------------------------------------
run "SG1 AWS access key id is a credential" \
    "$SECRET" "$SFIX/s1-aws-key.txt" 1
run "SG2 PEM private key block is a credential" \
    "$SECRET" "$SFIX/s2-private-key.txt" 1
run "SG3 hardcoded password in a JSON-shaped config is a credential" \
    "$SECRET" "$SFIX/s6-hardcoded-password.txt" 1

# --- secret scanner: must stay quiet --------------------------------------
# These are the shapes a correct codebase is full of. A scanner that flags
# them teaches people to ignore it, which costs more than its misses.
run "SG4 environment indirection is not a secret" \
    "$SECRET" "$SFIX/s3-env-indirection.txt" 0
run "SG5 documentation placeholder is not a secret" \
    "$SECRET" "$SFIX/s4-doc-placeholder.txt" 0
run "SG6 ordinary config with no credential is clean" \
    "$SECRET" "$SFIX/s5-clean-config.txt" 0

# --- dependency existence -------------------------------------------------
run "SG7 requirements.txt naming only real packages passes" \
    "$DEPS" "$MFIX/m1-requirements-valid.txt" 0
run "SG8 requirements.txt naming a nonexistent package is rejected" \
    "$DEPS" "$MFIX/m2-requirements-hallucinated.txt" 1
run "SG9 package.json naming only real packages passes" \
    "$DEPS" "$MFIX/m3-package.json" 0
run "SG10 package.json naming a nonexistent package is rejected" \
    "$DEPS" "$MFIX/m4-hallucinated-package.json" 1
# Comments, -r includes, --index-url, extras and environment markers are not
# package names; a parser that reads them as such reports failures that are
# artifacts of its own parsing.
run "SG11 comments, options, extras and markers are not package names" \
    "$DEPS" "$MFIX/m5-requirements-messy.txt" 0

# --- input validity is not a clean run ------------------------------------
# Both checkers must distinguish "nothing wrong" from "could not look",
# exactly as peer_verification_suite.sh's PV7/PV8 do.
echo "=== SG12 missing file is invalid input, not a clean scan ==="
got=0; sh "$SECRET" "$WORKDIR/does-not-exist.txt" >/dev/null 2>&1 || got=$?
record "SG12 missing file is invalid input, not a clean scan" 2 "$got"
echo

echo "=== SG13 unsupported manifest type is invalid input, not a clean run ==="
printf 'x\n' > "$WORKDIR/Gemfile"
got=0; sh "$DEPS" "$WORKDIR/Gemfile" >/dev/null 2>&1 || got=$?
record "SG13 unsupported manifest type is invalid input, not a clean run" 2 "$got"
echo

printf '%s\n' "${RESULTS[@]}"
echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
