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
# `|| true`: the annotation is absent by design on a release that DOES change
# §1-§5 rule text. Without it, `set -euo pipefail` aborted the whole script
# with no message the first time such a release came along (v1.4.0).
rules_version=$(grep -oP 'rule text §1–§5 unchanged since `v\K[0-9]+\.[0-9]+\.[0-9]+' PROTOCOL.md | head -1 || true)
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

# Every file that carries a "PROTOCOL.md vX.Y.Z" marker. The gemini-cli
# skills are domain specializations rather than protocol-core adapters, but
# they DO carry a version footer -- an earlier version of this comment
# asserted they did not, which is how both of them sat at v1.2.0 through two
# releases without CI noticing.
adapters=(
  "adapters/claude-code/SKILL.md"
  "adapters/cursor/reality-filter.mdc"
  "adapters/antigravity/SKILL.md"
  "adapters/gemini-cli/bio-ruiz-hernandez/SKILL.md"
  "adapters/gemini-cli/numerical-data-analysis/SKILL.md"
  "adapters/gemini-cli/computational-arch/SKILL.md"
  "adapters/gemini-cli/cybersecurity/SKILL.md"
)

# README.es.md carries its own release marker and was two releases behind
# (v1.2.0 at v1.3.1) because this script only ever looked at README.md.
es_version=$(tr '\n' ' ' <README.es.md | grep -oP '\*\*Versión de la release:\*\* `v\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if [[ -z "$es_version" ]]; then
  echo "FAIL: could not find a '**Versión de la release:** \`vX.Y.Z\`' line in README.es.md"
  fail=1
elif [[ "$es_version" != "$protocol_version" ]]; then
  echo "FAIL: README.es.md declares release v$es_version, PROTOCOL.md declares v$protocol_version"
  fail=1
else
  echo "OK: README.es.md release version matches PROTOCOL.md (v$es_version)"
fi

# Citation metadata drifts the same way and is what Zenodo/GitHub actually mint.
cff_version=$(grep -oP '^version:\s*\K[0-9]+\.[0-9]+\.[0-9]+' CITATION.cff | head -1)
if [[ "$cff_version" != "$protocol_version" ]]; then
  echo "FAIL: CITATION.cff declares version ${cff_version:-<none>}, PROTOCOL.md declares v$protocol_version"
  fail=1
else
  echo "OK: CITATION.cff version matches PROTOCOL.md ($cff_version)"
fi

zen_version=$(grep -oP '"version"\s*:\s*"\K[0-9]+\.[0-9]+\.[0-9]+' .zenodo.json | head -1)
if [[ "$zen_version" != "$protocol_version" ]]; then
  echo "FAIL: .zenodo.json declares version ${zen_version:-<none>}, PROTOCOL.md declares v$protocol_version"
  fail=1
else
  echo "OK: .zenodo.json version matches PROTOCOL.md ($zen_version)"
fi

# Scenario counts: prose in PROTOCOL.md/LINEAGE.md drifted from what the
# harness actually printed (11 vs 13) because nothing cross-checked them.
# Checking that the right count appears SOMEWHERE is not enough -- that still
# passes while a stale count sits next to it. So: collect every "N/N" the
# docs assert, and require each one to be a count some run log actually
# produced. A stale "11/11" then fails no matter where it hides.
# Corollary the docs must respect: the "N/N" form is reserved for scenario
# counts. Write other ratios as "N of N" so they are not read as one, and
# write scenario counts numerically: a count spelled as a word is invisible here.
valid_counts=""
for logfile in validation/replay_run_2026-08-05.log validation/peer_run_2026-08-26.log validation/gates_run_2026-08-27.log; do
  if [[ ! -f "$logfile" ]]; then
    echo "FAIL: expected run log missing: $logfile"
    fail=1
    continue
  fi
  logged=$(grep -c '^PASS |' "$logfile" || true)
  declared=$(grep -oP '^PASS=\K[0-9]+' "$logfile" | head -1 || true)
  if [[ "$logged" != "$declared" ]]; then
    echo "FAIL: $logfile is internally inconsistent: $logged PASS lines but reports PASS=$declared"
    fail=1
    continue
  fi
  valid_counts="$valid_counts $logged"
done
echo "Run logs report passing scenario counts:$valid_counts"

# TRIAL.md sat outside this list and kept asserting a stale count through the
# whole v1.4.0 sweep. A word-form guard ("eleven ... scenarios") was written
# and then dropped: it cannot tell a total from a delta ("two composed-hook
# regression scenarios were added") or from prose quoting the corrected error,
# and a check that cries wolf is a check someone switches off. Widening the
# file list is the half that actually holds.
asserted=$(grep -ohP '\b([0-9]+)/\1\b' PROTOCOL.md LINEAGE.md validation/REPORT.md validation/live-agent-trial-1/TRIAL.md | sort -u || true)
for a in $asserted; do
  n="${a%%/*}"
  if ! printf '%s' "$valid_counts" | grep -qw "$n"; then
    echo "FAIL: docs assert '$a' scenarios, but no run log reports $n passing scenarios (valid:$valid_counts)"
    fail=1
  fi
done
if [[ "$fail" -eq 0 ]]; then
  echo "OK: every N/N scenario count asserted in the docs matches a real run log"
fi

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
