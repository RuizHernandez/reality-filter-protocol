# Lineage

## Public release vs. protocol name

This repository publishes **Filtro de Realidad v5 + Anti-Sycophancy** as a public,
model-agnostic protocol. The protocol's own name ("v5") and this repository's release version
(`v1.0.0`) are two different counters — do not conflate them. The protocol keeps the name it had
privately; the release starts fresh at semver `v1.0.0` because it is the first public release,
not the fifth.

## Where "v5" came from

The protocol originated as an internal instruction file for a private multi-agent engineering
project: a multi-agent swarm building a machine-learning software application ("ML").
Internally, it went through informal revisions referred to as v1 through v5.

**[Unverified]** The specific content of, or reasoning behind, revisions v1 through v4 was not
preserved in a form suitable for public documentation, and this repository does not attempt to
reconstruct it. What is verified is the content of v5 itself.

## Source provenance (verified)

- Source repository: the Cerebro-Queen DevSwarm workspace (private).
- Source file: `docs/devswarm/PROTOCOL.md`.
- Source commit: `ab08d13408add5c46c665e9e58dcb5684e662c53`.
- Extraction date: 2026-07-22.

## What changed for the public release

- The domain-agnostic rules (source §1, and the domain-agnostic parts of source §2) were
  generalized and written into [`PROTOCOL.md`](PROTOCOL.md) as the universal core.
- The domain-specific content (source §2's specific bullets) and the
  Queen/Primary orchestration topology (source §3) were moved **undiluted** — unedited, in their
  original Spanish — into [`examples/ml-swarm/`](examples/ml-swarm/), explicitly labeled
  as an example, not a rule.
- No wording in the universal core was invented for this release: `PROTOCOL.md` §1–§3 is a
  direct generalization of the source's §1, and the example files reproduce source §2/§3 without
  paraphrasing.

## Versioning going forward

Future changes to `PROTOCOL.md`'s universal core should bump this repository's release semver
(`v1.0.0` → `v1.1.0`/`v2.0.0` per normal semver rules) independently of whether the protocol's
own name ever changes. If the protocol's name changes (e.g. a future "v6"), record the reason
here at the time it happens — do not backfill a reason after the fact.

## Release `v1.2.0` — 2026-07-24

**[Empirical]** Post-incident protocol bump approved after the DevSwarm rubric-capture case
(commit `776f042` in the DevSwarm workspace) and the Cursor IDE hook audit. Source rubric:
`RFv5_Mejoras` (internal session 2026-07-23; see DevSwrmxML `_rfv5_mejoras_extract.txt`).

**Included (items 1–26 + 30 confirmed):** SHA-anchored contracts; specification immutability;
stash identifier stability; audit document persistence; pipeline ordering gates;
single-writer-per-worktree; sign-off provenance; fabricated-deliverable detection; runtime model
logging; pool-exhaustion notification; inverted anti-sycophancy reinforcement; hook fail-closed
rules (empty `beforeShellExecution` payloads, UTF-8 BOM strip on Windows CLI hooks, incomplete hook
coverage); defense-in-depth; `[Empirical]` label; claim-language rule; visual-artifact n=5
self-check; evaluator-immunity principle; evidence hierarchy; formal-reply label requirement;
mandatory correction format; cited-figures visibility; no unsolicited rewrites; technical HOLD
(§3.10); future pre-commit / SHA-reconciliation roadmap (§3.11).

**Excluded (bio items 27–29):** laboratory biochemistry style directives — routed to the
`bio-researchruiz-hernandez` skill only, not the universal core.

**Stash evidence (wrong-branch WIP, item 30):** On the original DevSwarm machine,
`stash@{8}` — message `WIP P2 sobre rama P1 equivocada`, branch `ux/p1-progressive-disclosure` —
contains uncommitted P2 UI work (`93 insertions / 30 deletions` in `app/ui/context.py` and
`app/ui/shell.py`). Companion stash `stash@{6}` (`coder-P2-wip-sobre-rama-P1-NO-COMMITEAR`) on
the same branch. Full empirical record: DevSwrmxML `Evidence/devswarm-p2/VERIFICATION-ITEM-30.md`.
`stash@{n}` indices are unstable; locate by message, not index.

## Release `v1.3.0` — 2026-08-05

**[Empirical]** Cost/benefit optimization of Rule 2's evidence labels: short-form codes
(`[E]`/`[I]`/`[S]`/`[U]`) are now the default in agent output, with a legend declared once per
session instead of spelling out the word on every claim; a no-redundant-retagging rule was added
so a claim chain is tagged once at the point its evidence level is set or changes, not on every
restatement. Full words are still required in formal/human-facing documents. No §1–§5 rule
semantics changed — this is a token-cost optimization of the label's surface form only.

**[Empirical]** Six of the v1.2.0 artifact-layer rules (specification immutability, technical
HOLD, fabricated-deliverable detection, SHA-anchored contracts, stash identifier stability, and an
incident-derived phase/branch gate) were implemented as executable git hooks and validated against
eleven scenarios replaying the `776f042` incident's artifact-level shape in a disposable synthetic
repository — 11/11 pass. This closes part of the §3.11 roadmap item empirically; it does not
validate Rules 1–2 (anti-sycophancy, reality filter), which require a live-agent evaluation per
`CONTRIBUTING.md`. See `validation/REPORT.md` for method, results, and limitations.

## Release `v1.3.1` — 2026-08-25

**[Empirical]** Citation refresh, sourced via Elicit paper search and cross-checked directly
against arXiv/DOI resolvers (not by semantic-search relevance alone): five citations added to
`PROTOCOL.md`'s "Grounded in research" section —

- Young (2026) arXiv:2603.22582 — CoT-faithfulness across 12 open-weight reasoning models
  (41,832 runs), added to Rule 2.
- MacDiarmid et al. (2025) arXiv:2511.18397 — production-RL reward-hacking generalizing to
  sabotage/alignment-faking, added alongside Denison et al. (2024) in the v1.2 incident section.
- Yang et al. (2025) arXiv:2512.16279 (QuadSentinel) — flagged as existing prior art against the
  §3.11 "future technical enforcement" roadmap item, not yet adopted as a rule.
- Kraidia et al. (2026, *Scientific Reports*) and Yan et al. (2026) — quantitative multi-agent
  persuasion/misinformation-propagation results, added to support §5's evaluator-immunity
  principle beyond the single DevSwarm anecdote.

**[Unverified]** The existing Wooldridge (AAMAS) DOI:10.65109/ktwn2820 citation resolves (HTTP
302 → dl.acm.org) but its title could not be confirmed past the Cloudflare interstitial on the
resolved page in this pass; left as a `TODO` in `PROTOCOL.md` for the author to fill in from their
own record rather than have a title backfilled by inference.

No `PROTOCOL.md` §1–§5 rule text changed — this release touches only the citation list and this
changelog. Merged via PR #1 `citation-refresh-2026-08-25` (commit `9bd6f71`, same PR as the
Antigravity resync below); `PROTOCOL.md`'s Status line and changelog entry are updated to match.

## Adapter resync — `adapters/antigravity/SKILL.md`, 2026-08-25

**[Empirical]** `adapters/antigravity/SKILL.md` had drifted: its own frontmatter and footer read
"Synced to PROTOCOL.md v1.2.0" while `README.md` names `v1.3.0` as canonical. Concretely, it
still used full-word epistemic labels (`[Empirical]`/`[Inference]`/`[Speculation]`/`[Unverified]`)
everywhere instead of the `[E]`/`[I]`/`[S]`/`[U]` short-form default that v1.3.0 introduced, it
reproduced §3.1–§3.10 verbatim (all DevSwarm-specific worktree/stash/SHA subsections) instead of
condensing them, and it was missing §3.11. File size was 9.5 KB against 2.5–2.7 KB for the
Claude Code and Cursor adapters, for the same three universal rules.

**Fix applied:** resynced to `v1.3.0` using the Cursor adapter's density pattern — §1–§5 each
condensed to one paragraph, §3.1–§3.11 folded into a single sentence naming every enforced item
rather than a subsection per item, short-form tags as default. The three Antigravity-specific
"Applying this" bullets (`invoke_subagent`/`send_message` verification, native-tool verification,
artifact integrity) were kept and lightly reworded to match the other adapters' "Applying this in
X" heading — that section is platform-specific value, not duplication, and the audit that found
this drift did not flag it. Net size: 9.5 KB → ~2.6 KB. No rule semantics changed; this is a
sync and compression fix only. Merged via PR #1 `citation-refresh-2026-08-25` (commit `9bd6f71`);
this is the adapter's official v1.3.0 sync.
