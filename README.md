# Reality Filter v5 + Anti-Sycophancy

**English** | [Español](README.es.md)

A public, model-agnostic, citable conduct protocol for AI coding assistants and multi-agent
swarms.

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](LICENSE)

**Protocol name:** *Filtro de Realidad v5* (preserved from its private origin). **Release
version:** `v1.4.0` (see [LINEAGE.md](LINEAGE.md) for why the protocol name and release semver
are different counters). **Latest archived/citable DOI:**
[10.5281/zenodo.21499994](https://doi.org/10.5281/zenodo.21499994) — this covers the `v1.0.0`
snapshot; a `v1.4.0`-specific DOI will be added here once Zenodo mints it.

## Included domain skills

Domain skills are the layer above the universal core: `PROTOCOL.md` governs conduct, each skill
adds the invariants of one working domain. Two cover the biochemical-engineering / bioprocess
research workflow of Dr. Itan Homero Ruiz-Hernández; two cover software/systems and security work.

- **`bio-ruiz-hernandez`** — the flagship specialization, and the clearest demonstration of
  what a domain layer adds beyond a plain port of the protocol. Three things make it
  different: (1) it generalizes the n=5 visual self-check into an **n=10 manuscript audit** —
  five content passes, four ethics passes, one format pass — applied to every draft; (2) it
  adds an **AI-in-research ethics layer** the core protocol does not cover: the agent acts as
  a tool and never as an author, sensitive data must be anonymized and computed locally,
  every analytical result ships with its reproducible code, and a bilingual (ES/EN)
  transparency notice declares AI involvement — so the skill doubles as a journal-ready
  AI-use policy for manuscripts; (3) it enforces **hard editorial invariants** (microbial
  nomenclature in italics, clean Unicode notation, single bold citation per block, EPS figure
  handling via watermark-free Ghostscript).
- **`numerical-data-analysis`** — anti-data-leakage rules (`fit` on Train only, mandatory
  pipelines, SMOTE inside CV folds), scaler selection by distribution and algorithm, and a
  Julia/SciML directive for ODE kinetic modeling of bioprocesses.
- **`computational-arch`** — the software/systems layer, and the first domain skill written for
  this repository rather than extracted from a private workflow. Its distinguishing rule is a
  mandatory **environment preflight**: the toolchain is detected, never assumed, which
  generalizes the ad-hoc checks the bio skills already perform. It then adds the failure modes
  specific to software: APIs and package names must be verified against the *installed* version
  and the official registry (an invented package name is a live attack surface —
  *slopsquatting*); "the tests pass" and "X is faster" require an executable trace (command,
  exit code, log path; n runs with dispersion) or they are `[U]`/`[S]`; concurrency claims cap
  at `[I]` because code with a race condition passes most runs; and destructive operations show
  their blast radius before running. It also states plainly that `[E]` means *empirically
  verified*, never *secure* — a clean static-analysis run is evidence about the tool, not the code.
- **`cybersecurity`** — security work, **defensive and authorized only**. It deliberately inverts
  `bio-ruiz-hernandez`'s layout: there the ethics layer is §5, here it is **§1**, because in
  research ethics governs how a result is reported, while in security it governs whether the
  action may run at all. §1 requires authorization and scope to be established before anything
  else, treats scope as a hard boundary that is never self-extended, mandates lab isolation for
  untrusted code, and covers responsible disclosure and third-party data. The rest applies the
  reality filter to security's own failure modes: CVE/CWE/advisory identifiers verified against
  authoritative databases before citing (models invent them); a finding without a documented
  reproduction stays `[S]`, and "the scanner reported it" is `[I]`, since false positives are the
  normal case; severity must be argued in *this* deployment's context rather than inherited from
  an advisory; and "no vulnerabilities found" is a statement about coverage, never about the system.

## What this is

Three domain-agnostic conduct rules — anti-sycophancy in both directions, verify-before-you-claim
reality filtering, and state-verification-over-authority for orchestrator/subordinate agent
topologies — written once in [`PROTOCOL.md`](PROTOCOL.md) and adapted for specific platforms:

- **Canonical:** [`PROTOCOL.md`](PROTOCOL.md)
- **Claude Code:** [`adapters/claude-code/SKILL.md`](adapters/claude-code/SKILL.md)
- **Antigravity:** [`adapters/antigravity/SKILL.md`](adapters/antigravity/SKILL.md)
- **Cursor:** [`adapters/cursor/reality-filter.mdc`](adapters/cursor/reality-filter.mdc)
- **Gemini CLI (domain skills):** [`adapters/gemini-cli/`](adapters/gemini-cli/) — bioprocess
  research editorial + numerical data-analysis skills (see **Included domain skills** above)
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

The two domain skills exist for the same reason. The core protocol governs general agent
conduct, but it does not answer the questions that appear when it is taken into real
research: who signs the interpretation of a result? how do you stop a model from reporting
data-leakage-inflated metrics as valid? what format does a journal demand?
**`bio-ruiz-hernandez`** matters because it turns generic honesty into *operational academic
integrity*: without its ethics layer, a perfectly "honest" agent can still write conclusions
while simulating authorship, accept sensitive data unanonymized, or hand over numbers with no
code backing them. **`numerical-data-analysis`** matters because the most expensive error in
applied ML is not a bad model but a good model *measured wrong*: data leakage silently
inflates metrics, and no truthfulness label can detect that on its own — it takes structural
rules (`fit` on Train only, mandatory pipelines) that make it impossible by construction.

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

**What is actually executable.** Two harnesses in `validation/` run real commands and report
real exit codes: `replay_incident.sh` (13/13) replays the incident's artifact-level shape against
git hooks implementing §3.1/§3.2/§3.3/§3.8/§3.10, and `peer_verification_suite.sh` (8/8) exercises
the §3.12 peer-verification checker. `scripts/check-citations.sh` resolves the bibliography's
identifiers, and `scripts/sync-check.sh` catches version drift between this file, `PROTOCOL.md`,
`LINEAGE.md` and the adapters. All four run in CI. **None of them tests a model**: they test
artifact-layer and document-layer controls. The behavioral claims above are still Tier 1–3
observations, not measurements — see `validation/REPORT.md` for what each harness does and does
not establish.

**Context, not a controlled trial:** these observations come from a multi-day, multi-agent
engineering session (a 7-agent orchestration building a machine-learning software application) where a
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
