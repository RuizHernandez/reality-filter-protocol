#!/usr/bin/env bash
# Builds the prompt prefixes for the arms beyond A (no protocol) and B (full
# PROTOCOL.md), deterministically from PROTOCOL.md, into arms/:
#
#   C-placebo.md     length-matched filler with no conduct content. B differs
#                    from A in content AND length; C differs from A in length
#                    only, so B vs C isolates content from prompt length --
#                    the confound PROTOCOL-AB.md names as a limitation.
#   ABL-no-s<N>.md   PROTOCOL.md with top-level section N removed (ablation:
#                    B vs ABL-no-sN estimates what section N contributes).
#
# Byte length is matched, not token count: no tokenizer is assumed. The
# residual mismatch is a stated limitation, not a hidden one.
#
# Usage: make_arms.sh            (writes arms/ and prints byte sizes)
set -euo pipefail
cd "$(dirname "$0")"

PROTO=../../PROTOCOL.md
[ -f "$PROTO" ] || { echo "make_arms: $PROTO not found" >&2; exit 2; }
mkdir -p arms
target=$(wc -c < "$PROTO" | tr -d ' ')

# Placebo: a fixed paragraph from an unrelated domain, repeated and cut to
# the protocol's byte length. Nothing in it is about verification, review,
# evidence, agents or honesty.
para='Station log, coastal weather buoy 14. The anemometer cups were cleaned on the morning visit and the vane was realigned to true north against the shore marker. Readings were logged every ten minutes: air temperature, relative humidity, barometric pressure and wind speed at two heights. The tide gauge float was inspected for barnacle growth and the solar panel surface was wiped. Battery voltage held steady through the overcast afternoon. A gull nest on the upper rail was left undisturbed. '
: > arms/C-placebo.md
while [ "$(wc -c < arms/C-placebo.md | tr -d ' ')" -lt "$target" ]; do
  printf '%s\n' "$para" >> arms/C-placebo.md
done
head -c "$target" arms/C-placebo.md > arms/C-placebo.md.tmp && mv arms/C-placebo.md.tmp arms/C-placebo.md

# Ablations: drop one top-level "## N." section (and its subsections) at a
# time. §4-§6 are dropped together: they are operational/defensive, and three
# separate arms would triple the cost of the study for the least central rules.
ablate() {
  # ablate <out> <section numbers to drop...>
  local out="$1"; shift
  awk -v drop=" $* " '
    /^## [0-9]+\./ { n=$2; sub(/\.$/, "", n); skipping = index(drop, " " n " ") > 0 }
    /^## [^0-9]/   { skipping = 0 }
    !skipping
  ' "$PROTO" > "arms/$out"
}
ablate ABL-no-s1.md 1
ablate ABL-no-s2.md 2
ablate ABL-no-s3.md 3
ablate ABL-no-s4-6.md 4 5 6

for f in arms/*.md; do
  printf '%-22s %8s bytes  sha256 %s\n' "$(basename "$f")" "$(wc -c < "$f" | tr -d ' ')" "$(sha256sum "$f" | cut -c1-16)"
done
printf '%-22s %8s bytes  (reference)\n' "PROTOCOL.md (B)" "$target"
