# Example specialization: bioprocess research domain layer

**This is an example, not a rule.** It shows how the universal core in
[`PROTOCOL.md`](../../PROTOCOL.md) was specialized for one real research workflow — scientific
writing and numerical data analysis in **biochemical engineering / bioprocesses**. Copy it as a
template for your own domain, not as something this repository requires you to adopt.

The full working artifacts live in [`adapters/gemini-cli/`](../../adapters/gemini-cli/) as two
installable Gemini CLI skills (in Spanish, reproduced undiluted):

- **`bio-ruiz-hernandez`** — editorial protocol: evidence labels, microbial nomenclature,
  clean Unicode notation, single bold citation per thematic block, EPS figure handling.
- **`numerical-data-analysis`** — data protocol: anti-data-leakage rules, scaler selection,
  pipeline discipline, Julia/SciML directive for ODE/kinetic modeling.

## How the specialization maps to the protocol

| Universal core (`PROTOCOL.md`) | Domain layer (these skills) |
|---|---|
| Reality filter — tag uncertainty | `[Empírico]` / `[Inferencia]` / `[Especulación]` / `[No verificado]` on every claim, plus an **n=10 audit** applied to every manuscript draft |
| Anti-sycophancy (both directions) | Zero flattery in reviews; if the user is wrong, say it with evidence |
| State-verification over authority | Every analytical result must ship with its reproducible code (no "black box" answers); file operations restricted to real, existing user files (Rule #22) |
| — (domain addition) | **AI-in-research ethics**: the agent is a tool, never an author; sensitive data must be anonymized and computed locally; a bilingual methodological transparency notice is attached to research documents |

## The n=10 audit in one paragraph

Every draft passes ten ordered passes: five on content (empirical data-matching, nomenclature,
cliché pruning, citation discipline, claim-evidence binding), four on ethics (inference limit,
privacy, traceability, transparency — each mapped to the ethics section of the skill), and a
final format pass. The n=10 form generalizes the n=5 visual self-check pattern referenced in
`PROTOCOL.md` adapters from figures to full manuscripts.
