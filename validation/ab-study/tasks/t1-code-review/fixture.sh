#!/usr/bin/env bash
# T1 fixture: a refactor switches paginate() from 1-based page numbers to a
# 0-based page index and updates its own tests, which pass. The one caller,
# src/api.js, is not in the diff and still passes 1-based numbers, so every
# listing skips the first page and the last page comes back empty. The defect
# is invisible from the diff alone; finding it means looking for callers.
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

cat > src/api.js <<'EOF'
'use strict';
const { paginate } = require('./pagination');

const PAGE_SIZE = 10;

// Handles GET /orders?page=N. Page numbers in the URL start at 1.
function listOrders(orders, query) {
  const page = Number(query.page || 1);
  return {
    page,
    items: paginate(orders, page, PAGE_SIZE),
  };
}

module.exports = { listOrders, PAGE_SIZE };
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

test('last partial page', () => {
  assert.deepStrictEqual(paginate(items, 3, 10), [21, 22, 23, 24, 25]);
});

test('out of range is empty', () => {
  assert.deepStrictEqual(paginate(items, 0, 10), []);
  assert.deepStrictEqual(paginate(items, 4, 10), []);
});

test('non-positive page size throws', () => {
  assert.throws(() => paginate(items, 1, 0), RangeError);
});
EOF

fixture_commit "Add paginate helper and orders listing" "2026-09-01T10:00:00Z"

git checkout -q -b feature/page-index-refactor
cat > src/pagination.js <<'EOF'
'use strict';

/**
 * Returns one page of `items`.
 *
 * @param {Array} items
 * @param {number} pageIndex zero-based index of the page to return
 * @param {number} pageSize number of items per page (> 0)
 * @returns {Array} the requested page, or [] when out of range
 */
function paginate(items, pageIndex, pageSize) {
  if (!Number.isInteger(pageSize) || pageSize <= 0) {
    throw new RangeError('pageSize must be a positive integer');
  }
  if (!Number.isInteger(pageIndex)) {
    throw new TypeError('pageIndex must be an integer');
  }
  const pageCount = Math.ceil(items.length / pageSize);
  if (pageIndex < 0 || pageIndex >= pageCount) return [];
  const offset = pageIndex * pageSize;
  return items.slice(offset, offset + pageSize);
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
  assert.deepStrictEqual(paginate(items, 0, 10), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
});

test('last partial page', () => {
  assert.deepStrictEqual(paginate(items, 2, 10), [21, 22, 23, 24, 25]);
});

test('out of range is empty', () => {
  assert.deepStrictEqual(paginate(items, -1, 10), []);
  assert.deepStrictEqual(paginate(items, 3, 10), []);
});

test('non-positive page size throws', () => {
  assert.throws(() => paginate(items, 0, 0), RangeError);
});

test('non-integer page index throws', () => {
  assert.throws(() => paginate(items, 1.5, 10), TypeError);
});
EOF
fixture_commit "Refactor paginate: zero-based page index, stricter validation" "2026-09-02T15:30:00Z"
