---
name: rfp-meta-orchestrator
description: "Meta-skill for the Reality Filter Protocol domain layer. Loads the correct domain specialization based on task type and resolves conflicts between skills. Use this when the task spans multiple domains (e.g., writing a paper that includes data analysis + code + security review)."
---

# Meta-orchestrator for RFP domain skills

**Canonical source:** [`PROTOCOL.md`](../../../PROTOCOL.md) at the repository root. This meta-skill governs when to load which domain skill and how to resolve conflicts between them. It adds no domain rules of its own — if it and `PROTOCOL.md` ever disagree, `PROTOCOL.md` is correct.

## Activation rules

| Task signal | Primary skill | Secondary skill | Conflict resolution |
|---|---|---|---|
| Writing/editing a scientific manuscript | `bio-ruiz-hernandez` | `numerical-data-analysis` (if data is cited) | Editorial rules (bio) prevail over data presentation format |
| Building a software artifact | `computational-arch` | `cybersecurity` (if security review is needed) | `cybersecurity` §1 (authorization/scope) is a hard gate; if it fails, stop |
| Analyzing a dataset for a paper | `numerical-data-analysis` | `bio-ruiz-hernandez` (for result reporting) | Data rules (fit on Train, no leakage) prevail over narrative convenience |
| Security audit of existing code | `cybersecurity` | `computational-arch` (environment/tooling) | `cybersecurity` §1 (authorization/scope) is a hard gate |

## Cross-skill invariant

When two skills are active, `PROTOCOL.md` §1–§6 is the universal arbiter. Domain-specific rules never override the core protocol. If `computational-arch` §2 says "verify the package in the registry" and `cybersecurity` §2 says "verify the CVE against the authoritative database", both apply independently — they are additive, not competing.

When a task fits no row, load the skill whose domain the deliverable belongs to, not the one whose tools the task uses.

---

*Domain adapter of `PROTOCOL.md` v1.5.0 — Canonical DOI: [10.5281/zenodo.21499994](https://doi.org/10.5281/zenodo.21499994)*
