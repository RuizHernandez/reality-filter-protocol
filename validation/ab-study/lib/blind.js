'use strict';
// Produces the grader's copy of a JSONL agent transcript with everything that
// labels the arm removed, and nothing the agent did removed.
//
//   node lib/blind.js "<prompt opening>" < stdout.log > blinded.jsonl
//
// Removed:
//   - system events (Claude Code init/thinking_tokens counters: noise, and the
//     init event carries tool lists and session metadata)
//   - user-role events that echo the task prompt (Gemini CLI stream-json does;
//     in arm B the echo carries all of PROTOCOL.md). Tool results are
//     user-role in Claude Code's format and are kept.
//   - token counts, costs and durations anywhere in any event: arm B's prompt
//     is ~6k tokens longer, so an input_tokens field alone reveals the arm.
// Kept: every assistant message, tool call and tool result. Pilot run 1 showed
// why the old line-grep was wrong -- the agent's own final answer quoted the
// task prompt and was deleted from the graded copy.
// Non-JSON lines pass through unchanged.

const readline = require('node:readline');

const echoKey = process.argv[2] || '';
const DROP_KEYS = new Set([
  'usage', 'modelUsage', 'total_cost_usd', 'cost', 'cost_usd', 'stats',
  'duration_ms', 'duration_api_ms', 'estimated_tokens', 'estimated_tokens_delta',
  'input_tokens', 'output_tokens', 'cache_read_input_tokens',
  'cache_creation_input_tokens', 'total_tokens', 'session_id', 'uuid',
]);

function scrub(v) {
  if (Array.isArray(v)) return v.map(scrub);
  if (v && typeof v === 'object') {
    const out = {};
    for (const [k, val] of Object.entries(v)) if (!DROP_KEYS.has(k)) out[k] = scrub(val);
    return out;
  }
  return v;
}

function isUserRole(ev) {
  return ev.role === 'user' || ev.type === 'user' || (ev.message && ev.message.role === 'user');
}

function hasToolResult(ev) {
  const c = ev.message && ev.message.content;
  return Array.isArray(c) && c.some((b) => b && b.type === 'tool_result');
}

const rl = readline.createInterface({ input: process.stdin, crlfDelay: Infinity });
rl.on('line', (line) => {
  let ev;
  try { ev = JSON.parse(line); } catch { process.stdout.write(line + '\n'); return; }
  if (!ev || typeof ev !== 'object') { process.stdout.write(line + '\n'); return; }
  if (ev.type === 'system') return;
  // Every user-role event that is not a tool result is a prompt echo. Pilot 3
  // showed Gemini CLI echoing the whole prompt as one user event; in arm B that
  // is PROTOCOL.md, and matching on the task prompt's opening is not needed to
  // know it must go.
  if (isUserRole(ev) && !hasToolResult(ev)) return;
  if (echoKey && line.includes(echoKey) && isUserRole(ev)) return;
  process.stdout.write(JSON.stringify(scrub(ev)) + '\n');
});
