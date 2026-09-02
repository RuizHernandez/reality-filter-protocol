#!/usr/bin/env bash
# Verifies PROTOCOL.md's bibliography against scripts/citations.tsv, in both
# directions, and (with --online) against the actual resolvers.
#
# A protocol whose first rule is "verify against the source before asserting"
# should not ship a bibliography nobody re-checked. This makes the check a
# build step instead of a good intention.
#
#   ./scripts/check-citations.sh            structural, offline, deterministic (CI default)
#   ./scripts/check-citations.sh --online   also resolves every id and matches its title
#
# Offline mode FAILS on: a citation in PROTOCOL.md missing from the inventory,
# an inventory entry missing from PROTOCOL.md, a malformed identifier, or an
# id_type=none entry with no note explaining it. Unresolved-but-documented
# citations are reported as UNRESOLVED on every run — visible debt, not a pass.
set -uo pipefail
cd "$(dirname "$0")/.."

ONLINE=0
[ "${1:-}" = "--online" ] && ONLINE=1

INV="scripts/citations.tsv"
PROTO="PROTOCOL.md"
fail=0
unresolved=0

[ -f "$INV" ]   || { echo "FAIL: missing $INV"; exit 1; }
[ -f "$PROTO" ] || { echo "FAIL: missing $PROTO"; exit 1; }

# The bibliography section only — the changelog above it mentions authors too.
BIB=$(awk '/^## Grounded in research/{f=1} f' "$PROTO")
[ -n "$BIB" ] || { echo "FAIL: could not locate the '## Grounded in research' section in $PROTO"; exit 1; }

# Surnames cited in prose: "X et al." and "X (YYYY)" / "X (VENUE YYYY)".
cited=$(printf '%s' "$BIB" \
  | grep -oE '\b[A-Z][A-Za-z]+ et al\.|\b[A-Z][A-Za-z]+ \(([A-Za-z]+ )?(19|20)[0-9]{2}[,)]' \
  | sed -E 's/ et al\.$//; s/ \(.*$//' | sort -u)

inv_names=$(grep -v '^#' "$INV" | awk -F'\t' 'NF{print $1}' | sort -u)

echo "== Structural check =="
for name in $cited; do
  if ! printf '%s\n' "$inv_names" | grep -qx "$name"; then
    echo "FAIL: $PROTO cites '$name' but $INV has no entry for it"
    fail=1
  fi
done
for name in $inv_names; do
  if ! printf '%s\n' "$cited" | grep -qx "$name"; then
    echo "FAIL: $INV lists '$name' but $PROTO's bibliography no longer cites it (stale inventory entry)"
    fail=1
  fi
done
echo "cited in PROTOCOL.md: $(printf '%s\n' "$cited" | grep -c .) | inventory entries: $(printf '%s\n' "$inv_names" | grep -c .)"

echo
echo "== Identifier check =="
while IFS=$'\t' read -r surname year idtype id frag note; do
  case "${surname:-}" in ''|\#*) continue ;; esac
  case "$idtype" in
    none)
      if [ -z "${note:-}" ] || ! printf '%s' "$note" | grep -q 'UNRESOLVED'; then
        echo "FAIL: $surname ($year) has no identifier and no note marking it UNRESOLVED"
        fail=1
      else
        echo "UNRESOLVED: $surname ($year) — ${note#UNRESOLVED: }"
        unresolved=$((unresolved+1))
      fi
      continue
      ;;
    arxiv)
      if ! printf '%s' "$id" | grep -qE '^[0-9]{4}\.[0-9]{4,5}(v[0-9]+)?$'; then
        echo "FAIL: $surname — malformed arXiv id '$id'"; fail=1; continue
      fi
      ;;
    doi)
      if ! printf '%s' "$id" | grep -qE '^10\.[0-9]{4,9}/[^[:space:]]+$'; then
        echo "FAIL: $surname — malformed DOI '$id'"; fail=1; continue
      fi
      ;;
    rfc)
      # IETF RFCs are the primary literature for large parts of computer
      # systems and carry no DOI in general use. IEEE and ACM need no separate
      # type: their DOIs resolve through Crossref like any other (the
      # Wooldridge AAMAS citation above is an ACM DOI).
      if ! printf '%s' "$id" | grep -qE '^[0-9]{1,5}$'; then
        echo "FAIL: $surname — malformed RFC number '$id' (expected digits only, e.g. 8446)"; fail=1; continue
      fi
      ;;
    *)
      echo "FAIL: $surname — unknown id_type '$idtype'"; fail=1; continue
      ;;
  esac

  # The identifier must also actually appear in PROTOCOL.md, or the inventory
  # is describing a citation the document does not make.
  if ! grep -qiF "$id" "$PROTO"; then
    echo "FAIL: $surname — id '$id' is in the inventory but not in $PROTO"
    fail=1
    continue
  fi

  if [ "$ONLINE" -eq 0 ]; then
    echo "OK (offline): $surname — $idtype:$id well-formed and present in $PROTO"
    continue
  fi

  # Online resolution is cached for 7 days: a weekly CI cron plus pre-commit
  # runs would otherwise re-hit arXiv/Crossref/Datatracker for identifiers
  # whose resolved titles cannot change, and a check that rate-limits its
  # author is a check that gets switched off.
  CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/rfp-citations"
  mkdir -p "$CACHE_DIR"
  cache_file="$CACHE_DIR/${idtype}_${id}"
  title=""
  if [ -f "$cache_file" ] && [ -n "$(find "$cache_file" -mtime -7 2>/dev/null)" ]; then
    title=$(cat "$cache_file")
  fi
  if [ -z "$title" ]; then
  if [ "$idtype" = "arxiv" ]; then
    title=$(curl -sSL --max-time 30 "https://export.arxiv.org/api/query?id_list=$id" 2>/dev/null \
      | python3 -c "import re,sys;t=re.findall(r'<title>(.*?)</title>',sys.stdin.read(),re.S);print(' '.join(t[1].split()) if len(t)>1 else '')" 2>/dev/null)
  elif [ "$idtype" = "rfc" ]; then
    # IETF Datatracker. Parsed with python3 rather than jq so that adding RFC
    # support does not add a dependency the offline path never needed --
    # python3 is already required above for the arXiv branch.
    title=$(curl -sSL --max-time 30 "https://datatracker.ietf.org/api/v1/doc/document/rfc$id/?format=json" 2>/dev/null \
      | python3 -c "import json,sys;print(json.load(sys.stdin).get('title',''))" 2>/dev/null)
  else
    title=$(curl -sS --max-time 30 "https://api.crossref.org/works/$id" \
      -H 'User-Agent: rfp-citation-check/1.0 (mailto:noreply@example.org)' 2>/dev/null \
      | jq -r '.message.title[0] // ""' 2>/dev/null)
  fi

    [ -n "$title" ] && printf '%s' "$title" > "$cache_file"
  fi

  if [ -z "$title" ]; then
    echo "FAIL: $surname — $idtype:$id did not resolve"
    fail=1
  elif printf '%s' "$title" | grep -qiF "$frag"; then
    echo "OK (online):  $surname — $idtype:$id -> \"$title\""
  else
    echo "FAIL: $surname — $idtype:$id resolves to \"$title\", which does not contain the expected fragment \"$frag\""
    fail=1
  fi
done < "$INV"

echo
if [ "$unresolved" -gt 0 ]; then
  echo "$unresolved citation(s) carry no persistent identifier. They are documented in $INV and reported on every run."
fi
if [ "$fail" -ne 0 ]; then
  echo "check-citations FAILED."
  exit 1
fi
echo "check-citations passed (unresolved: $unresolved)."
