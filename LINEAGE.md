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
thirteen scenarios replaying the `776f042` incident's artifact-level shape in a disposable
synthetic repository — 13/13 pass. This closes part of the §3.11 roadmap item empirically; it does not
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

**[Empirical]** Update, 2026-08-26: the Wooldridge (AAMAS) DOI:10.65109/ktwn2820 `TODO` above is
resolved. Title confirmed independently via the Crossref API (`api.crossref.org/works/...`) and
the Semantic Scholar Graph API (`api.semanticscholar.org/graph/v1/paper/DOI:...`), which agree:
"Rethinking Multi-agent Systems in the Era of LLMs," AAMAS 2026 (25th ICAAMAS, Paphos, Cyprus,
25–29 May 2026), IFAAMAS. `PROTOCOL.md` §Rule 3 updated to drop the `TODO` marker.

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
this drift did not flag it. Net size: 9550 → 3842 bytes (9.5 KB → 3.8 KB). No rule semantics changed; this is a
sync and compression fix only. Merged via PR #1 `citation-refresh-2026-08-25` (commit `9bd6f71`);
this is the adapter's official v1.3.0 sync.

## Release `v1.4.0` — 2026-08-26

**[Empirical]** Adds `PROTOCOL.md` §3.12 (peer verification independence) — the first §3
subsection derived from published literature rather than from an observed incident, and marked
`[Literature-derived, not incident-derived]` in the rule text itself so that §3's
incident-derived property does not quietly become false. It specializes Rule 2's "never accept a
report as state" for horizontal (peer-to-peer) topologies, which §3 previously addressed only
vertically (orchestrator ↔ subordinate).

Three drafting decisions are worth recording, because the first draft of this rule (proposed by a
third-party model review, 2026-08-26) had them the other way round:

- **Independence is defined over artifact and method, not over command text.** The draft
  prohibited re-running the sender's exact command. That contradicts §3.1, which *prescribes*
  `git show <canonical_sha>:path` — a canonical form expected to be byte-identical across agents.
  As drafted, the rule would have flagged protocol-compliant behavior. The shipped rule instead
  targets the failure that the draft's example actually illustrated: a **narrowed** read
  (`head`, `tail`, a filtered `grep`) accepted as verification of a whole-artifact claim.
- **`peer-unverified` is a log event type, not an epistemic label.** The draft introduced it as a
  fifth bracket token alongside `[E]`/`[I]`/`[S]`/`[U]`, which would have diluted the four-label
  vocabulary v1.3.0 had just settled.
- **The rule is a specialization, not a discovery.** Rule 2 already covers "a subordinate agent,
  a tool summary, or your own prior reasoning." §3.12 makes the horizontal case explicit; it does
  not add a principle.

**[Empirical]** §3.12 ships with eight executable scenarios
(`validation/peer_verification_suite.sh`, 8/8 pass, log at `validation/peer_run_2026-08-26.log`).
Every PASS/FAIL is the exit code of a real invocation of
`validation/lib/peer_verification_check.sh` against a fixture transcript. Two of the eight are
false-positive guards (canonical re-read allowed; full read allowed) and two are §4.1
fail-closed guards added after a mutation test showed the checker's first version returned 0 for
an empty or unparseable transcript. What this does **not** establish: that any agent complies
with §3.12, that a flagged claim was actually false, or that the checker is wired into any
adapter. See `validation/REPORT.md`.

**[Empirical]** New `scripts/check-citations.sh` + `scripts/citations.tsv`. The bibliography is
now checked in both directions (every citation in `PROTOCOL.md` is inventoried; every inventory
entry is still cited) and, with `--online`, every identifier is resolved against the arXiv API or
Crossref and matched against an expected title fragment. First run, 2026-08-26: **12 of 12
identifiers resolve to the expected titles; 2 citations carried no persistent identifier at all** —
Amayuelas et al. (EMNLP 2024) and Yan et al. (2026), the entry supporting the 72.50% → 14.17%
figure, the strongest quantitative claim in the bibliography. Both were recorded as `UNRESOLVED`
and printed on every run — registered debt, not an exemption.

**[Empirical]** Update, same day: both resolved. Elicit's semantic search (`mcp__Elicit__search_papers`)
matched Yan et al.'s abstract verbatim against the 72.50%/14.17% figure and, separately, surfaced
Amayuelas et al.'s exact paper by author + topic; a first web-search attempt to fill in the same
detail synthesized a plausible-looking but ungrounded venue claim ("IJCAI 2026 workshop") not
present in any of the pages it actually returned, and was discarded rather than adopted. Both
identifiers were then confirmed by direct resolution, not the search summary: the arXiv API
(`export.arxiv.org/api/query`, exact-title and author-field search) returned **Yan et al. (2026)
arXiv:2608.03421**, abstract text identical to the cited figure; Crossref's bibliographic search
returned **Amayuelas et al., DOI:10.18653/v1/2024.findings-emnlp.407**, confirming the "EMNLP
2024" venue `PROTOCOL.md` already named — *Findings of the Association for Computational
Linguistics: EMNLP 2024*. `scripts/citations.tsv` and `PROTOCOL.md`'s bibliography now carry both
identifiers. 0 of 14 citations remain unresolved.

**[Empirical]** The WebSearch synthesis discarded above is itself now Rule 2 material: `PROTOCOL.md`
§2 gains one bullet, "a search tool's own synthesis is not a resolved claim" — a search tool's
narrative summary can assert a detail (here, a venue) that appears in none of the sources it
actually returned, and must be resolved against something that specifically confirms it before
being adopted. It is deliberately tool-agnostic: it does not name a specific search provider
(Google Scholar, or any other), because `PROTOCOL.md` is meant to be portable across adapters
with different available tools — the failure mode it targets is what just happened, whichever
search tool triggers it.

**[Empirical]** Version-drift pass. Seven defects, none of which `scripts/sync-check.sh` could
see:

| File | Was | Now |
|---|---|---|
| `README.es.md` | `v1.2.0` | `v1.4.0` |
| `CITATION.cff` | `1.3.0` | `1.4.0` |
| `adapters/gemini-cli/bio-ruiz-hernandez/SKILL.md` | `v1.2.0` footer | `v1.4.0` |
| `adapters/gemini-cli/numerical-data-analysis/SKILL.md` | `v1.2.0` footer | `v1.4.0` |
| `scripts/sync-check.sh` comment | claimed the gemini-cli skills "carry no PROTOCOL.md version marker" — both carried one | comment corrected, both files now checked |
| `PROTOCOL.md` / `LINEAGE.md` scenario count | stated 11 ("eleven scenarios") | 13, matching `validation/REPORT.md` and the run log |
| `LINEAGE.md` Antigravity resync size | "9.5 KB → ~2.6 KB" | 9550 → 3842 bytes (9.5 KB → 3.8 KB), from `git show` |

Also corrected: `README.md` and `.zenodo.json` still described the source project as
"computational-chemistry", a domain reference commit `9d49480` had anonymized everywhere else to
"machine-learning software application."

`scripts/sync-check.sh` was widened to cover `README.es.md`, `CITATION.cff`, `.zenodo.json` and
both gemini-cli skills, and to cross-check the scenario count between `PROTOCOL.md`,
`LINEAGE.md` and `validation/REPORT.md`.

**Not done in this release:** the anti-sycophancy worked examples (`examples/`) discussed
alongside this work are deferred pending a decision on whether they derive from real transcripts
(which would put them in `validation/` with a chain of custody) or are illustrative and synthetic
(which needs its own clearly-labeled directory, since `examples/` is defined above as undiluted
reproduction from the private source). No `[E]`-tier evidence about Rules 1–2 is added here.

## Domain skill added — `adapters/gemini-cli/computational-arch/SKILL.md`, 2026-08-27

**[Empirical]** First domain skill authored *for* this repository rather than extracted from a
private working source. The two bioprocess skills were reproduced undiluted from Dr. Ruiz-Hernández's
own workflow; this one has no such provenance, and `adapters/gemini-cli/README.md`'s language note
was corrected to stop implying otherwise for all skills in that directory.

**Motivation:** the universal core has always been software-shaped (§3 is git/worktree/stash/CI
mechanics; §4 is IDE hooks), but the *domain layer* covered only bioprocess research. A reader
landing on `README.md` saw two bio skills and reasonably concluded the project was a bioprocess
artifact. This closes that asymmetry without touching §1–§5.

**Distinguishing rule — environment preflight (§1).** The bio skills already perform ad-hoc
environment checks: `bio-ruiz-hernandez` §6 and its bootstrap prompt open with "PASO 1 — ENTORNO",
Ghostscript is located by ordered PATH search with no hardcoded path, and
`numerical-data-analysis` gates its Julia/SciML directive on `julia --version` responding, with a
declared SciPy fallback. `computational-arch` promotes that scattered pattern into a named
contract: detect, never assume; no assumed OS/shell/paths; missing tooling is reported before
anything is installed; absence of admin rights is treated as the normal case; and detected
versions become the empirical basis any later version-dependent claim must cite.

**Remaining §2–§6 content** covers the failure modes the core does not name: API/package
existence verified against the *installed* version and the official registry (an invented package
name is a live attack surface — slopsquatting/dependency confusion); test, build and performance
claims require an executable trace or degrade to `[U]`/`[S]`; concurrency and distributed-state
claims cap at `[I]` absent a deterministic reproduction, since a racy program passes most runs;
destructive operations must show their blast radius first.

**Deliberately not done:** the evidence labels are **not** redefined for this domain. §7 gives
per-label *examples* in a software context and states explicitly that `PROTOCOL.md` §2 governs
their semantics — redefining them per domain would forfeit the cross-domain portability that is
the protocol's stated value. §7 also records that `[E]` means *empirically verified* and never
*secure*: a clean static-analysis run is evidence about the tool's coverage, not about the code.

**Scope note:** a security/cybersecurity skill — where the domain-layer ethics section would be
the primary content rather than an appendix, mirroring `bio-ruiz-hernandez` §5 — is a separate
piece of work and is not included here. Infrastructure-as-code and orchestration are likewise out
of scope; §5 fixes only the principle that infrastructure state is queried, not narrated.

## Domain skill added — `adapters/gemini-cli/cybersecurity/SKILL.md`, 2026-08-27

**[Empirical]** Second skill authored for this repository (see the `computational-arch` entry
above for the provenance distinction). Completes the software-side domain layer: `computational-arch`
governs general verification of software work, this one governs security work specifically.

**Structural decision — the ethics layer is §1, not an appendix.** `bio-ruiz-hernandez` places
its AI-in-research ethics at §5, after the editorial and workflow rules. This skill deliberately
inverts that: in research, ethics governs how a result may be *reported*; in security, it governs
whether the action may *run at all*. Authorization and scope are therefore a precondition checked
before anything else — owner identified, authorization explicit (own infrastructure, lab/CTF, or
written authorization), scope treated as a hard boundary that is never self-extended and never
transitive across time, untrusted code isolated in a disposable environment, responsible
disclosure, and a rule to stop rather than extract when third-party data is exposed.

**Reality-filter specialization (§3).** Security has its own characteristic overclaim, and the
skill names each one: `[E]` never means *secure*; a finding without documented reproduction stays
`[S]`; "the scanner reported it" is `[I]`, because false positives are the normal case, not the
exception; severity must be argued for *this* deployment rather than inherited from an advisory,
since the same vulnerability can be critical when exposed and irrelevant in an unreachable
dependency; and presence of a vulnerable version is not reachability.

**Anti-hallucination (§2.1).** CVE, CWE, GHSA and vendor-advisory identifiers must be verified
against the authoritative database before being cited — a fabricated identifier is a
domain-specific instance of the failure Rule 2 exists to prevent, and it sends the reader to
look for something that does not exist. This is the same class of error the repository's own
`scripts/check-citations.sh` was built to catch in the bibliography.

**Scope boundaries recorded in the skill itself:** it is not an authorization and does not
substitute for a pentest contract, a bug-bounty program's rules, or institutional policy (the
stricter one always prevails); it does not cover regulatory compliance (ISO 27001, PCI-DSS,
LFPDPPP) or software licensing, each of which is its own domain.

**Not done:** no `validation/` harness accompanies either new skill. Both are prompt-layer
conduct rules — the "social half" in `README.md`'s terms — and the repository's own §3.11
position is that a conversational instruction is not technical enforcement. Executable gates for
these domains (dependency-audit and secret-scanning hooks) remain open work, and no `[E]`-tier
evidence about their effect is claimed here.

## Evidence-anchor verification — `scripts/check-claims.sh`, 2026-08-27

**[Empirical]** The repository verified its bibliography (`scripts/check-citations.sh`) and its
version markers (`scripts/sync-check.sh`), but never its own evidence anchors. `LINEAGE.md`,
`EVIDENCE.md` and `validation/REPORT.md` assert `[Empirical]`-tagged claims anchored to commit
SHAs and file paths, and nothing checked that those anchors resolve — so a renamed log or a
mistyped SHA would leave the documents quietly asserting something false. That is the failure
Rule 2 exists to prevent, in the one place where it is least defensible: a protocol that requires
verification before assertion, not verifying its own assertions.

`scripts/check-claims.sh` extracts every backticked commit SHA and repo path from those four
documents and resolves each one — `git cat-file -e` for SHAs, existence (repo-root-relative, then
relative to the citing document) for paths. On this baseline: **42 anchors resolve, 9 do not.**

The 9 are registered in `scripts/claim-anchors.tsv` with a mandatory reason and reported as
UNRESOLVED on every run — registered debt, deliberately visible, the same convention
`scripts/check-citations.sh` uses for `id_type=none`. All 9 are the same category: the private
Cerebro-Queen workspace the protocol was extracted from, and the incident record behind several
v1.2.0 rules. They are kept verbatim rather than paraphrased so anyone with access can locate
them, but they cannot be verified from here and the documents must not imply otherwise.

**Three failure modes, each exercised against the real script before merge:** an unregistered
dangling anchor fails; a registry entry that *does* resolve fails as a stale exemption; a
registry entry no document cites any more fails as stale debt. Non-anchors are excluded
structurally rather than by allowlist — URLs, glob patterns like `ux/p1-*` (a class of branches,
not an artifact), and backticked regex or contract templates, which contain a slash while naming
nothing.

**Implementation note:** classification uses bash builtins rather than a pipeline per token. The
first version spawned several subprocesses per token and took minutes under Git Bash on Windows,
where process spawn is expensive; it now runs in about a second. A check nobody can afford to run
locally is a check that rots — and `computational-arch` §1, added the same day, is precisely the
rule against assuming someone else's environment.

**Shallow-clone correction (same day).** The first CI run of this check failed on GitHub Actions
while passing locally: `actions/checkout@v4` performs a depth-1 checkout by default, so the
history the commit anchors live in was not present, and the script reported two commits that do
exist as resolving nowhere. Reporting "does not resolve" when the truth is "this checkout cannot
see it" is itself an unverified assertion — the failure mode the script was written to catch,
reproduced by the script. It now detects a shallow repository, reports SHA anchors as
UNVERIFIABLE, and fails with the remediation instead of with a false claim; the workflow sets
`fetch-depth: 0`. Verified both ways: full clone resolves, a `--depth 1` clone reports
UNVERIFIABLE.

**CRLF correction (same day).** On a Windows checkout the registry's blank separator line becomes
a lone carriage return, which `read` returns as a record whose first field is `\r` — not empty,
not a comment — so `scripts/check-claims.sh` rejected its own inventory with "registry entry ''
has no reason". Linux CI cannot reproduce this, since git only rewrites line endings on the
platform that asked for them: the check was green on GitHub and red on the maintainer's machine
at the same commit. Fixed at both levels — `.gitattributes` pins `*.sh`, `*.tsv`, `*.jsonl` and
`*.yml` to LF in every working tree, and the reader strips carriage returns defensively for
contributors who already have CRLF copies.

## Citation identifiers — RFC support and scheduled resolution, 2026-08-27

**[Empirical]** `scripts/check-citations.sh` accepted only `arxiv` and `doi`, rejecting anything
else with `unknown id_type`. IETF RFCs are primary literature for much of computer systems and
carry no DOI in general use, so the systems-side bibliography had no way in. Added `id_type: rfc`
(digits only), resolved against the IETF Datatracker and parsed with `python3`, which the arXiv
branch already required — RFC support adds no new dependency.

**Not added: IEEE and ACM types.** They need none. Their DOIs resolve through Crossref like any
other, which the existing `doi` branch already does — the Wooldridge AAMAS citation in
`PROTOCOL.md` is an ACM DOI and resolved that way on 2026-08-26. A proposal to add them
separately was declined as redundant after checking.

Verified against the live API: `rfc8446` resolves to "The Transport Layer Security (TLS) Protocol
Version 1.3". No entry in `scripts/citations.tsv` uses `id_type=rfc` yet; the resolver is in place
for future systems-side citations and was not retrofitted by inventing one.

**Scheduled online resolution.** `scripts/check-citations.sh` runs structurally on every push and
deliberately does not resolve identifiers, so a resolver outage cannot redden a build over an
unrelated change. That keeps PRs honest but means an identifier that silently stopped resolving
would never be noticed. `.github/workflows/citations-online.yml` runs the `--online` pass weekly
and on demand, where a failure points at the bibliography rather than at whoever pushed last.

## Domain-skill gates — executable enforcement for the two new skills, 2026-08-27

**[Empirical]** `adapters/gemini-cli/computational-arch` and
`adapters/gemini-cli/cybersecurity` were merged as prompt-layer conduct rules — what `README.md`
calls the "social half", and what §3.11 says is not technical enforcement. Two of their rules are
now executable, so the skills are no longer only prose:

- `validation/lib/secret_scan_check.sh` (cybersecurity §2.3) rejects content containing a string
  shaped like a live credential, and `validation/hooks/pre-commit-secret-scan.sh` wires it as a
  real commit stop. It scans the **staged blob** rather than the working tree, because the two
  differ under partial staging and the blob is what the commit would contain. It reports
  `file:line` and the matching pattern but never the matched text — a scanner that echoes a
  secret into a build log has published it where logs are most widely readable.
- `validation/lib/dependency_manifest_check.sh` (computational-arch §2.2) rejects a manifest
  naming a package that does not exist in its registry: an unregistered name is an unclaimed
  namespace a third party can register, not a typo.

**13/13 scenarios pass** (`validation/gates_run_2026-08-27.log`). Six exercise the secret scanner
— and three of those assert it stays **quiet** on environment indirection, documentation
placeholders and ordinary config, because a scanner that flags what a correct codebase is full of
teaches people to switch it off, which costs more than its misses. Five exercise dependency
existence, including a parser case where comments, `-r` includes, `--index-url`, extras and
environment markers must not be read as package names. Two confirm invalid input is reported as
invalid input rather than as a clean run, the distinction PV7/PV8 already make.

**Resolution is injected** through `RFP_PKG_RESOLVER`, so the suite exercises the real decision
logic and real exit codes with no network. A gate whose tests need the internet stops running the
first time CI is offline.

**Two fixture corrections found by running it.** The first AWS fixture used
`AKIAIOSFODNN7EXAMPLE`, the canonical key from AWS's own documentation — the scanner correctly
declined to flag it, since it contains `EXAMPLE`, and the fixture was wrong rather than the
filter. The generic assignment pattern also missed `"password": "..."` because it required the
key to be followed directly by `:`; JSON puts a quote in between.

**`scripts/check-claims.sh` gained a `generic` anchor kind** while documenting this work: it
flagged `package.json`, cited in `validation/REPORT.md` as a manifest *type* rather than as a
file of this repository. That is not the same statement as the private-workspace anchors, which
name real artifacts this checkout cannot see, so it is reported separately and left out of the
unresolved count — folding them together would inflate the debt figure with things that were
never debt.

## A/B study apparatus and a stale spelled-out count, 2026-08-27

**[Empirical]** `validation/ab-study/` adds the apparatus for the controlled evaluation
`EVIDENCE.md` and `CONTRIBUTING.md` both say does not exist: design and rubric
(`validation/ab-study/PROTOCOL-AB.md`), four seed tasks, an archiving runner, and a results
template.

**No data was collected and no result is claimed.** `EVIDENCE.md`'s statement stands unchanged.
Building the harness does not shrink the gap, and recording that it did would be the exact
failure this repository is about.

Three design decisions worth keeping on the record:

- **The control is "no protocol", not a different protocol variant.** A proposal reviewed the
  same day suggested comparing a biology-flavoured build against a systems-flavoured one; that
  measures nothing about whether the protocol causes any behaviour, because both arms have it.
- **Every metric is a count of observable transcript events**, with M5 (spontaneous correction)
  included as a counter-metric so the study can detect the protocol making things *worse*. A
  treatment that only measures its intended effect cannot fail, and task T4 exists for the same
  reason: §1 forbids fabricating objections as much as rubber-stamping, so a treatment that
  merely makes an agent more negative must be scored as the different failure it is.
- **The runner does not grade.** It writes a condition-stripped copy for blind grading, because
  the evidence tags and protocol vocabulary label which arm a transcript came from. A harness
  scoring its own runs would be the evaluator-immunity violation §5 names.

The prompt-length confound (condition B also has a longer system prompt) is recorded as a stated
limitation with the filler-arm control that would separate it, rather than left for a reader to
find.

**Stale count corrected.** `validation/live-agent-trial-1/TRIAL.md` still said "the eleven no-LLM
synthetic scenarios" — the v1.4.0 sweep that corrected every numeric 11 to 13 could not see it,
because `scripts/sync-check.sh` matches the `N/N` form and this was spelled as a word in a file
outside its list. Fixed to thirteen, and TRIAL.md added to the guard's file list. A word-form
guard was written and then **dropped**: it cannot distinguish a total from a delta ("two
composed-hook regression scenarios were added") or from prose quoting the corrected error, and
both of those false positives fired immediately on the real documents. A check that cries wolf is
a check someone switches off — the same reasoning the secret scanner's placeholder filter rests
on. The convention comment now tells authors to write scenario counts numerically.

## Release `v1.5.0` — 2026-09-02

**[Empirical]** Operational hardening release, derived from an external critical review whose
factual premises were verified against the repository before adoption. One premise of that
review — that the Cursor adapter omitted §3.12 — was false (the adapter carries it); its
proposal was re-scoped rather than implemented as stated. That misreading is an instance of
the failure mode the protocol exists to catch, recorded here as such.

Protocol changes (`PROTOCOL.md`):

- §2 gains an evidence-decay rule: an `[E]` claim about mutable state expires when the agent
  acts on that state or crosses a session boundary; immutable-ref anchors do not decay.
- §3.12.1 adds a quick decision table for peer verification — the rule's semantics unchanged,
  made operable at decision time.
- §4.4 develops the compensating controls §4.3 only named: artifact-level verification before
  ACK, external durable logging, deterministic verification prompts.
- §6 adds a session handoff protocol (state snapshot, claim inventory, pending verifications,
  authority transfer), closing §3.12's loop across sessions.

Adapters:

- New first-party adapters: `adapters/kimi/SKILL.md` (Kimi web/desktop and Kimi Code CLI —
  the first adapter for a platform with no user-facing hook layer, so §4.4's controls are
  written as the primary mechanism, not a fallback) and
  `adapters/github-copilot/copilot-instructions.md` (short-form, inline-suggestion budget).
- `adapters/claude-code/SKILL.md`: explicit guidance for the `Agent` tool (completion
  summaries describe intent, not outcome; peer subagents re-verify), plus parity fixes —
  it had silently dropped the mandatory correction format, the no-unsolicited-rewrites rule,
  and sections 4–5 while CI stayed green.
- `adapters/cursor/reality-filter.mdc`: a scannable "Critical moments" section, and the exact
  correction template added for parity.
- `adapters/antigravity/SKILL.md`: structured subagent outputs are containers, not evidence.
- `adapters/gemini-cli/meta-orchestrator/SKILL.md`: new meta-skill governing which domain
  skill loads for which task and how cross-skill conflicts resolve.

Domain skills:

- `bio-ruiz-hernandez`: the n=10 audit gains a mandatory structured scorecard per delivery —
  an audit that is not recorded is an intention, not a control.
- `numerical-data-analysis`: the golden rule gains its canonical non-pipeline violation —
  features derived from global column statistics computed before the split.
- `cybersecurity`: responsible disclosure gains a quantified timeline template (day 0 / 7 /
  30 / 90).

Validation and CI:

- `validation/ab-study/PROTOCOL-AB.md` gains pre-registered decision criteria (positive /
  null / negative / inconclusive thresholds), and `validation/ab-study/preregister.sh` + a `validation/ab-study/runner.sh` gate make
  preregistration a hashed file that must exist before the first run — §3.1 applied to the
  study itself.
- `validation/lib/mutate_check.sh`: systematic mutation testing for checkers — a suite every
  mutant survives proves nothing (formalizes the accidental PV7/PV8 lesson).
- `validation/lib/anti_sycophancy_check.sh`: a transcript linter for the observable surface
  of Rules 1–2 (M1/M2 events and the praise-then-trivial-objection pattern).
- `scripts/adapter-coverage.sh` + `scripts/adapter-coverage.tsv`: every first-party adapter
  must carry the core protocol elements or register the omission with a reason. This release
  exists partly because the version-string grep in `scripts/sync-check.sh` could not see content
  drift; this checker can. Its first run caught the cursor adapter's missing correction
  template.
- `scripts/sync-check.sh` now also verifies LINEAGE.md release chronology (dates
  non-decreasing, versions strictly increasing) and covers the new adapters.
- `scripts/check-citations.sh` caches online resolutions locally (7-day TTL);
  `scripts/check-claims.sh` gains an optional `--online` URL-liveness pass.
