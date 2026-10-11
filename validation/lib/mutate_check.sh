#!/usr/bin/env bash
# Mutation testing for a validation checker. A suite that every mutant survives
# is not a suite -- it proves nothing about the checker it claims to guard.
#
# Usage: mutate_check.sh <checker-script> <suite-command...>
# Applies a fixed set of controlled syntactic mutations to a scratch copy of
# the checker, exports RFP_CHECKER_UNDER_TEST pointing at the mutant, and runs
# the suite. Exit 0 = every applicable mutant was killed. Exit 1 = a survivor.
set -euo pipefail

CHECKER="${1:-}"; shift || true
[ -n "$CHECKER" ] && [ $# -ge 1 ] || { echo "usage: mutate_check.sh <checker> <suite-command...>" >&2; exit 2; }
[ -f "$CHECKER" ] || { echo "no such checker: $CHECKER" >&2; exit 2; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cp "$CHECKER" "$WORK/original.sh"

# Operators skip comment lines: a mutation that only rewrites a comment is an
# equivalent mutant, and its "survival" was reported as a missing test
# (dependency_manifest_check.sh's "# exit 0 = exists" comment did exactly
# that). `exit-var-to-0` covers checkers that exit through a variable.
declare -A MUT=(
  [invert-exit-1-to-0]='/^[[:space:]]*#/!s/exit 1/exit 0/'
  [invert-exit-0-to-1]='/^[[:space:]]*#/!s/exit 0/exit 1/'
  [negate-first-if]='0,/^[[:space:]]*if /s/^([[:space:]]*)if /\1if ! /'
  [exit-var-to-0]='/^[[:space:]]*#/!s/exit "\$[A-Za-z_]+"/exit 0/'
)

TARGET="$(basename "$CHECKER")"
chmod +x "$WORK/original.sh"

# Baseline: the suite must pass with the UNMUTATED checker substituted the
# same way. If it does not, every mutant would count as "killed" for reasons
# that have nothing to do with the mutation.
base_rc=0
RFP_CHECKER_UNDER_TEST="$WORK/original.sh" RFP_CHECKER_TARGET="$TARGET" "$@" >/dev/null 2>&1 || base_rc=$?
if [ "$base_rc" -ne 0 ]; then
  echo "mutation check INVALID: the suite fails (exit $base_rc) against the unmutated checker substituted via RFP_CHECKER_UNDER_TEST; kills would be meaningless" >&2
  exit 2
fi

survivors=0
for name in "${!MUT[@]}"; do
  mutant="$WORK/mutant-$name.sh"
  if sed -E "${MUT[$name]}" "$WORK/original.sh" > "$mutant" && ! cmp -s "$WORK/original.sh" "$mutant"; then
    chmod +x "$mutant"
    # RFP_CHECKER_TARGET names which checker the mutant replaces, so a suite
    # that runs several checkers substitutes only this one -- and a suite
    # that runs none of that name refuses (exit 2) instead of silently
    # testing the original, which made every mutant "survive".
    rc=0
    RFP_CHECKER_UNDER_TEST="$mutant" RFP_CHECKER_TARGET="$TARGET" "$@" >/dev/null 2>&1 || rc=$?
    if [ "$rc" -eq 0 ]; then
      echo "SURVIVED: $name -- the suite passes against this mutant; add a test that kills it"
      survivors=$((survivors+1))
    elif [ "$rc" -eq 2 ]; then
      echo "mutation check INVALID: suite reported an environment error (exit 2) for mutant $name" >&2
      exit 2
    else
      echo "killed:   $name"
    fi
  else
    echo "skipped:  $name (operator does not apply to this checker)"
  fi
done

if [ "$survivors" -gt 0 ]; then
  echo "mutation check FAILED: $survivors mutant(s) survived"
  exit 1
fi
echo "mutation check passed: every applicable mutant was killed"
