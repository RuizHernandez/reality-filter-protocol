# Gemini CLI adapter — domain skills

Companion skills that specialize [`PROTOCOL.md`](../../PROTOCOL.md) for real working domains.
They are the *domain layer*: the universal conduct rules (anti-sycophancy, reality filter,
state-verification) live in `PROTOCOL.md`; these files add the editorial, ethical, technical,
and data-handling invariants of each domain.

Two of them cover a **biochemical engineering / bioprocesses** research workflow; the third
covers **software and systems** work.

| Skill | File | Scope |
|-------|------|-------|
| `bio-ruiz-hernandez` | [`bio-ruiz-hernandez/SKILL.md`](bio-ruiz-hernandez/SKILL.md) | Scientific writing & review: evidence labels, microbial nomenclature, clean Unicode notation, single bold citation, **n=10 audit** (5 content + 4 ethics + 1 format passes), AI-in-research ethics (tool-not-author, privacy, traceability, bilingual transparency notice), EPS→JPG via Ghostscript. |
| `numerical-data-analysis` | [`numerical-data-analysis/SKILL.md`](numerical-data-analysis/SKILL.md) | Numerical data & ML: strict anti-data-leakage rules (`fit` on Train only, pipelines, SMOTE inside CV), scaler selection by distribution and algorithm, Julia/SciML directive for ODE/kinetic modeling, `fg-data-profiling` migration. |
| `computational-arch` | [`computational-arch/SKILL.md`](computational-arch/SKILL.md) | Software & systems: mandatory **environment preflight** (detect, never assume), anti-hallucination rules for APIs and dependencies (verify against the *installed* version; registry check before adding a package, against slopsquatting), executable evidence for test/build and performance claims, concurrency claims capped at `[I]`, irreversible-operation gate. |

**Language note:** all three skills are written in Spanish. The two bioprocess skills are
reproduced undiluted from the working source — same convention as
[`examples/ml-swarm/`](../../examples/ml-swarm/). `computational-arch` is **newly authored for
this repository**, not extracted from a prior private workflow; it follows the same language
convention but carries no such provenance claim.

## Installation (Gemini CLI)

Copy the skill folders you need into your Gemini CLI skills directory (they are independent —
install only the domains you work in):

```bash
# Windows
xcopy /E /I adapters\gemini-cli\bio-ruiz-hernandez "%USERPROFILE%\.gemini\config\skills\bio-ruiz-hernandez"
xcopy /E /I adapters\gemini-cli\numerical-data-analysis "%USERPROFILE%\.gemini\config\skills\numerical-data-analysis"
xcopy /E /I adapters\gemini-cli\computational-arch "%USERPROFILE%\.gemini\config\skills\computational-arch"

# Linux / macOS
mkdir -p ~/.gemini/config/skills
cp -r adapters/gemini-cli/bio-ruiz-hernandez ~/.gemini/config/skills/
cp -r adapters/gemini-cli/numerical-data-analysis ~/.gemini/config/skills/
cp -r adapters/gemini-cli/computational-arch ~/.gemini/config/skills/
```

Each skill activates from its frontmatter `description`; no further configuration is needed.
`bio-ruiz-hernandez` loads `numerical-data-analysis` automatically when a task involves
numerical analysis (see its §6, "Skills vinculados").

## Environment prerequisites (optional, task-dependent)

- **Ghostscript ≥ 10** (`gswin64c.exe`) — only for EPS→JPG figure conversion. The skill
  searches PATH and standard install locations; no hardcoded path is required.
- **Python 3.10–3.13** with `scikit-learn`, `feature-engine`, `fg-data-profiling` — only for
  the numerical skill. Note the documented `setuptools==80.9.0` pin (see the ⚠️ alert inside
  `numerical-data-analysis/SKILL.md` §4): `fg-data-profiling` needs `pkg_resources`, removed
  from `setuptools` ≥ 81.
- **Julia ≥ 1.10** — only when the Julia/SciML directive for ODE modeling applies. The skill
  checks `julia --version` before proposing it.
- **`computational-arch` has no fixed prerequisites by design.** Its §1 makes environment
  detection the first step of every task rather than a documented assumption, so the toolchain
  it needs is whatever the task at hand needs — verified on the spot, with a declared fallback
  when something is missing. It generalizes the ad-hoc checks the other two skills already do
  (Ghostscript PATH search, `julia --version`, `pip show`) into a named contract.

## See also

- [`examples/bioprocess-research/`](../../examples/bioprocess-research/) — how these two
  skills map onto `PROTOCOL.md` as a domain specialization.
