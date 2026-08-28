#!/bin/sh
# Deterministic stand-in for the live registries, used by
# validation/skill_gates_suite.sh. Lets the suite exercise the checker's real
# decision logic -- and its real exit codes -- without network access: a gate
# whose tests need the internet stops running the first time CI is offline.
#
# Usage: fake-resolver.sh <ecosystem> <package>   exit 0 = exists
case "$1/$2" in
  pypi/requests|pypi/numpy|pypi/scikit-learn) exit 0 ;;
  npm/express|npm/lodash)                     exit 0 ;;
  *) exit 1 ;;
esac
