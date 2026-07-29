# Reality Filter v5 + Anti-Sycophancy

**English** | [Español](README.es.md)

A public, model-agnostic, citable conduct protocol for AI coding assistants and multi-agent
swarms.

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](LICENSE)

**Protocol name:** *Filtro de Realidad v5* (preserved from its private origin). **Release
version:** `v1.2.0` (see [LINEAGE.md](LINEAGE.md) for why the protocol name and release semver
are different counters). **Latest archived/citable DOI:**
[10.5281/zenodo.21499994](https://doi.org/10.5281/zenodo.21499994) — this covers the `v1.0.0`
snapshot; a `v1.2.0`-specific DOI will be added here once Zenodo mints it.

## What this is

Three domain-agnostic conduct rules — anti-sycophancy in both directions, verify-before-you-claim
reality filtering, and state-verification-over-authority for orchestrator/subordinate agent
topologies — written once in [`PROTOCOL.md`](PROTOCOL.md) and adapted for specific platforms:

- **Canonical:** [`PROTOCOL.md`](PROTOCOL.md)
- **Claude Code:** [`adapters/claude-code/SKILL.md`](adapters/claude-code/SKILL.md)
- **Antigravity:** [`adapters/antigravity/SKILL.md`](adapters/antigravity/SKILL.md)
- **Cursor:** [`adapters/cursor/reality-filter.mdc`](adapters/cursor/reality-filter.mdc)
- **Gemini CLI (domain skills):** [`adapters/gemini-cli/`](adapters/gemini-cli/)
  - **`bio-ruiz-hernandez`** — the flagship specialization, and the clearest demonstration of
    what a domain layer adds beyond a plain port of the protocol. Three things make it
    different: (1) it generalizes the n=5 visual self-check into an **n=10 manuscript audit**
    — five content passes, four ethics passes, one format pass — applied to every draft;
    (2) it adds an **AI-in-research ethics layer** the core protocol does not cover: the agent
    acts as a tool and never as an author, sensitive data must be anonymized and computed
    locally, every analytical result ships with its reproducible code, and a bilingual
    (ES/EN) transparency notice declares AI involvement — so the skill doubles as a
    journal-ready AI-use policy for manuscripts; (3) it enforces hard editorial invariants
    (microbial nomenclature in italics, clean Unicode notation, single bold citation per
    block, EPS figure handling via watermark-free Ghostscript).
  - **`numerical-data-analysis`** — anti-data-leakage rules (`fit` on Train only, mandatory
    pipelines, SMOTE inside CV folds), scaler selection by distribution and algorithm, and a
    Julia/SciML directive for ODE kinetic modeling of bioprocesses.
- **Other platforms** (ChatGPT, Windsurf, …): no first-party adapter yet — see
  [CONTRIBUTING.md](CONTRIBUTING.md) for a porting guide.

It is behavioral prose, not executable code. Its value is portability of conduct rules across
models, and citability as an academic artifact.

## Why this exists

Frontier models are already trained toward calibration and honesty. So the *anti-sycophancy*
and *verify-before-you-claim* halves of this protocol mostly reinforce behavior a good base
model already leans toward — we make no claim to have invented them.

The part a base model does **not** do on its own is **explicit authority boundaries between
an orchestrating agent and its subordinates** — who may decide, who may only report, and the
rule that the orchestrator verifies real state (git, logs, files) instead of trusting any
agent's narrative, *including its own*. This governance layer is the protocol's actual
contribution: not novel in the abstract (least-privilege and orchestrator-worker patterns
long predate it), but a portable, prompt-level articulation of it for LLM agent swarms.

### The social half of a two-part lesson

A conversational instruction is **not** technical enforcement. A prompt that says "the
subordinate may not act without approval" constrains a cooperative model; it does not *stop*
a determined or malfunctioning one — only a real gate (a `preToolUse` hook, an ACL, a sandbox)
does that.

- **This protocol** demonstrates the *social/prompt* half.
- A parallel adversarial investigation into Cursor's hook system
  ([Cursor-Hooks-Minimal-Test](https://github.com/RuizHernandez/Cursor-Hooks-Minimal-Test))
  demonstrated the *technical* half — and why it's non-optional: a `beforeShellExecution` hook
  arriving with an empty payload defaulted to *allow*, letting a shell command run that a prior
  `preToolUse` had already denied. The prompt-level rule is necessary; it is not sufficient.

Use this protocol for the social half. Do not mistake it for the technical one.

## Worked examples

[`examples/ml-swarm/`](examples/ml-swarm/) shows the universal core specialized for a 
real project: a machine-learning software application built by a 7-agent swarm. It is reproduced
undiluted from the private source, labeled as an example — copy it as a template, not as a
required rule.

[`examples/bioprocess-research/`](examples/bioprocess-research/) shows the same specialization
for a research domain: biochemical-engineering scientific writing (`bio-ruiz-hernandez`, with
its n=10 audit and AI-in-research ethics) and numerical data analysis
(`numerical-data-analysis`, with anti-leakage rules and a Julia/SciML directive), implemented
as two installable Gemini CLI skills ([`adapters/gemini-cli/`](adapters/gemini-cli/)).

## Evidence & limitations

**This is not a controlled evaluation.** There is no A/B study here — same task, rule vs.
no-rule, across multiple models. Every item below is graded by *how it was observed*, and the
grades are not equal. Conflating them would be the exact error this protocol exists to prevent.

**Tier 1 — reviewed by an independent second agent.** A separate agent (a different Claude Code
session, not the one under the rule) reviewed a transcript excerpt the user pasted into that
second conversation — not the original agent's raw session log directly — in which the original
agent describes refusing a flattering "you detected this bug" attribution and tagging it
`[unverified]`. The second agent confirmed that self-description was well-calibrated: it
correctly distinguished observable behavior from an unverifiable introspective causal claim, not
that the underlying event occurred exactly as described. This is transcript-as-relayed-by-the-user
verification, not direct log access.

**Tier 2 — self-report by the agent under the rule, not independently verified.** The same agent
reports two further incidents from an earlier session that no third party reviewed: a self-issued
accusation retracted once git evidence contradicted it, and a near-miss false rejection caught by
re-checking the source. We verified that PROTOCOL.md exists with this content; we did **not**
verify that these specific events occurred as described. Treat as self-report.

**Tier 3 — user self-report of daily use.** The author runs the protocol in a persistent desktop
prompt and observes the model visibly invoking it outside the original project ("per your reality
filter and anti-sycophancy…") during ordinary browsing/coding. User self-report, not measurement.

**Context, not a controlled trial:** these observations come from a multi-day, multi-agent
engineering session (a 7-agent orchestration building a computational-chemistry ML tool) where a
real governance failure occurred during normal work — not a deliberate red-team. (The genuinely
*adversarial* work is the separate
[Cursor hooks investigation](https://github.com/RuizHernandez/Cursor-Hooks-Minimal-Test), which
*was* a deliberate probe.)

What we explicitly **cannot** claim: that the rule *caused* any given behavior rather than the
base model producing it anyway. Separating the two would require the controlled study we have not
run. Contributions of such a study are welcome.

See [EVIDENCE.md](EVIDENCE.md) for the long-form version of this section, including the
chain-of-evidence detail behind Tier 1 and the quantified Cursor-hooks findings behind the
"technical enforcement half" reference above.

## How to cite

```
Ruiz-Hernández, I. (2026). Filtro de Realidad v5 + Anti-Sycophancy:
A model-agnostic conduct protocol for AI coding assistants (v1.0.0).
Zenodo. https://doi.org/10.5281/zenodo.21499994
```

`CITATION.cff` is also present for GitHub's "Cite this repository" feature.

- ORCID: [0000-0001-8075-482X](https://orcid.org/0000-0001-8075-482X)
- Google Scholar: `user=BvW7db0AAAAJ`
- ResearchGate: `Itan-Ruiz-Hernandez`

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) — porting the protocol to a new platform, or contributing
a controlled evaluation this repository does not yet have.

## Provenance

See [LINEAGE.md](LINEAGE.md) for where this protocol came from and how the public release maps
to its private version history.

## License

[CC BY 4.0](LICENSE). Attribution travels with copies.

## Related

- [Cursor-Hooks-Minimal-Test](https://github.com/RuizHernandez/Cursor-Hooks-Minimal-Test) — the
  technical enforcement half of this two-part lesson.
