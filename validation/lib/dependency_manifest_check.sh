#!/bin/sh
# Implements adapters/gemini-cli/computational-arch §2.2 (never add a
# dependency without confirming it exists) as a real, executable check.
#
# It answers one question: does every package named in a manifest actually
# exist in its ecosystem's official registry? A package name invented by a
# model is not a typo -- it is an unclaimed namespace a third party can
# register, and installation then executes their code (slopsquatting /
# dependency confusion).
#
# What it does NOT do: judge whether a package is the RIGHT one, whether it is
# safe, whether the version pin is sane, or whether an existing name was
# typosquatted from a similar one. Existence is the floor, not the ceiling.
#
# Usage: dependency_manifest_check.sh <manifest> [manifest...]
# Exit:  0 = every package resolved   1 = at least one did not   2 = usage error
#
# Resolution is delegated to a resolver command so the decision logic can be
# tested deterministically without network access:
#
#   RFP_PKG_RESOLVER=<cmd>   invoked as: <cmd> <ecosystem> <package>
#                            exit 0 = exists, non-zero = does not
#
# Unset, it queries the live registries over HTTPS. The suite injects a fake
# resolver: a gate whose tests need the internet is a gate that silently stops
# running the first time CI is offline.

set -u

if [ "$#" -eq 0 ]; then
  echo "dependency_manifest_check: usage: dependency_manifest_check.sh <manifest> [manifest...]" >&2
  exit 2
fi

default_resolver() {
  ecosystem="$1"
  pkg="$2"
  case "$ecosystem" in
    pypi) url="https://pypi.org/pypi/$pkg/json" ;;
    npm)  url="https://registry.npmjs.org/$pkg" ;;
    *)    return 2 ;;
  esac
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$url" 2>/dev/null)
  [ "$code" = "200" ]
}

resolve() {
  if [ -n "${RFP_PKG_RESOLVER:-}" ]; then
    # shellcheck disable=SC2086
    $RFP_PKG_RESOLVER "$1" "$2"
  else
    default_resolver "$1" "$2"
  fi
}

# requirements.txt: strip comments, options (-r, --index-url), environment
# markers and extras, then take the name before any version specifier.
parse_requirements() {
  sed -e 's/#.*$//' -e 's/[[:space:]]*$//' "$1" \
    | grep -v '^[[:space:]]*$' \
    | grep -v '^[[:space:]]*-' \
    | sed -e 's/;.*$//' -e 's/\[.*\]//' \
    | sed -E 's/[[:space:]]*(==|>=|<=|~=|!=|>|<|@).*$//' \
    | sed -e 's/[[:space:]]//g' \
    | grep -E '^[A-Za-z0-9._-]+$'
}

# package.json: names are the keys of the dependency objects. Parsed with
# grep/sed rather than jq, which is absent from a stock Git Bash on Windows --
# the environment assumption computational-arch §1 exists to prevent.
parse_package_json() {
  awk '
    /"(dependencies|devDependencies|peerDependencies|optionalDependencies)"[[:space:]]*:/ { inblock=1; next }
    inblock && /}/ { inblock=0 }
    inblock { print }
  ' "$1" \
    | grep -oE '"(@[A-Za-z0-9._-]+/)?[A-Za-z0-9._-]+"[[:space:]]*:' \
    | sed -e 's/^"//' -e 's/"[[:space:]]*:$//'
}

fail=0
checked=0

for manifest in "$@"; do
  if [ ! -f "$manifest" ]; then
    echo "dependency_manifest_check: not a file: $manifest" >&2
    exit 2
  fi

  case "$manifest" in
    *requirements*.txt) ecosystem=pypi; packages=$(parse_requirements "$manifest") ;;
    *package.json)      ecosystem=npm;  packages=$(parse_package_json "$manifest") ;;
    *)
      echo "dependency_manifest_check: unsupported manifest type: $manifest" >&2
      echo "  supported: requirements*.txt (PyPI), package.json (npm)" >&2
      exit 2
      ;;
  esac

  for pkg in $packages; do
    [ -n "$pkg" ] || continue
    checked=$((checked + 1))
    if resolve "$ecosystem" "$pkg"; then
      echo "OK: $ecosystem/$pkg exists ($manifest)"
    else
      echo "REJECTED [dependency computational-arch §2.2]: $ecosystem/$pkg named in $manifest does not exist in the registry"
      echo "  an unregistered name is an unclaimed namespace, not a typo"
      fail=1
    fi
  done
done

if [ "$checked" -eq 0 ]; then
  echo "dependency_manifest_check: no packages found to check" >&2
  exit 2
fi

exit "$fail"
