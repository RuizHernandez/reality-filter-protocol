# A/B study apparatus

**No data has been collected. No result is claimed.** `EVIDENCE.md`'s statement that this
project has no controlled evaluation stands unchanged until someone runs this and reports it.

| File | What it is |
|---|---|
| [`PROTOCOL-AB.md`](PROTOCOL-AB.md) | Design, rubric (M1–M5 with operational definitions), grading and reporting rules, and what the design cannot establish |
| [`tasks/`](tasks/) | Five tasks (T5 reproduces the antigravity n=2 tool-deprivation case). `tasks/<id>.md` is the experimenter's spec (never shown to the agent); `tasks/<id>/prompt.txt` is all the agent sees; `tasks/<id>/fixture.sh` builds its byte-reproducible workspace repo; optional `check.sh` records workspace facts (not scores) |
| [`smoke.sh`](smoke.sh) | Backend admission gate: a model/harness/proxy must prove its file-read tool works before it enters the study |
| [`preregister.sh`](preregister.sh) | Freezes n, model(s), and the SHA-256 of every spec, prompt, fixture and check into `preregistration.json` |
| [`runner.sh`](runner.sh) | Runs one cell in a fresh fixture workspace outside the study dir; archives prompt, transcript, exit code, metadata, post-run workspace diff, check facts, and a condition-stripped copy for blind grading |
| [`RESULTS-TEMPLATE.md`](RESULTS-TEMPLATE.md) | Reporting skeleton, with a null/negative result treated as a first-class outcome |
| `runs/` | Archived runs (empty) |

Three choices worth knowing before using it:

**The control is "no protocol."** Not a different protocol variant. Comparing two variants
measures nothing about whether the protocol causes any behaviour, since both arms have it.

**The runner does not grade.** Grading is blind and manual; `runner.sh` writes a copy with the
evidence tags and protocol vocabulary stripped, because those label the arm. A harness that
scored its own runs would be the evaluator-immunity violation §5 names.

**The agent command is injected** (`AB_AGENT_CMD`), so the study is not welded to one vendor's
CLI and a run stays reproducible against whatever tool exists later.
