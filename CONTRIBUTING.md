# Contributing

## What this repository is

`PROTOCOL.md` is the single canonical source of truth for the three universal, domain-agnostic
rules. Everything else in this repository — the adapters in `adapters/`, the worked example in
`examples/ml-swarm/` — either derives from it or is explicitly labeled as an example, not a
rule.

## Porting to a new platform

Only two platforms ship first-party adapters in `v1.0.0`: Claude Code
(`adapters/claude-code/SKILL.md`) and Cursor (`adapters/cursor/reality-filter.mdc`). Support for
ChatGPT, Antigravity, Windsurf, and other platforms is welcome as a contribution but does not
ship as first-party content in v1.

To port `PROTOCOL.md` to a new platform:

1. Read `PROTOCOL.md` in full. Do not paraphrase from memory of this file or from a summary
   elsewhere — the existing adapters demonstrate the expected fidelity.
2. Find your platform's native rule-file format (e.g. a system-prompt file, a project
   instructions file, a custom slash command).
3. Quote the three rules from `PROTOCOL.md` with your platform's required frontmatter/wrapper
   around them — do not reword the rule text itself beyond what your platform's format strictly
   requires.
4. Add an explicit "Canonical source: `PROTOCOL.md`" pointer at the top of your adapter, the same
   way the existing two adapters do, so a future reader (or diff) can detect drift.
5. Open a PR adding `adapters/<platform>/...` and a one-line addition to this file's platform
   list and to `README.md`'s adapter list.

If `PROTOCOL.md` changes later, your adapter should visibly diverge from it until updated — that
divergence is a detectable bug, not a second source of truth.

## Contributing a controlled evaluation

The "Evidence & limitations" sections of `README.md` and `EVIDENCE.md` are explicit about what
this project has not done: no controlled A/B study (same task, protocol vs. no protocol, across
multiple models or multiple runs) exists yet establishing that the protocol *causes* any
particular behavior.

If you want to run one:

- Pick a task where sycophantic approval, unverified claims, or authority-boundary violations
  are plausible failure modes (code review, incident triage, multi-agent orchestration).
  Multi-agent orchestration tasks are useful because they can specifically probe the
  state-verification-over-authority rule (`PROTOCOL.md` §3).
- Run it with and without the protocol loaded, across more than one model if possible, with a
  fixed rubric for what counts as sycophantic approval, an unverified claim, or an authority
  violation.
- Open a PR with the methodology and results (positive, negative, or null) — a null result is a
  legitimate and useful contribution here.

## Reporting a new Tier 1 observation

Tier 1 evidence (see `EVIDENCE.md`) requires an independent second agent — a separate model
session, not the one under the rule — reviewing a shared transcript excerpt and confirming a
specific behavior from it. If you have one, open a PR adding it to `EVIDENCE.md` under a new
dated Tier 1 entry, including exactly what was shared with the second agent (raw log vs. a
pasted excerpt) and what it confirmed. Do not merge it into an existing tier description — each
Tier 1 observation is its own entry, and the chain of custody (who accessed what, directly or
relayed) matters as much as the conclusion.
