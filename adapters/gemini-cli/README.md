# Gemini CLI adapter — domain skills

Companion skills that specialize [`PROTOCOL.md`](../../PROTOCOL.md) for real workflows. They are
the *domain layer*: the universal conduct rules (anti-sycophancy, reality filter,
state-verification) live in `PROTOCOL.md`; these files add the editorial, ethical, data-handling,
or engineering invariants of each domain.

| Skill | File | Scope |
|-------|------|-------|
| `bio-ruiz-hernandez` | [`bio-ruiz-hernandez/SKILL.md`](bio-ruiz-hernandez/SKILL.md) | Scientific writing & review (biochemical engineering / bioprocesses): evidence labels, microbial nomenclature, clean Unicode notation, single bold citation, **n=10 audit** (5 content + 4 ethics + 1 format passes), AI-in-research ethics (tool-not-author, privacy, traceability, bilingual transparency notice), EPS→JPG via Ghostscript. |
| `numerical-data-analysis` | [`numerical-data-analysis/SKILL.md`](numerical-data-analysis/SKILL.md) | Numerical data & ML: strict anti-data-leakage rules (`fit` on Train only, pipelines, SMOTE inside CV), scaler selection by distribution and algorithm, Julia/SciML directive for ODE/kinetic modeling, `fg-data-profiling` migration. |
| `computational-systems` | [`computational-systems/SKILL.md`](computational-systems/SKILL.md) | General software/systems engineering: reality filter applied to code (no hallucinated API surfaces, no unexecuted test/build state reported as passing), anti-sycophancy in code review, hard rules against OWASP-class vulnerabilities, over-engineering and destructive git operations, plus dependency/supply-chain, CI/CD, and architecture guidance. Domain-general — not tied to one researcher's workflow, same generality as `numerical-data-analysis`. |

**Language note:** the skills are written in Spanish, reproduced undiluted from the working
source — same convention as [`examples/ml-swarm/`](../../examples/ml-swarm/).

## Installation (Gemini CLI)

Copy both skill folders into your Gemini CLI skills directory:

```bash
# Windows
xcopy /E /I adapters\gemini-cli\bio-ruiz-hernandez "%USERPROFILE%\.gemini\config\skills\bio-ruiz-hernandez"
xcopy /E /I adapters\gemini-cli\numerical-data-analysis "%USERPROFILE%\.gemini\config\skills\numerical-data-analysis"
xcopy /E /I adapters\gemini-cli\computational-systems "%USERPROFILE%\.gemini\config\skills\computational-systems"

# Linux / macOS
mkdir -p ~/.gemini/config/skills
cp -r adapters/gemini-cli/bio-ruiz-hernandez ~/.gemini/config/skills/
cp -r adapters/gemini-cli/numerical-data-analysis ~/.gemini/config/skills/
cp -r adapters/gemini-cli/computational-systems ~/.gemini/config/skills/
```

Each skill activates from its frontmatter `description`; no further configuration is needed.
`bio-ruiz-hernandez` loads `numerical-data-analysis` automatically when a task involves
numerical analysis (see its §6, "Skills vinculados"). `computational-systems` is independent of
both — install it alone if your workflow is general software engineering rather than bioprocess
research.

## Environment prerequisites (optional, task-dependent)

- **Ghostscript ≥ 10** (`gswin64c.exe`) — only for EPS→JPG figure conversion. The skill
  searches PATH and standard install locations; no hardcoded path is required.
- **Python 3.10–3.13** with `scikit-learn`, `feature-engine`, `fg-data-profiling` — only for
  the numerical skill. Note the documented `setuptools==80.9.0` pin (see the ⚠️ alert inside
  `numerical-data-analysis/SKILL.md` §4): `fg-data-profiling` needs `pkg_resources`, removed
  from `setuptools` ≥ 81.
- **Julia ≥ 1.10** — only when the Julia/SciML directive for ODE modeling applies. The skill
  checks `julia --version` before proposing it.

## See also

- [`examples/bioprocess-research/`](../../examples/bioprocess-research/) — how the two bioprocess
  skills map onto `PROTOCOL.md` as a domain specialization.
- [`examples/computational-systems/`](../../examples/computational-systems/) — how
  `computational-systems` maps onto `PROTOCOL.md` for general software engineering.
