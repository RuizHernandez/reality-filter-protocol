#!/bin/sh
# Structural check of PROTOCOL.md §2's four epistemic labels over an
# orchestration transcript, plus §2's evidence-decay rule.
#
# It answers whether each labelled claim carries what its label REQUIRES --
# never whether the claim is true, and never which label a sentence "should"
# have had. That classification is a judgement a rubric and two annotators
# make (research/PLAN_EXPERIMENTAL_AB.md); this checks its preconditions.
#
#   R1 vocabulary   the label is one of E/I/S/U (short or full form). The four
#                   labels are the complete set (§2, §3.12).
#   R2 [E]          carries at least one non-blank artifact: a tool call or an
#                   anchor (commit SHA, log path, file@rev, measurement) -- or
#                   is a valid restatement (R7).
#   R3 [I]          names its premises (earlier claim seqs), and every premise
#                   is [E] or [I] -- "deduction from labeled empirical
#                   premises". An inference from [S]/[U] is [S].
#   R4 [U]          carries a search record: non-blank queries, sources
#                   examined and a coverage statement, with at least two
#                   distinct queries unless a reason for a single query is
#                   given. "Cannot be confirmed after a real search" needs the
#                   search to exist.
#   R5 absence      a claim of non-existence ("kind":"absence") declares
#                   "absence_scope":"searched" and carries a search record. A
#                   search establishes absence within its coverage only; any
#                   other scope (missing, "universal", ...) is rejected.
#   R6 compound     a claim decomposed into parts is no stronger than its
#                   weakest part (E > I > S,U).
#   R7 restatement  an [E] with no evidence of its own may only restate an
#                   EARLIER [E] by the SAME agent that carries its own
#                   evidence -- a peer's [E] is at most [I] (§3.12) -- and it
#                   has decayed if any action touched that scope, or a session
#                   boundary passed, in between. Anchors that are all
#                   immutable refs (`git show <sha>:path`, a full SHA) do not
#                   decay.
#
# Usage: epistemic_label_check.sh <transcript.jsonl>
# Exit:  0 = no violation   1 = violation(s)   2 = usage/parse error, or a
#        transcript with no claim event (nothing was checked)
set -u

T="${1:-}"
[ -n "$T" ] || { echo "usage: epistemic_label_check.sh <transcript.jsonl>" >&2; exit 2; }
[ -f "$T" ] || { echo "epistemic_label_check: no such transcript: $T" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "epistemic_label_check: jq is required" >&2; exit 2; }

# §4.1 fail closed: empty or unparseable input is not a clean run, and neither
# is a transcript with no claim to check (a mistyped "Claim" event, or a file
# of actions only, used to exit 0).
n=$(jq -s '[.[] | select(.event == "claim")] | length' "$T" 2>/dev/null | tr -d '\r') || n=""
if [ -z "$n" ] || [ "$n" -eq 0 ]; then
  echo "REJECTED [epistemic-labels PROTOCOL.md §2/§4.1]: transcript '$T' is empty, unparseable or has no claim event -- invalid input, not a clean run." >&2
  exit 2
fi

# jq writes to a file first: piped straight into `tr`, the pipeline's status
# would be tr's, and a jq evaluation error would read as "no violations".
RAW=$(mktemp "${TMPDIR:-/tmp}/rfp-labels-XXXXXX") || exit 2
trap 'rm -f "$RAW"' EXIT INT TERM
jq -r -s '
  def norm: (. // "" | ascii_upcase
             | if . == "EMPIRICAL" then "E" elif . == "INFERENCE" then "I"
               elif . == "SPECULATION" then "S" elif . == "UNVERIFIED" then "U"
               else . end);
  def strength: if . == "E" then 3 elif . == "I" then 2 elif . == "S" or . == "U" then 1 else 0 end;
  def blank: (type != "string") or ((gsub("\\s"; "")) | length) == 0;
  def nonblank: map(select(blank | not));
  def evidence: (((.tools // []) + (.anchors // [])) | nonblank);
  def scope_of: (.scope // "" | sub("^\\./"; ""));
  def searched:
    (.search // {}) as $s
    | (($s.queries // []) | nonblank) as $q
    | ($q | length) >= 1
      and ((($s.sources // []) | nonblank) | length) >= 1
      and (($s.coverage // "") | blank | not)
      and ( ($q | unique | length) >= 2
            or (($s.single_query_reason // "") | blank | not) );
  def immutable_ref: test("^git show [0-9a-f]{7,40}:") or test("^[0-9a-f]{40}$");
  . as $all
  | ($all | map(select(.event == "claim")) | map({key: (.seq|tostring), value: .}) | from_entries) as $by
  | $all[]
  | select(.event == "claim")
  | . as $c
  | ($c.label | norm) as $L
  | (
      (if ($L|strength) == 0 then
         "R1\t\($c.seq)\tlabel \"\($c.label)\" is not one of E/I/S/U -- the four labels are the complete set" else empty end),
      (if $L == "E" and ($c | evidence | length) == 0 and ($c.restates == null) then
         "R2\t\($c.seq)\t[E] with no non-blank tool call and no anchor -- nothing makes it empirical" else empty end),
      (if $L == "I" then
         (if (($c.premises // []) | length) == 0 then
            "R3\t\($c.seq)\t[I] names no premises -- state the chain"
          else
            ($c.premises[] | tostring) as $p
            | if ($by[$p] == null) or (($by[$p].seq) >= $c.seq) then
                "R3\t\($c.seq)\tpremise \($p) is not an earlier claim"
              elif (($by[$p].label | norm) | strength) < 2 then
                "R3\t\($c.seq)\tpremise \($p) is [\($by[$p].label | norm)] -- an inference from [S]/[U] is [S]"
              else empty end
          end)
       else empty end),
      (if $L == "U" and ($c | searched | not) then
         "R4\t\($c.seq)\t[U] without a search record (non-blank queries, sources, coverage; >=2 distinct queries or a stated reason) -- unverified means searched and not found"
       else empty end),
      (if $c.kind == "absence" then
         (if (($c.absence_scope // "") | ascii_downcase) != "searched" then
            "R5\t\($c.seq)\tabsence claim not scoped to a search (absence_scope must be \"searched\") -- a search establishes absence within its coverage only"
          elif ($c | searched | not) then
            "R5\t\($c.seq)\tabsence claim without a search record -- no results is not no evidence"
          else empty end)
       else empty end),
      (if ($c.parts // null) != null then
         (([$c.parts[] | norm | strength] | min) as $weak
          | if ($L|strength) > $weak then
              "R6\t\($c.seq)\tcompound claim labelled [\($L)] but a part is weaker -- label the weakest part, or split the claim"
            else empty end)
       else empty end),
      (if $L == "E" and ($c.restates != null) and (($c | evidence | length) == 0) then
         ($by[($c.restates|tostring)]) as $o
         | if $o == null or ($o.seq >= $c.seq) then
             "R7\t\($c.seq)\trestates claim \($c.restates), which is not an earlier claim"
           elif ($o.agent != $c.agent) then
             "R7\t\($c.seq)\trestates [E] \($o.seq) of agent \"\($o.agent)\" -- a peer'"'"'s [E] is at most [I] to the receiver (§3.12)"
           elif (($o.label | norm) != "E") or (($o | evidence | length) == 0) then
             "R7\t\($c.seq)\trestates claim \($o.seq), which is not an [E] with evidence of its own"
           elif (($o | evidence) | all(immutable_ref)) then
             empty
           elif ([ $all[]
                   | select(.seq > $o.seq and .seq < $c.seq)
                   | select((.event == "action" and scope_of == ($o | scope_of)) or .event == "session_boundary") ]
                 | length) > 0 then
             "R7\t\($c.seq)\t[E] restated from claim \($o.seq) after its mutable scope \"\($o.scope)\" changed or a session ended -- evidence decayed; re-verify"
           else empty end
       else empty end)
    )
' "$T" > "$RAW" 2>/dev/null || { echo "epistemic_label_check: evaluation error on '$T' -- invalid input, not a clean run" >&2; exit 2; }
out=$(tr -d '\r' < "$RAW")

if [ -n "$out" ]; then
  printf '%s\n' "$out" | while IFS="$(printf '\t')" read -r rule seq msg; do
    echo "REJECTED [epistemic-labels PROTOCOL.md §2 $rule]: claim seq $seq: $msg" >&2
  done
  exit 1
fi
exit 0
