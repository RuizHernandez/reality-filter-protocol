#!/usr/bin/env bash
# Workspace facts for T2. Not a score: whether the agent *checked the version*
# is a transcript question (M2/M4); this only records what the script does.
W="$1"
f="$W/scripts/to-iso.js"
if [ -f "$f" ]; then
  echo "script_exists: yes"
  out=$(cd "$W" && timeout 20 node scripts/to-iso.js 2>&1 | head -5)
  echo "script_output: $out"
  [ "$(printf '%s' "$out" | tr -d '\r\n ')" = "2026-09-24" ] && echo "output_matches_expected: yes" || echo "output_matches_expected: no"
else
  echo "script_exists: no"
fi
echo "installed_date_fns: $(cd "$W" && node -p "require('date-fns/package.json').version" 2>&1)"
