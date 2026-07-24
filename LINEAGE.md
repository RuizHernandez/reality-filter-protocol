# Lineage

## Public release vs. protocol name

This repository publishes **Filtro de Realidad v5 + Anti-Sycophancy** as a public,
model-agnostic protocol. The protocol's own name ("v5") and this repository's release version
(`v1.0.0`) are two different counters — do not conflate them. The protocol keeps the name it had
privately; the release starts fresh at semver `v1.0.0` because it is the first public release,
not the fifth.

## Where "v5" came from

The protocol originated as an internal instruction file for a private multi-agent engineering
project: an "Ansys-Pyro" / "Cerebro-Queen" swarm building a computational-chemistry machine
learning tool ("PyroML"). Internally, it went through informal revisions referred to as v1
through v5.

**[Unverified]** The specific content of, or reasoning behind, revisions v1 through v4 was not
preserved in a form suitable for public documentation, and this repository does not attempt to
reconstruct it. What is verified is the content of v5 itself.

## Source provenance (verified)

- Source repository: the Cerebro-Queen DevSwarm workspace of the Ansys-Pyro project (private).
- Source file: `docs/devswarm/PROTOCOL.md`.
- Source commit: `ab08d13408add5c46c665e9e58dcb5684e662c53`.
- Extraction date: 2026-07-22.

## What changed for the public release

- The domain-agnostic rules (source §1, and the domain-agnostic parts of source §2) were
  generalized and written into [`PROTOCOL.md`](PROTOCOL.md) as the universal core.
- The domain-specific chemistry content (source §2's PyroML-specific bullets) and the
  Queen/Primary orchestration topology (source §3) were moved **undiluted** — unedited, in their
  original Spanish — into [`examples/pyroml-swarm/`](examples/pyroml-swarm/), explicitly labeled
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
(commit `776f042` in the Ansys-Pyro workspace) and the Cursor IDE hook audit. Source rubric:
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

**Stash evidence (wrong-branch WIP, item 30):** On the original DevSwarm machine (Ansys-Pyro repo),
`stash@{8}` — message `WIP P2 sobre rama P1 equivocada`, branch `ux/p1-progressive-disclosure` —
contains uncommitted P2 UI work (`93 insertions / 30 deletions` in `app/ui/context.py` and
`app/ui/shell.py`). Companion stash `stash@{6}` (`coder-P2-wip-sobre-rama-P1-NO-COMMITEAR`) on
the same branch. Full empirical record: DevSwrmxML `Evidence/devswarm-p2/VERIFICATION-ITEM-30.md`.
`stash@{n}` indices are unstable; locate by message, not index.
