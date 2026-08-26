#!/usr/bin/env bash
# Fails if PROTOCOL.md's declared release version is not consistent with
# LINEAGE.md's latest changelog entry and each first-party adapter's
# "synced to" marker. Catches the drift LINEAGE.md itself has documented
# twice: a release or adapter resync merged to main while still described
# as "proposed" / "pending sign-off".
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0

protocol_version=$(grep -oP 'This file is \*\*release `v\K[0-9]+\.[0-9]+\.[0-9]+' PROTOCOL.md | head -1)
if [[ -z "$protocol_version" ]]; then
  echo "FAIL: could not find a 'This file is **release \`vX.Y.Z\`**' line in PROTOCOL.md"
  exit 1
fi
echo "PROTOCOL.md declares release: v$protocol_version"

# Adapters quote PROTOCOL.md's §1-5 rule text, not its bibliography or
# changelog prose. A release that only touches citations/changelog (per
# its own "rule text unchanged since vX.Y.Z" annotation) doesn't obligate
# every adapter to bump its "synced to" marker — only releases that
# actually change §1-5 do. Default to the release version itself when no
# such annotation is present.
rules_version=$(grep -oP 'rule text §1–§5 unchanged since `v\K[0-9]+\.[0-9]+\.[0-9]+' PROTOCOL.md | head -1)
rules_version="${rules_version:-$protocol_version}"
echo "Adapters must be synced to (rules-affecting) version: v$rules_version"

# LINEAGE.md: the last "## Release `vX.Y.Z`" heading is the latest one
# (entries are appended chronologically). It must match PROTOCOL.md's
# declared version and must not still be marked "proposed".
lineage_line=$(grep -E '^## Release `v[0-9]+\.[0-9]+\.[0-9]+`' LINEAGE.md | tail -1)
lineage_version=$(sed -E 's/^## Release `v([0-9]+\.[0-9]+\.[0-9]+)`.*/\1/' <<<"$lineage_line")

if [[ "$lineage_version" != "$protocol_version" ]]; then
  echo "FAIL: LINEAGE.md's latest release heading is v$lineage_version, PROTOCOL.md declares v$protocol_version"
  fail=1
elif [[ "$lineage_line" == *proposed* ]]; then
  echo "FAIL: LINEAGE.md still marks v$lineage_version as 'proposed', but PROTOCOL.md already declares it as the current release — update the wording to match what's actually on main"
  fail=1
else
  echo "OK: LINEAGE.md latest release (v$lineage_version) matches PROTOCOL.md and is not marked proposed"
fi

# README.md declares its own copy of the release version (separately
# from PROTOCOL.md's Status line) — same drift risk, same fix.
readme_version=$(tr '\n' ' ' <README.md | grep -oP '\*\*Release\s+version:\*\* `v\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if [[ -z "$readme_version" ]]; then
  echo "FAIL: could not find a '**Release version:** \`vX.Y.Z\`' line in README.md"
  fail=1
elif [[ "$readme_version" != "$protocol_version" ]]; then
  echo "FAIL: README.md declares release v$readme_version, PROTOCOL.md declares v$protocol_version"
  fail=1
else
  echo "OK: README.md release version matches PROTOCOL.md (v$readme_version)"
fi

# PROTOCOL.md's own "Changelog (vX.Y.Z, proposed)" line has the same
# failure mode: it can lag behind the "Status" line above it.
if grep -qE "Changelog \(v$protocol_version, proposed\)" PROTOCOL.md; then
  echo "FAIL: PROTOCOL.md's own changelog entry for v$protocol_version is still marked '(proposed)' while the Status line above declares it as the current release"
  fail=1
fi

# Any other LINEAGE.md section header still marked "proposed" for a date
# that is not the newest entry is stale by construction; surface it so a
# human decides rather than silently pass.
stale_proposed=$(grep -nE '^## .*— proposed' LINEAGE.md | grep -v "$lineage_line" || true)
if [[ -n "$stale_proposed" ]]; then
  echo "FAIL: LINEAGE.md has other sections still marked 'proposed' — verify these against actual merge state:"
  echo "$stale_proposed"
  fail=1
fi

# First-party adapters (excludes gemini-cli/*, which are domain skills,
# not protocol-core adapters, and carry no PROTOCOL.md version marker).
adapters=(
  "adapters/claude-code/SKILL.md"
  "adapters/cursor/reality-filter.mdc"
  "adapters/antigravity/SKILL.md"
)

for adapter in "${adapters[@]}"; do
  if [[ ! -f "$adapter" ]]; then
    echo "FAIL: expected adapter file missing: $adapter"
    fail=1
    continue
  fi
  if grep -q "v$rules_version" "$adapter"; then
    echo "OK: $adapter references v$rules_version"
  else
    echo "FAIL: $adapter does not mention v$rules_version anywhere (stale sync?)"
    fail=1
  fi
done

if [[ "$fail" -ne 0 ]]; then
  echo
  echo "sync-check FAILED — PROTOCOL.md, LINEAGE.md, and/or an adapter have drifted apart."
  exit 1
fi

echo
echo "sync-check passed."
