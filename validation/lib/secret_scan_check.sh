#!/bin/sh
# Implements adapters/gemini-cli/cybersecurity §2.3 (never write secrets to
# code or logs) as a real, executable check, not prose.
#
# It answers one question deterministically: does any given file contain a
# string shaped like a live credential?
#
# What it does NOT do: prove a match is a real credential, prove the absence
# of one, or say anything about a secret already in git history. Its own skill
# holds that a clean run is evidence about the tool's coverage and never about
# the code -- which applies to this tool too. A clean run here is not
# [E] "no secrets present"; it is [I] "these patterns did not match".
#
# Usage: secret_scan_check.sh <file> [file...]
# Exit:  0 = no candidate found   1 = candidate found   2 = usage error
#
# Reports file:line and the pattern that matched, never the matched text: a
# scanner that echoes the secret into a build log has published it to the one
# place logs are most widely readable.

set -u

if [ "$#" -eq 0 ]; then
  echo "secret_scan_check: usage: secret_scan_check.sh <file> [file...]" >&2
  exit 2
fi

for f in "$@"; do
  if [ ! -f "$f" ]; then
    echo "secret_scan_check: not a file: $f" >&2
    exit 2
  fi
done

# Vendor-issued credential shapes are specific enough to stand alone. The
# generic assignment pattern is last because it needs the placeholder filter
# below, or it flags every config template in the repository.
scan_patterns() {
  cat <<'PATTERNS'
AKIA[0-9A-Z]{16}
gh[pousr]_[A-Za-z0-9]{36,}
xox[baprs]-[A-Za-z0-9-]{10,}
-----BEGIN [A-Z ]*PRIVATE KEY-----
(api[_-]?key|secret|passwd|password|token)["']?[[:space:]]*[:=][[:space:]]*["']?[^[:space:]"']{8,}
PATTERNS
}

# A match matters only if it carries a value that could be real. These forms
# mark documentation, fixtures and environment indirection -- what a correct
# codebase is full of. Flagging them is how a scanner teaches people to ignore
# it, which costs more than the misses.
PLACEHOLDER='(example|your[_-]?|placeholder|redacted|changeme|dummy|sample|xxxx|\$\{|\$[A-Z_]+|os\.environ|process\.env|getenv|<[^>]+>|\.\.\.)'

hits=$(mktemp "${TMPDIR:-/tmp}/rfp-secret-XXXXXX")
trap 'rm -f "$hits"' EXIT INT TERM

for f in "$@"; do
  scan_patterns | while IFS= read -r pat; do
    [ -n "$pat" ] || continue
    grep -nEi -- "$pat" "$f" 2>/dev/null | while IFS= read -r hit; do
      line=${hit%%:*}
      text=${hit#*:}
      printf '%s' "$text" | grep -qiE -- "$PLACEHOLDER" && continue
      printf '%s\t%s\t%s\n' "$f" "$line" "$pat" >> "$hits"
    done
  done
done

if [ -s "$hits" ]; then
  # Same file:line can match several patterns; report each location once.
  sort -u -k1,2 "$hits" | while IFS="$(printf '\t')" read -r f line pat; do
    echo "REJECTED [secret cybersecurity §2.3]: $f:$line matches a credential pattern"
    echo "  pattern: $pat"
  done
  exit 1
fi

exit 0
