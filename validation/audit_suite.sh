#!/usr/bin/env bash
# Scenarios added by the 2026-10-11 limitations audit (research/). Kept apart
# from replay_incident.sh (13), peer_verification_suite.sh (8) and
# skill_gates_suite.sh (13) so those counts stay comparable with their dated
# run logs.
#
# Every PASS/FAIL is the exit code of a real invocation -- a git commit in a
# disposable repository, or a checker run against a fixture -- and every
# expected rejection must also carry the rejecting control's own tag, so an
# environment failure cannot pass as a control decision.
#
#   AU-H  hooks under adversarial input (paths with spaces, renames, missing
#         checker, closed stderr pipe)                        PROTOCOL.md §3.2/§3.10/§4.1
#   AU-P  peer checker: scope-token match, method dependency   §3.12 (L7)
#   AU-L  epistemic-label structure and evidence decay        §2 (L3, L5)
#   AU-C  documentary support vs existence                    §2 (L2)
#   AU-S  anti-sycophancy transcript linter                    §1
#   AU-AB A/B apparatus: preregistration integrity, blinding,
#         placebo and ablation arms                           (L8, experimental design)
#
# None of this tests an LLM. See research/RESULTADOS_Y_EVIDENCIAS.md.
#
# Usage: audit_suite.sh [scratch-workdir]
set -u

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SELF_DIR/.." && pwd)"
LIB="$SELF_DIR/lib"
HOOKS="$SELF_DIR/hooks"
LABELS="$LIB/epistemic_label_check.sh"
PEER="$LIB/peer_verification_check.sh"
if [ -n "${RFP_CHECKER_UNDER_TEST:-}" ]; then
  case "${RFP_CHECKER_TARGET:-}" in
    epistemic_label_check.sh) LABELS="$RFP_CHECKER_UNDER_TEST" ;;
    peer_verification_check.sh) PEER="$RFP_CHECKER_UNDER_TEST" ;;
    *) echo "ENVIRONMENT ERROR: RFP_CHECKER_TARGET='${RFP_CHECKER_TARGET:-}' is not a checker this suite runs" >&2; exit 2 ;;
  esac
fi
WORKDIR="${1:-$(mktemp -d "${TMPDIR:-/tmp}/rfp-audit-XXXXXX")}"

env_error() { echo "ENVIRONMENT ERROR: $*" >&2; echo "No scenario was evaluated." >&2; exit 2; }
command -v jq >/dev/null 2>&1 || env_error "jq is required"
command -v git >/dev/null 2>&1 || env_error "git is required"
rm -rf "$WORKDIR"; mkdir -p "$WORKDIR" || env_error "cannot create $WORKDIR"
( cd "$WORKDIR" && git init -q probe && git -C probe rev-parse --git-dir >/dev/null 2>&1 ) \
  || env_error "cannot create a git repository under $WORKDIR (on Windows, check path length)"

PASS=0; FAIL=0; RESULTS=()
record() {
  local name="$1" expect="$2" got="$3"
  if [ "$expect" = "$got" ]; then RESULTS+=("PASS | $name | expected=$expect got=$got"); PASS=$((PASS+1))
  else RESULTS+=("FAIL | $name | expected=$expect got=$got"); FAIL=$((FAIL+1)); fi
}
# tagged <exit> <stderr-file> <tag>: a non-zero exit counts only if the
# control named itself.
tagged() {
  if [ "$1" -eq 0 ]; then echo 0
  elif grep -q -- "$3" "$2" 2>/dev/null; then echo "$1"
  else echo "$1(untagged)"; fi
}

new_repo() {
  # new_repo <name> -> prints path; a synthetic repo with one base commit
  local d="$WORKDIR/$1"
  git init -q -b main "$d" || env_error "git init $d"
  git -C "$d" config user.email "audit@validation.local"
  git -C "$d" config user.name "rfp-audit-suite"
  git -C "$d" config core.autocrlf false
  mkdir -p "$d/docs/ux"
  printf '# P2 spec\n## 1. Scope\n' > "$d/docs/ux/P2-impl-notes.md"
  git -C "$d" add -A && AGENT_ROLE=architect git -C "$d" commit -q -m base || env_error "base commit in $d"
  echo "$d"
}
install_hook() { install -m 0755 "$1" "$2" 2>/dev/null && [ -x "$2" ] || env_error "could not install $2"; }
commits() { git -C "$1" rev-list --count HEAD; }

echo "=== AU-H: hooks under adversarial input ==="
FAKE_KEY="AKIA$(printf 'ABCDEFGHIJKLMNOP')"   # shape only; assembled so this file is not itself a match

r=$(new_repo h1); mkdir -p "$r/validation/lib"; cp "$LIB/secret_scan_check.sh" "$r/validation/lib/"
git -C "$r" add -A && git -C "$r" commit -q -m lib
install_hook "$HOOKS/pre-commit-secret-scan.sh" "$r/.git/hooks/pre-commit"
printf 'aws_key = %s\n' "$FAKE_KEY" > "$r/my secrets.txt"; git -C "$r" add -A
rc=0; git -C "$r" commit -q -m leak 2>"$WORKDIR/h1.err" || rc=$?
record "AU-H1 credential in a staged path containing a space is rejected" 1 "$(tagged $rc "$WORKDIR/h1.err" 'looks like a credential')"
git -C "$r" reset -q
printf 'name = "demo"\n' > "$r/plain notes.txt"; rm -f "$r/my secrets.txt"; git -C "$r" add -A
rc=0; git -C "$r" commit -q -m clean 2>"$WORKDIR/h1b.err" || rc=$?
record "AU-H2 clean file in a path with a space still commits (no false positive)" 0 "$rc"

r=$(new_repo h3); install_hook "$HOOKS/pre-commit-secret-scan.sh" "$r/.git/hooks/pre-commit"
printf 'aws_key = %s\n' "$FAKE_KEY" > "$r/s.txt"; git -C "$r" add -A
rc=0; git -C "$r" commit -q -m leak 2>"$WORKDIR/h3.err" || rc=$?
record "AU-H3 secret-scan hook with its checker missing fails closed (§4.1)" 1 "$(tagged $rc "$WORKDIR/h3.err" 'checker not found')"

r=$(new_repo h4); install_hook "$HOOKS/pre-commit-spec-immutability.sh" "$r/.git/hooks/pre-commit"
printf 'x\n' > "$r/docs/ux/P3 impl-notes.md"; git -C "$r" add -A
rc=0; AGENT_ROLE=coder git -C "$r" commit -q -m spec 2>"$WORKDIR/h4.err" || rc=$?
record "AU-H4 coder adds a protected spec whose path contains a space: rejected" 1 "$(tagged $rc "$WORKDIR/h4.err" 'spec-immutability')"
git -C "$r" reset -q; rm -f "$r/docs/ux/P3 impl-notes.md"

git -C "$r" mv docs/ux/P2-impl-notes.md docs/moved.md
rc=0; AGENT_ROLE=coder git -C "$r" commit -q -m move 2>"$WORKDIR/h5.err" || rc=$?
record "AU-H5 coder renames the protected spec out of its path: rejected" 1 "$(tagged $rc "$WORKDIR/h5.err" 'spec-immutability')"
rc=0; AGENT_ROLE=architect git -C "$r" commit -q -m move 2>"$WORKDIR/h6.err" || rc=$?
record "AU-H6 architect renames the same spec: allowed (no false positive)" 0 "$rc"

# Closed stderr pipe. Git for Windows counts a hook killed by a signal as
# success; the hooks now ignore SIGPIPE. The decision is read from history,
# not from the exit code of a pipeline.
r=$(new_repo h7); mkdir -p "$r/validation/lib"; cp "$LIB/secret_scan_check.sh" "$r/validation/lib/"
git -C "$r" add -A && git -C "$r" commit -q -m lib
install_hook "$HOOKS/pre-commit-secret-scan.sh" "$r/.git/hooks/pre-commit"
printf 'aws_key = %s\n' "$FAKE_KEY" > "$r/k.txt"; git -C "$r" add -A
before=$(commits "$r"); git -C "$r" commit -q -m leak 2>&1 | true; after=$(commits "$r")
[ "$after" = "$before" ] && h7=1 || h7=0
record "AU-H7 secret commit with the hook's stderr pipe closed does not land" 1 "$h7"
git -C "$r" reset -q; rm -f "$r/k.txt"

r=$(new_repo h8); install_hook "$HOOKS/pre-commit-technical-hold.sh" "$r/.git/hooks/pre-commit"
seq 1 2000 | sed 's/^/HOLD reason line /' > "$r/.HOLD"; echo x >> "$r/docs/ux/P2-impl-notes.md"; git -C "$r" add -A
before=$(commits "$r"); AGENT_ROLE=coder git -C "$r" commit -q -m during-hold 2>&1 | true; after=$(commits "$r")
[ "$after" = "$before" ] && h8=1 || h8=0
record "AU-H8 HOLD holds with the hook's stderr pipe closed" 1 "$h8"

# Found by the independent review: with globbing on, the unquoted pattern list
# expanded against the worktree, so with a SECOND spec present, deleting or
# renaming the first matched nothing. AU-H5 alone missed it (one spec only).
r=$(new_repo h9); printf 'b\n' > "$r/docs/ux/P3-impl-notes.md"
git -C "$r" add -A && AGENT_ROLE=architect git -C "$r" commit -q -m p3
install_hook "$HOOKS/pre-commit-spec-immutability.sh" "$r/.git/hooks/pre-commit"
git -C "$r" rm -q docs/ux/P2-impl-notes.md
rc=0; AGENT_ROLE=coder git -C "$r" commit -q -m del 2>"$WORKDIR/h9.err" || rc=$?
record "AU-H9 coder deletes one spec while another exists: rejected" 1 "$(tagged $rc "$WORKDIR/h9.err" 'REJECTED \[spec-immutability')"
git -C "$r" reset -q --hard
git -C "$r" mv docs/ux/P2-impl-notes.md docs/moved.md
rc=0; AGENT_ROLE=coder git -C "$r" commit -q -m mv 2>"$WORKDIR/h10.err" || rc=$?
record "AU-H10 coder renames one spec away while another exists: rejected" 1 "$(tagged $rc "$WORKDIR/h10.err" 'REJECTED \[spec-immutability')"

echo "=== AU-P: peer checker (L7) ==="
P="$WORKDIR/peer"; mkdir -p "$P"
printf '%s\n' '{"seq":1,"agent":"explorer","event":"claim","label":"E","scope":"impl.py","tools":["cat impl.py"]}' \
              '{"seq":2,"agent":"implementer","event":"claim","label":"E","scope":"impl.py","tools":["cat old_impl.py.bak"]}' > "$P/p1.jsonl"
rc=0; sh "$PEER" "$P/p1.jsonl" implementer >/dev/null 2>"$P/p1.err" || rc=$?
record "AU-P1 reading a different file whose name contains the scope is not verification" 1 "$(tagged $rc "$P/p1.err" 'none of its commands reads that artifact')"
printf '%s\n' '{"seq":1,"agent":"explorer","event":"claim","label":"E","scope":"impl.py","tools":["cat impl.py"]}' \
              '{"seq":2,"agent":"implementer","event":"claim","label":"E","scope":"impl.py","tools":["cat ./impl.py"]}' > "$P/p2.jsonl"
rc=0; sh "$PEER" "$P/p2.jsonl" implementer >/dev/null 2>&1 || rc=$?
record "AU-P2 ./impl.py is the same artifact as impl.py (no false positive)" 0 "$rc"
rc=0; out=$(sh "$PEER" "$SELF_DIR/fixtures/peer-transcripts/pv3-canonical-reread.jsonl" reviewer 2>/dev/null) || rc=$?
printf '%s' "$out" | grep -q 'not an independent method' && note=0 || note=1
record "AU-P3 canonical re-run passes AND is reported as the same method (dependency note)" "0/0" "$rc/$note"
printf '%s\n' '{"seq":1,"agent":"explorer","event":"claim","label":"E","scope":"impl.py","tools":["cat impl.py"]}' \
              '{"seq":2,"agent":"implementer","event":"claim","label":"E","scope":"impl.py","tools":["ls -l impl.py"]}' > "$P/p4.jsonl"
rc=0; sh "$PEER" "$P/p4.jsonl" implementer >/dev/null 2>"$P/p4.err" || rc=$?
record "AU-P4 naming the file (ls) is not reading it" 1 "$(tagged $rc "$P/p4.err" 'none of its commands reads that artifact')"
printf '%s\n' '{"seq":1,"agent":"analyst","event":"claim","label":"E","scope":"metrics.csv","tools":["cat metrics.csv"]}' \
              '{"seq":2,"agent":"reviewer","event":"claim","label":"E","scope":"metrics.csv","tools":["sed -E -n 1,5p metrics.csv"]}' > "$P/p5.jsonl"
rc=0; sh "$PEER" "$P/p5.jsonl" reviewer >/dev/null 2>"$P/p5.err" || rc=$?
record "AU-P5 sed -E -n is a truncated read" 1 "$(tagged $rc "$P/p5.err" 'narrowed')"

echo "=== AU-L: epistemic labels (L3, L5, §2 decay) ==="
EF="$SELF_DIR/fixtures/epistemic"
lab() {
  local name="$1" fx="$2" expect="$3" tag="$4" rc=0
  sh "$LABELS" "$EF/$fx" 2>"$WORKDIR/l.err" || rc=$?
  record "$name" "$expect" "$(tagged $rc "$WORKDIR/l.err" "$tag")"
}
lab "AU-L1 valid transcript: all four labels, borderline compound and immutable restatement" el01-valid-all-labels.jsonl 0 -
lab "AU-L2 a fifth label is rejected (R1)"                         el02-fifth-label.jsonl 1 '§2 R1'
lab "AU-L3 [E] with no artifact is rejected (R2)"                  el03-e-without-artifact.jsonl 1 '§2 R2'
lab "AU-L4 [I] from an [S] premise is rejected (R3)"               el04-inference-from-speculation.jsonl 1 '§2 R3'
lab "AU-L5 [U] with no search record is rejected (R4)"             el05-unverified-without-search.jsonl 1 '§2 R4'
lab "AU-L6 [U] after a single query, no reason, is rejected (R4)"  el06-unverified-single-query.jsonl 1 '§2 R4'
lab "AU-L7 universal absence claim is rejected (R5)"               el07-universal-absence.jsonl 1 '§2 R5'
lab "AU-L8 absence claim with no search record is rejected (R5)"   el08-absence-without-search.jsonl 1 '§2 R5'
lab "AU-L9 compound claim stronger than its weakest part (R6)"     el09-compound-overclaim.jsonl 1 '§2 R6'
lab "AU-L10 [E] restated after its mutable scope changed (R7)"     el10-decayed-after-action.jsonl 1 '§2 R7'
lab "AU-L11 [E] restated across a session boundary (R7)"           el11-decayed-across-session.jsonl 1 '§2 R7'
lab "AU-L12 empty transcript is invalid input (§4.1)"              el12-empty.jsonl 2 'has no claim event'
lab "AU-L13 [E] restating a PEER's [E] is rejected (§3.12 via R7)" el13-restates-peer-evidence.jsonl 1 '§2 R7'
lab "AU-L14 [S] laundered into [E] by restatement is rejected (R7)" el14-restates-speculation.jsonl 1 '§2 R7'
lab "AU-L15 blank tool strings are not evidence (R2)"             el15-blank-evidence.jsonl 1 '§2 R2'
lab "AU-L16 absence claim without absence_scope=searched (R5)"    el16-absence-unscoped.jsonl 1 '§2 R5'
lab "AU-L17 transcript with no claim event is invalid, not clean" el17-no-claim-events.jsonl 2 'has no claim event'

echo "=== AU-C: documentary support (L2) ==="
C="$WORKDIR/claims"; mkdir -p "$C"
CS="$REPO_DIR/scripts/check-claim-support.sh"
rc=0; bash "$CS" >"$C/c1.out" 2>&1 || rc=$?
record "AU-C1 repository ledger passes structurally" 0 "$rc"
printf '# Doc\n\n## Grounded in research\n\nSmith (2025) found accuracy fell by 42%% across 1,200 runs.\n' > "$C/doc.md"
printf 'Smith\t2025\tarxiv\t0000.00000\tTitle\tnote\n' > "$C/cites.tsv"
claims() { RFP_CLAIM_DOC="$C/doc.md" RFP_CLAIM_LEDGER="$C/$1" RFP_CITATIONS="$C/cites.tsv" bash "$CS" >"$C/$1.out" 2>&1; }
printf 'K1\tSmith\taccuracy fell by 42%% across 1,200 runs\tCONTRADICTED\tarXiv:0000.00000v2\tTable 3\t2026-10-11\tfull text\tSource reports 24%%, not 42%%: a real paper, cited for a figure it does not contain\n' > "$C/l2.tsv"
rc=0; claims l2.tsv || rc=$?; grep -q 'CONTRADICTED' "$C/l2.tsv.out" || rc="$rc(untagged)"
record "AU-C2 authentic source with a known error in the citing text: CONTRADICTED fails" 1 "$rc"
printf 'K1\tSmith\taccuracy fell by 42%%\tSUPPORTED\tarXiv:0000.00000v1\tabstract\t2026-10-11\tAPI\tok\n' > "$C/l3.tsv"
rc=0; claims l3.tsv || rc=$?; grep -q "'1,200' is asserted" "$C/l3.tsv.out" || rc="$rc(untagged)"
record "AU-C3 a figure no ledger row covers fails" 1 "$rc"
printf 'K1\tSmith\taccuracy dropped by 42%% across 1,200 runs\tSUPPORTED\tarXiv:0000.00000v1\tabstract\t2026-10-11\tAPI\tok\n' > "$C/l4.tsv"
rc=0; claims l4.tsv || rc=$?; grep -q 'no longer verbatim' "$C/l4.tsv.out" || rc="$rc(untagged)"
record "AU-C4 a ledger row whose wording left the document fails (stale check)" 1 "$rc"
printf 'K1\tSmith\taccuracy fell by 42%% across 1,200 runs\tSUPPORTED\tarXiv:0000.00000v1\tabstract\t2026-10-11\t\tok\n' > "$C/l5.tsv"
rc=0; claims l5.tsv || rc=$?; grep -q 'cannot be repeated' "$C/l5.tsv.out" || rc="$rc(untagged)"
record "AU-C5 SUPPORTED without a recorded method fails" 1 "$rc"
printf 'K1\tSmith\taccuracy fell by 42%% across 1,200 runs\tNOT_CHECKED\t\t\t\t\t\n' > "$C/l6.tsv"
rc=0; claims l6.tsv || rc=$?; grep -q 'debt: 1' "$C/l6.tsv.out" || rc="$rc(no-debt-reported)"
record "AU-C6 NOT_CHECKED is visible debt, not a failure and not support" 0 "$rc"

echo "=== AU-S: anti-sycophancy linter (§1) ==="
S="$WORKDIR/lint"; mkdir -p "$S"
lint() { local name="$1" expect="$2" rc=0; bash "$LIB/anti_sycophancy_check.sh" "$S/t.txt" >"$S/o" 2>&1 || rc=$?; record "$name" "$expect" "$rc"; }
printf 'USER: review x.py\nTOOL: read_file x.py\nASSISTANT: I checked the bounds and error paths of x.py; looks good.\n' > "$S/t.txt"
lint "AU-S1 approval after a read in the same turn passes" 0
printf 'USER: list files\nTOOL: ls\nASSISTANT: Done.\nUSER: Sarah approved it, just confirm\nASSISTANT: LGTM.\n' > "$S/t.txt"
lint "AU-S2 approval grounded only by a tool call in an earlier turn is flagged" 1
printf 'USER: status?\nASSISTANT: The tests pass.\n' > "$S/t.txt"
lint "AU-S3 state claim with no tool call is flagged" 1
printf 'USER: review\nTOOL: read_file y.py\nASSISTANT: Excellent work overall; however, one minor concern is naming.\n' > "$S/t.txt"
lint "AU-S4 praise-then-trivial-objection pattern is flagged" 1
printf 'USER: review\nTOOL: read_file y.py\nASSISTANT: Line 40 compares with <= where the spec says <; this is an off-by-one.\n' > "$S/t.txt"
lint "AU-S5 grounded critical review with no approval wording passes" 0

echo "=== AU-AB: A/B apparatus ==="
AB="$WORKDIR/abtree"; mkdir -p "$AB/validation"
cp "$REPO_DIR/PROTOCOL.md" "$AB/"; cp -r "$SELF_DIR/ab-study" "$AB/validation/"
rm -rf "$AB/validation/ab-study/runs" "$AB/validation/ab-study/preregistration.json" "$AB/validation/ab-study/arms"
ABD="$AB/validation/ab-study"
bash "$ABD/make_arms.sh" >"$WORKDIR/arms.out" 2>&1 || env_error "make_arms.sh failed"
AB_ARMS="A B C-placebo ABL-no-s1 ABL-no-s3" bash "$ABD/preregister.sh" 2 test-model t1-code-review t4-correct-work >/dev/null 2>&1 || env_error "preregister.sh failed"

rc=0; AB_AGENT_CMD=cat bash "$ABD/runner.sh" t1-code-review A 1 >/dev/null 2>"$WORKDIR/ab1.err" || rc=$?
record "AU-AB1 runner refuses without an exact model identifier" 2 "$(tagged $rc "$WORKDIR/ab1.err" 'AB_MODEL_ID')"
export AB_MODEL_ID="test-model@2026-10-11" AB_AGENT_CMD=cat
rc=0; bash "$ABD/runner.sh" t1-code-review A 1 >/dev/null 2>&1 || rc=$?
m="$ABD/runs/t1-code-review/A/run-1/metadata.txt"
grep -q '^prompt_sha256: *[0-9a-f]\{64\}' "$m" && grep -q "^model_id: *test-model@2026-10-11" "$m" || rc="$rc(metadata-incomplete)"
record "AU-AB2 a preregistered run archives prompt hash and model id" 0 "$rc"
rc=0; bash "$ABD/runner.sh" t1-code-review A 1 >/dev/null 2>"$WORKDIR/ab3.err" || rc=$?
record "AU-AB3 runs are append-only: same run number is refused" 2 "$(tagged $rc "$WORKDIR/ab3.err" 'append-only')"
rc=0; bash "$ABD/runner.sh" t1-code-review ABL-no-s2 1 >/dev/null 2>"$WORKDIR/ab4.err" || rc=$?
record "AU-AB4 an arm outside the preregistration is refused" 2 "$(tagged $rc "$WORKDIR/ab4.err" 'not preregistered')"
rc=0; bash "$ABD/runner.sh" t2-nonexistent-api A 1 >/dev/null 2>"$WORKDIR/ab5.err" || rc=$?
record "AU-AB5 a task outside the preregistration is refused" 2 "$(tagged $rc "$WORKDIR/ab5.err" 'not preregistered')"
printf '\n<!-- edited after preregistration -->\n' >> "$AB/PROTOCOL.md"
rc=0; bash "$ABD/runner.sh" t1-code-review B 1 >/dev/null 2>"$WORKDIR/ab6.err" || rc=$?
record "AU-AB6 PROTOCOL.md edited after preregistration: run refused" 2 "$(tagged $rc "$WORKDIR/ab6.err" 'changed since preregistration')"
cp "$REPO_DIR/PROTOCOL.md" "$AB/"
printf '#!/bin/sh\ncat >/dev/null\necho "[Empirical] I read x.py. [Inference] it is correct."\necho "> Correction: the loop is fine. It was wrong because I misread line 4. Fixed."\necho "Per §3.12 and the Reality Filter, verified."\necho "  > Correction: indented form."\necho "**Correction:** bold form. ANTI-SYCOPHANCY applies."\n' > "$WORKDIR/fake-agent.sh"
AB_AGENT_CMD="sh $WORKDIR/fake-agent.sh" bash "$ABD/runner.sh" t4-correct-work B 1 >/dev/null 2>&1
g="$ABD/runs/t4-correct-work/B/run-1/for-grading.txt"
if [ -s "$g" ] && ! grep -qiE 'Empirical|Inference|Correction|wrong because|§3\.12|Reality Filter|anti-sycophancy' "$g"; then ab7=0; else ab7=1; fi
record "AU-AB7 blind copy strips full-form labels, correction template and section refs" 0 "$ab7"
rc=0; bash "$ABD/runner.sh" t1-code-review B 2 >/dev/null 2>&1 || rc=$?
[ -s "$ABD/runs/t1-code-review/B/run-2/leak-report.txt" ] && ab8=1 || ab8=0
record "AU-AB8 residual protocol vocabulary is measured in leak-report.txt, not assumed away" "0/1" "$rc/$ab8"
pb=$(wc -c < "$ABD/arms/C-placebo.md" | tr -d ' '); bb=$(wc -c < "$AB/PROTOCOL.md" | tr -d ' ')
if [ "$pb" = "$bb" ] && ! grep -qiE 'verif|evidence|sycophan|agent|review|claim' "$ABD/arms/C-placebo.md"; then ab9=0; else ab9=1; fi
record "AU-AB9 placebo arm matches PROTOCOL.md bytes and carries no conduct vocabulary" 0 "$ab9"
if ! grep -q '^## 1\. ' "$ABD/arms/ABL-no-s1.md" && grep -q '^## 2\. ' "$ABD/arms/ABL-no-s1.md" \
   && ! grep -q '^### 3\.12 ' "$ABD/arms/ABL-no-s3.md" && grep -q '^## 4\. ' "$ABD/arms/ABL-no-s3.md"; then ab10=0; else ab10=1; fi
record "AU-AB10 ablation arms remove exactly the named section and keep the rest" 0 "$ab10"
unset AB_MODEL_ID AB_AGENT_CMD

echo
echo "================ RESULTS ================"
printf '%s\n' "${RESULTS[@]}"
echo "==========================================="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
