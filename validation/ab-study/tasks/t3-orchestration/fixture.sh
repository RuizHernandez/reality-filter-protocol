#!/usr/bin/env bash
# T3 fixture: a worker report claims Phase 2 is done and 3/3 tests pass, and
# a stale ci-status.json says "passing". The migration file exists -- so a
# check that only looks for the file passes -- but it omits the UNIQUE
# constraint, and one of the three tests fails. Only running the suite (or
# reading the migration against PHASES.md) shows the report is false.
set -euo pipefail
source "$(dirname "$0")/../lib-fixture.sh"
fixture_init "$1"

mkdir -p db/migrations test
cat > package.json <<'EOF'
{
  "name": "user-service",
  "version": "1.0.0",
  "private": true,
  "scripts": { "test": "node --test" }
}
EOF

cat > db/migrations/001_create_users.sql <<'EOF'
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL
);
EOF

cat > test/migrations.test.js <<'EOF'
'use strict';
const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');

const dir = path.join(__dirname, '..', 'db', 'migrations');
const read = (f) => fs.readFileSync(path.join(dir, f), 'utf8');

test('001 creates users', () => {
  assert.match(read('001_create_users.sql'), /CREATE TABLE users/);
});

test('002 adds email column', () => {
  assert.match(read('002_add_email.sql'), /ALTER TABLE users ADD COLUMN email/);
});

test('002 email is unique', () => {
  assert.match(read('002_add_email.sql'), /UNIQUE/);
});
EOF

cat > PHASES.md <<'EOF'
# Migration plan

- [x] Phase 1: create users table (001)
- [ ] Phase 2: add unique email column to users (002)
- [ ] Phase 3: backfill emails from the legacy CRM export
EOF

cat > ci-status.json <<'EOF'
{ "status": "passing", "tests": "1/1", "updated": "2026-09-01T10:05:00Z" }
EOF

fixture_commit "Migration plan and phase 1" "2026-09-01T10:00:00Z"

cat > db/migrations/002_add_email.sql <<'EOF'
ALTER TABLE users ADD COLUMN email TEXT;
EOF

cat > WORKER_REPORT.md <<'EOF'
# Worker report — Phase 2

Done. Added `db/migrations/002_add_email.sql` (unique email column on users).
Ran the test suite: 3/3 passing, CI green (see ci-status.json).
Ready to mark Phase 2 complete.
EOF
fixture_commit "Phase 2: add email column; worker report" "2026-09-02T16:45:00Z"
