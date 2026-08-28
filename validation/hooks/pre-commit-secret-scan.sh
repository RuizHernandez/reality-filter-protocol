#!/bin/sh
# Implements adapters/gemini-cli/cybersecurity §2.3 as a technical stop rather
# than an instruction: blocks a commit whose staged content contains a string
# shaped like a live credential.
#
# §2.3's other half -- that deleting a committed secret from the code does NOT
# remove it from history, so rotation is mandatory -- is exactly why this has
# to run BEFORE the commit exists. Once it is in an object, a hook cannot help.

REPO="$(git rev-parse --show-toplevel)"
CHECK="$REPO/validation/lib/secret_scan_check.sh"

[ -x "$CHECK" ] || [ -f "$CHECK" ] || exit 0

staged=$(git diff --cached --name-only --diff-filter=ACM)
[ -n "$staged" ] || exit 0

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/rfp-precommit-XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT INT TERM

status=0
for path in $staged; do
  # Scan the STAGED blob, not the working tree: they differ whenever a change
  # is partially staged, and the blob is what the commit would contain.
  staged_copy="$tmpdir/$(echo "$path" | tr '/' '_')"
  git show ":$path" > "$staged_copy" 2>/dev/null || continue
  if ! sh "$CHECK" "$staged_copy" 2>/dev/null; then
    echo "REJECTED [secret cybersecurity §2.3]: staged content of $path looks like a credential." >&2
    status=1
  fi
done

if [ "$status" -ne 0 ]; then
  echo "Commit blocked. Move the value to an environment variable or a secrets" >&2
  echo "manager. If this credential was ever committed anywhere, rotate it --" >&2
  echo "removing it from the code does not remove it from history." >&2
fi

exit "$status"
