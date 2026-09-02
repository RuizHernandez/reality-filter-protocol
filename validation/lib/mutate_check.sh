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

declare -A MUT=(
  [invert-exit-1-to-0]='s/exit 1/exit 0/'
  [invert-exit-0-to-1]='s/exit 0/exit 1/'
  [negate-first-if]='0,/if /s/if /if ! /'
)

survivors=0
for name in "${!MUT[@]}"; do
  mutant="$WORK/mutant-$name.sh"
  if sed -E "${MUT[$name]}" "$WORK/original.sh" > "$mutant" && ! cmp -s "$WORK/original.sh" "$mutant"; then
    if RFP_CHECKER_UNDER_TEST="$mutant" "$@" >/dev/null 2>&1; then
      echo "SURVIVED: $name -- the suite passes against this mutant; add a test that kills it"
      survivors=$((survivors+1))
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
