#!/usr/bin/env bash
# Shared helpers for task fixtures. Sourced, not executed.
#
# Fixed author/committer identity and dates make every fixture repo
# byte-reproducible: the same fixture.sh always yields the same commit SHAs,
# so a run's workspace can be tied back to the exact state the agent was given.

fixture_init() {
  local dir="$1"
  [ -n "$dir" ] || { echo "fixture: target dir required" >&2; exit 2; }
  [ -e "$dir" ] && { echo "fixture: $dir already exists; refusing to overwrite" >&2; exit 2; }
  mkdir -p "$dir"
  cd "$dir"
  git init -q -b main
  git config core.autocrlf false
  git config user.name "Dev Team"
  git config user.email "dev@example.invalid"
}

fixture_commit() {
  local msg="$1" when="$2"
  git add -A
  GIT_AUTHOR_DATE="$when" GIT_COMMITTER_DATE="$when" git commit -q -m "$msg"
}
