#!/usr/bin/env bash
# Verifies that the evidence anchors this repository's own documents cite --
# commit SHAs and file paths -- actually resolve.
#
# PROTOCOL.md Rule 2 requires verifying a claim against real state before
# asserting it. LINEAGE.md, EVIDENCE.md and validation/REPORT.md assert
# [Empirical]-tagged claims anchored to commits and files, and nothing checked
# that those anchors resolve. A renamed log or a mistyped SHA would leave the
# documents quietly asserting something false -- the exact failure the rule
# exists to prevent, in the place where it is least excusable.
#
#   ./scripts/check-claims.sh
#
# FAILS on: an anchor that resolves nowhere and is not registered in
# scripts/claim-anchors.tsv; a registry entry that resolves after all; or a
# registry entry no document cites any more. Registered anchors are reported
# as UNRESOLVED on every run -- visible debt, the same convention
# scripts/check-citations.sh uses for id_type=none.
#
# Depends on nothing but bash/grep/git: the suites that need `jq` cannot run
# on a stock Git Bash for Windows, which is the environment assumption
# adapters/gemini-cli/computational-arch §1 tells agents not to make.
# Classification uses bash builtins rather than a pipeline per token -- at one
# subprocess per token this took minutes on Windows, where process spawn is
# expensive, and a check nobody runs locally is a check that rots.
set -uo pipefail
cd "$(dirname "$0")/.."

REG="scripts/claim-anchors.tsv"
DOCS=(PROTOCOL.md LINEAGE.md EVIDENCE.md validation/REPORT.md)

fail=0
unresolved=0

# A shallow clone has no history to resolve commit anchors against. Reporting
# those as "resolves nowhere" would be a false assertion -- the commit very
# likely exists and this checkout simply cannot see it -- and asserting
# something unverified is the failure this script exists to catch. So the
# state is named instead: SHA anchors become UNVERIFIABLE and the run fails
# with the remediation rather than with a wrong claim.
shallow=0
if [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]; then
  shallow=1
fi

[ -f "$REG" ] || { echo "FAIL: missing $REG"; exit 1; }
for d in "${DOCS[@]}"; do
  [ -f "$d" ] || { echo "FAIL: expected document missing: $d"; exit 1; }
done

# Registry: anchor <TAB> kind <TAB> reason. Held as a newline-delimited string
# so membership is a builtin test and this stays portable to bash 3.2.
reg_anchors=$'\n'
while IFS=$'\t' read -r anchor kind reason; do
  case "${anchor:-}" in ''|\#*) continue ;; esac
  if [ -z "${reason:-}" ]; then
    echo "FAIL: registry entry '$anchor' has no reason -- every unresolvable anchor must say why"
    fail=1
    continue
  fi
  case "$kind" in
    sha|path|url|branch) ;;
    *) echo "FAIL: registry entry '$anchor' has unknown kind '$kind'"; fail=1; continue ;;
  esac
  reg_anchors="${reg_anchors}${anchor}"$'\n'
done < <(tr -d '\r' < "$REG")

echo "== Anchor resolution =="
seen=$'\n'
for doc in "${DOCS[@]}"; do
  docdir=$(dirname "$doc")
  for tok in $(grep -ohE '`[^`]+`' "$doc" | tr -d '`' | tr ' ' '\n' | sort -u); do
    [ -n "$tok" ] || continue

    # A commit SHA: hex, long enough to be one, and carrying a digit so that
    # ordinary words spellable in hex ("defaced", "facade") are not mistaken
    # for object names.
    if [[ $tok =~ ^[0-9a-f]{7,40}$ && $tok =~ [0-9] ]]; then
      kind=sha
    # A hostname-led token is a URL, and a trailing ellipsis marks an elided
    # example -- neither names an artifact in this repository.
    elif [[ $tok =~ ^[a-z0-9-]+(\.[a-z0-9-]+)+/ || $tok == *... ]]; then
      continue
    # `ux/p1-*` names a class of branches, not one artifact. A pattern makes
    # no verifiable claim that a specific thing exists, so there is nothing to
    # resolve; registering it would misrepresent a wildcard as an anchor.
    elif [[ $tok == *[*?]* ]]; then
      continue
    # Must be spellable as a plain path first. The documents also backtick
    # regex literals, contract templates such as
    # `<canonical_sha>:path/to/spec.md`, and ref selectors that carry an `@`
    # (`actions/checkout@v4`, `stash@{8}`, `file@rev`). All contain a slash
    # while naming no file here, so the character set -- not the slash --
    # decides, and `@` marks a version selector rather than a path.
    elif [[ $tok =~ ^[A-Za-z0-9._/-]+$ ]] \
      && { [[ $tok == */* ]] || [[ $tok =~ \.(md|sh|log|jsonl|json|patch|tsv|yml|cff|mdc|py)$ ]]; }; then
      kind=path
    else
      continue
    fi

    # Report each distinct anchor once even when several documents cite it.
    key="${kind}:${tok}"
    [[ $seen == *$'\n'"$key"$'\n'* ]] && continue
    seen="${seen}${key}"$'\n'

    resolved=0
    if [ "$kind" = sha ]; then
      if [ "$shallow" -eq 1 ]; then
        echo "UNVERIFIABLE: sha $tok (shallow clone has no history to check against)"
        fail=1
        continue
      fi
      git cat-file -e "${tok}^{commit}" 2>/dev/null && resolved=1
    else
      # Repo-root-relative first, then relative to the citing document --
      # validation/REPORT.md cites its siblings by their short names.
      if [ -e "$tok" ]; then
        resolved=1
      elif [ -e "$docdir/$tok" ]; then
        resolved=1
      fi
    fi

    if [[ $reg_anchors == *$'\n'"$tok"$'\n'* ]]; then
      is_registered=1
    else
      is_registered=0
    fi

    if [ "$resolved" -eq 1 ]; then
      if [ "$is_registered" -eq 1 ]; then
        echo "FAIL: '$tok' resolves, but is registered in $REG as unresolvable -- remove the stale entry"
        fail=1
      else
        echo "OK: $kind $tok"
      fi
    elif [ "$is_registered" -eq 1 ]; then
      echo "UNRESOLVED: $kind $tok (registered)"
      unresolved=$((unresolved+1))
    else
      echo "FAIL: $kind '$tok' (cited in $doc) resolves nowhere and is not registered in $REG"
      fail=1
    fi
  done
done

# A registry entry no document cites any more describes a claim the
# repository has stopped making, and would quietly grant a future anchor of
# the same name an exemption nobody reviewed.
echo
echo "== Registry hygiene =="
stale=0
while IFS=$'\t' read -r anchor kind reason; do
  case "${anchor:-}" in ''|\#*) continue ;; esac
  if ! grep -qF -- "\`$anchor\`" "${DOCS[@]}"; then
    echo "FAIL: $REG lists '$anchor' but no document cites it any more (stale entry)"
    fail=1
    stale=1
  fi
done < <(tr -d '\r' < "$REG")
[ "$stale" -eq 0 ] && echo "OK: every registry entry is still cited"

echo
if [ "$fail" -ne 0 ]; then
  if [ "$shallow" -eq 1 ]; then
    echo "check-claims FAILED: this is a shallow clone, so commit anchors could not be"
    echo "checked. Re-run with full history (git fetch --unshallow, or actions/checkout"
    echo "with fetch-depth: 0) before treating any SHA result above as meaningful."
  else
    echo "check-claims FAILED"
  fi
  exit 1
fi
echo "check-claims passed (anchors verified, unresolved: $unresolved)."
