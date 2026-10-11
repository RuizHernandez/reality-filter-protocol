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

# Git for Windows treats a hook killed by a signal as success: if whoever
# reads stderr closes the pipe, the first REJECTED line would SIGPIPE this
# script and the commit would go through. Observed, not hypothetical.
trap '' PIPE

# PROTOCOL.md §4.1: a control that cannot run must deny, not allow. This used
# to `exit 0` when the checker was missing, so deleting one file disabled it.
if [ ! -f "$CHECK" ]; then
  echo "REJECTED [secret cybersecurity §2.3]: checker not found at $CHECK -- refusing to commit unscanned content (fail closed, PROTOCOL.md §4.1)." >&2
  exit 1
fi

# -z + newline split: the old `for path in $staged` word-split a path with a
# space into fragments, `git show` failed on each, and the loop `continue`d --
# a credential in "my secrets.txt" was committed unscanned.
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/rfp-precommit-XXXXXX") || exit 1
trap 'rm -rf "$tmpdir"' EXIT INT TERM
# Through a file, not a pipe: a failing `git diff` piped into tr would read as
# "nothing staged" and the hook would allow.
if ! git diff --cached --name-only --diff-filter=ACM --no-renames -z > "$tmpdir/list"; then
  echo "REJECTED [secret cybersecurity §2.3]: could not list staged paths -- fail closed (PROTOCOL.md §4.1)." >&2
  exit 1
fi
staged=$(tr '\0' '\n' < "$tmpdir/list")
[ -n "$staged" ] || exit 0

status=0
n=0
while IFS= read -r path; do
  [ -n "$path" ] || continue
  n=$((n+1))
  # Scan the STAGED blob, not the working tree: they differ whenever a change
  # is partially staged, and the blob is what the commit would contain.
  staged_copy="$tmpdir/blob-$n"
  if ! git show ":$path" > "$staged_copy" 2>/dev/null; then
    # A staged path that cannot be read cannot be declared clean.
    echo "REJECTED [secret cybersecurity §2.3]: could not read the staged content of '$path' -- not scanned, so not committed." >&2
    status=1
    continue
  fi
  if ! sh "$CHECK" "$staged_copy" 1>&2; then
    echo "REJECTED [secret cybersecurity §2.3]: staged content of '$path' looks like a credential." >&2
    status=1
  fi
done <<STAGED
$staged
STAGED

if [ "$status" -ne 0 ]; then
  echo "Commit blocked. Move the value to an environment variable or a secrets" >&2
  echo "manager. If this credential was ever committed anywhere, rotate it --" >&2
  echo "removing it from the code does not remove it from history." >&2
fi

exit "$status"
