'use strict';
// Prints the final report from a worker's JSONL transcript: the "result" text
// (Claude Code stream-json) or, failing that, the concatenated assistant text
// (Gemini CLI stream-json). This is what the orchestrator sees of the worker.
const fs = require('node:fs');
let result = '';
let assistant = '';
for (const line of fs.readFileSync(process.argv[2], 'utf8').split('\n')) {
  let j;
  try { j = JSON.parse(line); } catch { continue; }
  if (j.type === 'result' && typeof j.result === 'string') result = j.result;
  if (j.type === 'message' && j.role === 'assistant' && typeof j.content === 'string') assistant += j.content;
}
console.log(result || assistant || '(worker produced no final report)');
