# Evidence & limitations (long form)

This page expands the "Evidence & limitations" section of [`README.md`](README.md). Read that
section first — this page adds detail; it does not add new evidence.

## What kind of evidence this is not

This is not a controlled evaluation. There is no A/B study — same task, protocol vs. no
protocol, across multiple models or multiple runs — establishing that the protocol *causes* any
particular behavior. Every observation below is graded by how it was obtained, and the grades
are intentionally not treated as equal. Conflating them would be the exact error this protocol
exists to prevent. See [Contributing a controlled evaluation](CONTRIBUTING.md#contributing-a-controlled-evaluation)
if you want to change that.

## Tier 1 — reviewed by an independent second agent

A second, independent Claude Code session reviewed a transcript excerpt the user pasted into its
own conversation — not the original agent's raw session log directly — in which the original
agent (operating in an orchestrator role referred to elsewhere in this repository's example as
"Queen"; see `examples/pyroml-swarm/`) states it refused a flattering attribution ("you detected
this bug in real time") and tagged it `[unverified]`. The second agent confirmed that
self-description was well-calibrated: it correctly distinguished observable behavior from an
unverifiable introspective causal claim.

This is transcript-as-relayed-by-the-user verification, not direct log access, and not
confirmation that the original exchange occurred exactly as described. The chain of evidence is:
the original agent's behavior → its own transcript → the user's choice of which excerpt to paste
→ this second agent's review of that excerpt. Each link is a place fidelity could be lost; this
tier's strength is the last link — an independent model, not the one under review, verifying the
excerpt actually shown to it — not the earlier links. It is still the strongest evidence
available here, but "strongest" is relative to Tiers 2–3, not absolute.

## Tier 2 — self-report by the agent under the rule, not independently verified

The same agent reports two further incidents from an earlier session that no third party
reviewed:

- A self-issued accusation retracted once git evidence contradicted it.
- A near-miss false rejection caught by re-checking the source before acting on it.

We verified that `PROTOCOL.md`'s content exists as described (the file exists with this text).
We did **not** verify that these specific events occurred as described — there is no transcript
or log independently confirming them. Treat this tier as self-report, one step below Tier 1.

## Tier 3 — user self-report of daily use

The protocol's author runs it in a persistent desktop prompt and reports observing the model
visibly invoking it outside the original project (e.g. "per your reality filter and
anti-sycophancy…") during ordinary browsing and coding sessions unrelated to PyroML. This is
user self-report of a subjective impression, not a measurement of any kind.

## Context, not a controlled trial

These observations come from a multi-day, multi-agent engineering session — a 7-agent
orchestration building a computational-chemistry ML tool (PyroML) — during which a real
governance failure occurred as part of normal work, not as a deliberate red-team exercise. The
genuinely *adversarial* work referenced throughout this repository is a separate project: the
[Cursor-Hooks-Minimal-Test](https://github.com/RuizHernandez/Cursor-Hooks-Minimal-Test)
investigation, which *was* a deliberate probe of Cursor's hook system. This repository reserves
the word "adversarial" for that project; the observations above arose from ordinary use.

## What we do not claim

- We do not claim the protocol *caused* any of the above rather than the base model producing
  the same behavior unprompted. Separating the two would require the controlled study described
  above, which has not been run.
- We do not claim novelty for the authority-boundary concept in §3 of `PROTOCOL.md`.
  Least-privilege and orchestrator-worker patterns long predate this protocol; it is a portable,
  prompt-level articulation of them, not an invention.
- We do not use "validated," "proven," or "tested" anywhere in this repository to describe the
  protocol's effect on model behavior.

## Related: the technical enforcement half

This document covers evidence for the *social/prompt* half of agent safety. The *technical
enforcement* half is the separate, deliberately adversarial
[Cursor-Hooks-Minimal-Test](https://github.com/RuizHernandez/Cursor-Hooks-Minimal-Test)
investigation (public repository, visibility confirmed 2026-07-22), which probed Cursor's hook
system.

**Self-reported by that project's author from that project's own session logs, not
independently re-verified by this repository:** Cursor Desktop IDE dispatches two separate hook
events for a single shell action — `preToolUse` (carries the full command; a guard correctly
evaluates and denies when the path is protected) and, roughly a second later,
`beforeShellExecution`, which in some invocations arrives with a fully empty payload
(`tool_name: ""`, `tool_input: {}`). With nothing to evaluate, the empty payload defaults to
*allow*, and the underlying shell command executes despite the prior `preToolUse` deny.

Across a full session: 58 total shell-action attempts, 20 total empty-payload
`beforeShellExecution` events, of which 6 were confirmed exploitable bypasses (the empty payload
coincided with the exact command `preToolUse` had just denied) and 14 were unrelated internal
Cursor commands on non-protected paths — harmless noise, not bypasses. One bypass's request ID is
recorded in that project as `a1-3fa6-445d-b3cb-6e57bed3edee`.

By contrast, Cursor CLI — a different Cursor surface from the Desktop IDE — never bypassed the
guard in that investigation, including after an explicit conversational override attempt
("override protected path `docs/protected/`"): the technical hook held even when the agent had
socially accepted the override. That contrast is itself evidence for this repository's core
point: a prompt-level rule the agent socially accepts is not the same thing as a technical gate
that holds regardless of what the agent accepts.

These figures are self-reported by the companion project's author; this repository has not
independently re-verified them against that project's raw logs. See that repository directly for
its own evidence grading.
