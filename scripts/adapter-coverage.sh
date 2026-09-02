#!/usr/bin/env bash
# Adapter coverage matrix: every first-party adapter must carry the core
# elements of PROTOCOL.md, or have the omission registered with a reason in
# scripts/adapter-coverage.tsv. sync-check.sh verifies that an adapter
# MENTIONS the current version; this script verifies that adapters mention
# the same RULES. The v1.5.0 audit found adapters green in CI while silently
# dropping the mandatory correction format, the no-unsolicited-rewrites rule,
# and sections 4-5 of the protocol -- drift a version-string grep cannot see.
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0

# element <TAB> case-insensitive anchor regex
ELEMENTS=$(cat <<'EOF'
anti-sycophancy	Anti-Sycophancy
no-unsolicited-rewrites	unsolicited.rewrite
evidence-labels	Empirical
correction-format	Correction:
evidence-decay	evidence decay
peer-verification	§3\.12
defense-in-depth	Defense-in-depth|§4
evaluator-immunity	[Ee]valuator-immunity
session-handoff	§6|handoff
EOF
)

ADAPTERS=(
  adapters/claude-code/SKILL.md
  adapters/cursor/reality-filter.mdc
  adapters/antigravity/SKILL.md
  adapters/kimi/SKILL.md
  adapters/github-copilot/copilot-instructions.md
)

REG="scripts/adapter-coverage.tsv"
registered=""
while IFS=$'\t' read -r adapter element reason; do
  case "${adapter:-}" in ''|\#*) continue ;; esac
  if [ -z "${reason:-}" ]; then
    echo "FAIL: coverage registry entry '$adapter / $element' has no reason"
    fail=1
    continue
  fi
  registered="${registered}${adapter}	${element}"$'\n'
done < "$REG"

echo "== Adapter coverage matrix =="
for adapter in "${ADAPTERS[@]}"; do
  if [ ! -f "$adapter" ]; then
    echo "FAIL: adapter missing: $adapter"
    fail=1
    continue
  fi
  while IFS=$'\t' read -r element anchor; do
    [ -n "$element" ] || continue
    if grep -qiE "$anchor" "$adapter"; then
      if printf '%s' "$registered" | grep -qF "${adapter}	${element}"; then
        echo "FAIL: $adapter carries '$element' but it is registered as omitted -- remove the stale exemption"
        fail=1
      else
        echo "OK: $adapter carries '$element'"
      fi
    else
      if printf '%s' "$registered" | grep -qF "${adapter}	${element}"; then
        echo "OMITTED (registered): $adapter / $element"
      else
        echo "FAIL: $adapter lacks '$element' (anchor: $anchor) and no omission is registered in $REG"
        fail=1
      fi
    fi
  done <<< "$ELEMENTS"
done

# A registry entry for an adapter that no longer exists is stale debt.
while IFS=$'\t' read -r adapter element reason; do
  case "${adapter:-}" in ''|\#*) continue ;; esac
  [ -f "$adapter" ] || { echo "FAIL: $REG registers an omission for missing file $adapter"; fail=1; }
done < "$REG"

if [ "$fail" -ne 0 ]; then
  echo "adapter-coverage FAILED"
  exit 1
fi
echo "adapter-coverage passed"
