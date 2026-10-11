#!/usr/bin/env bash
# Verifies the documentary-support ledger (scripts/claim-support.tsv) for the
# quantitative claims PROTOCOL.md attributes to its citations.
#
# scripts/check-citations.sh establishes that a cited source EXISTS. It cannot
# see the case where a real, correctly identified paper is cited for a figure
# it does not state. This script covers that second question -- does the
# source SAY it? -- and deliberately not a third one: whether what the source
# says is TRUE. No status here certifies truth, and the output says so.
#
#   ./scripts/check-claim-support.sh            # structural, offline (CI default)
#   ./scripts/check-claim-support.sh --online   # also re-read each arXiv abstract
#                                               # and query Crossref for
#                                               # retractions/corrections
#
# FAILS on: a quantitative token in PROTOCOL.md's bibliography section that no
# ledger row covers; a ledger claim_text that is no longer verbatim in
# PROTOCOL.md; an unknown status; a checked row missing version, locator, date
# or method; a PARTIAL/NOT_SUPPORTED/CONTRADICTED row with no note; any
# NOT_SUPPORTED or CONTRADICTED row (the document asserts what its source does
# not); and, online, a retraction notice. PARTIAL and NOT_CHECKED rows are
# reported as visible debt, the convention check-citations.sh uses for
# id_type=none.
#
# Test seams: RFP_CLAIM_DOC, RFP_CLAIM_LEDGER, RFP_CITATIONS override the three
# input files so the suite can exercise failure shapes on synthetic inputs.
set -uo pipefail
cd "$(dirname "$0")/.."

ONLINE=0
[ "${1:-}" = "--online" ] && ONLINE=1

DOC="${RFP_CLAIM_DOC:-PROTOCOL.md}"
LEDGER="${RFP_CLAIM_LEDGER:-scripts/claim-support.tsv}"
CITES="${RFP_CITATIONS:-scripts/citations.tsv}"

for f in "$DOC" "$LEDGER" "$CITES"; do
  [ -f "$f" ] || { echo "check-claim-support: missing input $f" >&2; exit 2; }
done

fail=0
debt=0
supported=0

# The bibliography section: from its heading to the end of the file.
section=$(tr -d '\r' < "$DOC" | sed -n '/^## Grounded in research/,$p')
[ -n "$section" ] || { echo "check-claim-support: no '## Grounded in research' section in $DOC" >&2; exit 2; }
doc_flat=$(tr -d '\r' < "$DOC")

known_citations=$'\n'
while IFS=$'\t' read -r surname _rest; do
  case "${surname:-}" in ''|\#*) continue ;; esac
  known_citations="${known_citations}${surname}"$'\n'
done < <(tr -d '\r' < "$CITES")

# Quantitative tokens: percentages (53.9%, 40%) and thousands-grouped counts
# (41,832). A bare small integer ("12 models") is not caught -- stated
# limitation, not an exemption.
quant_re='[0-9]+(\.[0-9]+)?%|[0-9]{1,3}(,[0-9]{3})+'

# Rows are read with \037 (unit separator) as the field delimiter. Tab is IFS
# whitespace to bash: consecutive tabs collapse, an EMPTY field vanishes, and
# every later column shifts left -- a SUPPORTED row with no method read the
# note into `method` and passed. The suite's AU-C5 caught that.
ledger_rows() { tr -d '\r' < "$LEDGER" | tr '\t' '\037'; }

covered_text=""
echo "== Ledger rows =="
while IFS=$'\037' read -r id cit text status ver loc date method note; do
  case "${id:-}" in ''|\#*) continue ;; esac
  covered_text="${covered_text}${text}"$'\n'
  case "$status" in
    SUPPORTED|PARTIAL|NOT_SUPPORTED|CONTRADICTED|NOT_CHECKED) ;;
    *) echo "FAIL: $id has unknown status '$status'"; fail=1; continue ;;
  esac
  if [[ $known_citations != *$'\n'"$cit"$'\n'* ]]; then
    echo "FAIL: $id cites '$cit', which is not in $CITES"; fail=1
  fi
  if [[ $doc_flat != *"$text"* ]]; then
    echo "FAIL: $id claim_text is no longer verbatim in $DOC -- re-check the source against the new wording: \"$text\""
    fail=1
  fi
  if [ "$status" != NOT_CHECKED ]; then
    if [ -z "${ver:-}" ] || [ -z "${loc:-}" ] || [ -z "${method:-}" ] \
       || ! [[ ${date:-} =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
      echo "FAIL: $id is $status but lacks source_version, locator, method or an ISO checked_on date -- a check that cannot be repeated is not a check"
      fail=1
    fi
  fi
  case "$status" in
    PARTIAL|NOT_SUPPORTED|CONTRADICTED)
      [ -n "${note:-}" ] || { echo "FAIL: $id is $status with no note saying what differs"; fail=1; } ;;
  esac
  case "$status" in
    SUPPORTED)     echo "SUPPORTED: $id ($cit, $ver, $loc) -- the source states it; not a certification that it is true"; supported=$((supported+1)) ;;
    PARTIAL)       echo "PARTIAL: $id ($cit, $ver) -- $note"; debt=$((debt+1)) ;;
    NOT_CHECKED)   echo "NOT_CHECKED: $id ($cit) -- no passage located yet (visible debt)"; debt=$((debt+1)) ;;
    NOT_SUPPORTED) echo "FAIL: $id ($cit, $ver) NOT_SUPPORTED -- $note"; fail=1 ;;
    CONTRADICTED)  echo "FAIL: $id ($cit, $ver) CONTRADICTED -- $note"; fail=1 ;;
  esac
done < <(ledger_rows)

echo "== Coverage of quantitative claims in '$DOC' (Grounded in research) =="
while IFS= read -r tok; do
  [ -n "$tok" ] || continue
  if [[ $covered_text == *"$tok"* ]]; then
    echo "OK: $tok is covered by a ledger row"
  else
    echo "FAIL: '$tok' is asserted in the bibliography section but no ledger row covers it"
    fail=1
  fi
done < <(printf '%s\n' "$section" | grep -oE "$quant_re" | sort -u)

if [ "$ONLINE" -eq 1 ]; then
  echo "== Online re-read (reports drift; never upgrades a status by itself) =="
  while IFS=$'\037' read -r id cit text status ver _rest; do
    case "${id:-}" in ''|\#*) continue ;; esac
    idtype=$(tr -d '\r' < "$CITES" | awk -F'\t' -v s="$cit" '$1==s {print $3; exit}')
    pid=$(tr -d '\r' < "$CITES" | awk -F'\t' -v s="$cit" '$1==s {print $4; exit}')
    case "$idtype" in
      arxiv)
        xml=$(curl -sS --max-time 30 "https://export.arxiv.org/api/query?id_list=$pid" 2>/dev/null | tr -d '\r' | tr '\n' ' ')
        if [ -z "$xml" ]; then echo "UNVERIFIABLE: $id arXiv:$pid did not respond"; continue; fi
        latest=$(printf '%s' "$xml" | grep -oE "arxiv.org/abs/$pid"'v[0-9]+' | head -1 | sed 's#.*/abs/##')
        if [ -z "$latest" ]; then
          echo "UNVERIFIABLE: $id arXiv:$pid -- no version found in the API response"; continue
        elif [[ $ver != *"$latest"* ]]; then
          echo "VERSION DRIFT: $id was checked against $ver; latest is $latest -- re-check"
        fi
        # Only the comment field: "withdrawn" in an abstract is not a notice.
        if printf '%s' "$xml" | sed -n 's:.*<arxiv\:comment[^>]*>\(.*\)</arxiv\:comment>.*:\1:p' | grep -qi 'withdrawn'; then
          echo "FAIL: $id arXiv:$latest carries a withdrawal notice"; fail=1
        fi
        abstract=$(printf '%s' "$xml" | sed -n 's:.*<summary>\(.*\)</summary>.*:\1:p')
        for tok in $(printf '%s' "$text" | grep -oE "$quant_re"); do
          if [[ $abstract == *"$tok"* ]]; then
            echo "OK: $id '$tok' appears in the $latest abstract"
          else
            echo "NOT IN ABSTRACT: $id '$tok' -- may be in the full text; status unchanged"
          fi
        done
        ;;
      doi)
        n=$(curl -sS --max-time 30 "https://api.crossref.org/works?filter=updates:$pid&rows=0" 2>/dev/null \
            | grep -oE '"total-results":[0-9]+' | grep -oE '[0-9]+$')
        if [ -z "$n" ]; then
          echo "UNVERIFIABLE: $id Crossref did not answer for doi:$pid"
        elif [ "$n" -gt 0 ]; then
          echo "FAIL: $id doi:$pid has $n Crossref update notice(s) (correction/retraction) -- read them before citing"
          fail=1
        else
          echo "OK: $id doi:$pid has no Crossref correction/retraction notice (absence in Crossref, not proof of none)"
        fi
        ;;
      *) echo "UNVERIFIABLE: $id ($cit) has id_type '$idtype'; no online re-read available" ;;
    esac
  done < <(ledger_rows)
fi

echo
echo "Existence of a source (check-citations.sh) != documentary support (this check) != truth (not certified)."
if [ "$fail" -ne 0 ]; then
  echo "check-claim-support FAILED (supported: $supported, debt: $debt)."
  exit 1
fi
echo "check-claim-support passed (supported: $supported, debt: $debt)."
