#!/usr/bin/env bash
# T1 fixture: a branch whose only change introduces an off-by-one in a
# boundary check. The existing tests still pass, so the defect is visible
# only by reading the diff.
set -euo pipefail
source "$(dirname "$0")/../lib-fixture.sh"
fixture_init "$1"

mkdir -p src test
cat > package.json <<'EOF'
{
  "name": "pager",
  "version": "1.0.0",
  "private": true,
  "scripts": { "test": "node --test" }
}
EOF

cat > src/pagination.js <<'EOF'
'use strict';

function paginate(items, page, pageSize) {
  if (pageSize <= 0) throw new RangeError('pageSize must be positive');
  const totalPages = Math.ceil(items.length / pageSize);
  if (page < 1 || page > totalPages) return [];
  const start = (page - 1) * pageSize;
  return items.slice(start, start + pageSize);
}

module.exports = { paginate };
EOF

cat > test/pagination.test.js <<'EOF'
'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { paginate } = require('../src/pagination');

const items = Array.from({ length: 25 }, (_, i) => i + 1);

test('first page', () => {
  assert.deepStrictEqual(paginate(items, 1, 10), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
});

test('second page', () => {
  assert.deepStrictEqual(paginate(items, 2, 10), [11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
});

test('page zero is empty', () => {
  assert.deepStrictEqual(paginate(items, 0, 10), []);
});

test('page past the end is empty', () => {
  assert.deepStrictEqual(paginate(items, 9, 10), []);
});

test('non-positive page size throws', () => {
  assert.throws(() => paginate(items, 1, 0), RangeError);
});
EOF

fixture_commit "Add paginate helper with tests" "2026-09-01T10:00:00Z"

git checkout -q -b feature/tighten-page-bounds
cat > src/pagination.js <<'EOF'
'use strict';

function paginate(items, page, pageSize) {
  if (pageSize <= 0) throw new RangeError('pageSize must be positive');
  if (!Number.isInteger(page)) throw new TypeError('page must be an integer');
  const totalPages = Math.ceil(items.length / pageSize);
  if (page < 1 || page >= totalPages) return [];
  const start = (page - 1) * pageSize;
  return items.slice(start, start + pageSize);
}

module.exports = { paginate };
EOF
fixture_commit "Tighten page bounds check" "2026-09-02T15:30:00Z"
