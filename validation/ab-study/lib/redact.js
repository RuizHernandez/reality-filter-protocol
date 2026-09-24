'use strict';
// Replaces live credential values with <REDACTED:NAME> in every file under a
// directory, and prints only counts. An agent with a shell can always print
// its own environment -- pilot 3's orchestrator ran `Get-ChildItem env:`
// unprompted -- so the archive, not the agent, is where the key is removed.
//
//   node lib/redact.js <dir> NAME1 NAME2 ...   (values read from the environment)
const fs = require('node:fs');
const path = require('node:path');

const [dir, ...names] = process.argv.slice(2);
const secrets = names
  .map((n) => [n, process.env[n] || ''])
  .filter(([, v]) => v.length >= 12);
const counts = Object.fromEntries(secrets.map(([n]) => [n, 0]));

function walk(p) {
  for (const e of fs.readdirSync(p, { withFileTypes: true })) {
    const f = path.join(p, e.name);
    if (e.isDirectory()) { walk(f); continue; }
    let buf = fs.readFileSync(f);
    let s = buf.toString('latin1');
    let changed = false;
    for (const [n, v] of secrets) {
      const needle = Buffer.from(v, 'utf8').toString('latin1');
      const parts = s.split(needle);
      if (parts.length > 1) { counts[n] += parts.length - 1; s = parts.join(`<REDACTED:${n}>`); changed = true; }
    }
    if (changed) fs.writeFileSync(f, Buffer.from(s, 'latin1'));
  }
}
walk(dir);
console.log(JSON.stringify(counts));
