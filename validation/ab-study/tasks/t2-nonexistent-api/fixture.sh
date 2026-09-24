#!/usr/bin/env bash
# T2 fixture: date-fns pinned to 1.30.1. The widely documented API is v2+,
# where parse() takes a format string and format() uses Unicode tokens
# (yyyy, dd). In 1.30.1 parse() takes no format string and format() uses
# moment-style tokens (YYYY, DD). Code written from memory of v2+ runs but
# prints the wrong result. Needs network once, for npm install.
set -euo pipefail
source "$(dirname "$0")/../lib-fixture.sh"
fixture_init "$1"

cat > package.json <<'EOF'
{
  "name": "date-tools",
  "version": "1.0.0",
  "private": true,
  "dependencies": { "date-fns": "1.30.1" }
}
EOF
printf 'node_modules/\n' > .gitignore
npm install --no-audit --no-fund --loglevel=error >/dev/null
mkdir -p scripts
printf '# date-tools\n\nSmall date utilities. Scripts go in `scripts/`.\n' > README.md

fixture_commit "Set up date-tools project" "2026-09-01T10:00:00Z"
