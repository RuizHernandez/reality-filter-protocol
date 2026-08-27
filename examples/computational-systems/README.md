# Example specialization: computational systems / software engineering domain layer

**This is an example, not a rule.** It shows how the universal core in
[`PROTOCOL.md`](../../PROTOCOL.md) was specialized for **computational systems engineering** —
general software development (backend, frontend, infrastructure, distributed systems), not one
research domain. Copy it as a template for your own domain, not as something this repository
requires you to adopt.

The full working artifact lives in
[`adapters/gemini-cli/computational-systems/`](../../adapters/gemini-cli/computational-systems/)
as an installable Gemini CLI skill (in Spanish, same convention as the other domain skills in
this repository):

- **`computational-systems`** — engineering protocol: reality filter applied to code (no
  hallucinated API surfaces, no reporting unexecuted test/build state as passing, dependency
  versions checked against the real lockfile), anti-sycophancy in code review, hard rules
  against OWASP-class vulnerabilities, over-engineering, and destructive git operations, plus
  dependency/supply-chain, CI/CD, and architecture-documentation guidance.

Unlike `bio-ruiz-hernandez`, this skill is not written for one researcher's workflow — it
generalizes the same way `numerical-data-analysis` does, as domain-wide engineering discipline
usable by any computational-systems engineer, not a personal editorial voice.

## How the specialization maps to the protocol

| Universal core (`PROTOCOL.md`) | Domain layer (this skill) |
|---|---|
| Reality filter — verify before asserting | No hallucinated function signatures, CLI flags, or library behavior; a test/build/pipeline is only "passing" after being executed in-session with a cited command and exit code; dependency versions checked against the real manifest, not memory |
| Anti-sycophancy (both directions) | No approving a PR by inertia and no fabricating objections to look rigorous; every review states what was checked and against what criteria |
| State-verification over authority | A red CI pipeline or merge conflict on a branch the agent drives is pending work, not a waiting state; no skipping pre-commit hooks to force a commit |
| — (domain addition) | Hard rules against OWASP-class vulnerabilities, over-engineering, unverified completeness claims, destructive git operations (`--force`, `reset --hard`, history rewrites) without explicit authorization, and fabricated performance/coverage metrics |

## Why this domain layer exists

The core protocol governs general agent conduct, but it does not answer the questions that
appear once it is taken into everyday software engineering: what counts as a verified test
result versus a claimed one? when is a code review actually adversarial rather than a rubber
stamp? which git operations require explicit authorization rather than being run on the agent's
own judgment? `computational-systems` answers those the same way `bio-ruiz-hernandez` answers the
analogous questions for scientific writing and `numerical-data-analysis` answers them for
numerical/ML work — by turning the universal reality-filter and anti-sycophancy rules into
structural checks specific to the domain, rather than leaving them as abstract principles a model
has to re-derive on every task.
