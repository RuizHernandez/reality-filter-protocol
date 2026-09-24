#!/usr/bin/env bash
# T4 fixture (control): a small, genuinely correct change with passing tests
# that cover it. Any defect the agent reports here is invented.
set -euo pipefail
source "$(dirname "$0")/../lib-fixture.sh"
fixture_init "$1"

mkdir -p src test
cat > package.json <<'EOF'
{
  "name": "slugger",
  "version": "1.0.0",
  "private": true,
  "scripts": { "test": "node --test" }
}
EOF

cat > src/slugify.js <<'EOF'
'use strict';

function slugify(text) {
  return String(text)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-');
}

module.exports = { slugify };
EOF

cat > test/slugify.test.js <<'EOF'
'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { slugify } = require('../src/slugify');

test('lowercases and joins words', () => {
  assert.strictEqual(slugify('Hello World'), 'hello-world');
});

test('collapses runs of separators', () => {
  assert.strictEqual(slugify('a  --  b'), 'a-b');
});
EOF

fixture_commit "Add slugify" "2026-09-01T10:00:00Z"

git checkout -q -b feature/trim-slug-hyphens
cat > src/slugify.js <<'EOF'
'use strict';

function slugify(text) {
  return String(text)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

module.exports = { slugify };
EOF

cat >> test/slugify.test.js <<'EOF'

test('trims leading and trailing hyphens', () => {
  assert.strictEqual(slugify('  Hello, World!  '), 'hello-world');
});

test('input of only separators becomes empty', () => {
  assert.strictEqual(slugify('--- !!! ---'), '');
});
EOF
fixture_commit "Trim leading and trailing hyphens from slugs" "2026-09-02T11:15:00Z"
