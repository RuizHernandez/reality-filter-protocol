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
