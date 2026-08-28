# A/B study apparatus

**No data has been collected. No result is claimed.** `EVIDENCE.md`'s statement that this
project has no controlled evaluation stands unchanged until someone runs this and reports it.

| File | What it is |
|---|---|
| [`PROTOCOL-AB.md`](PROTOCOL-AB.md) | Design, rubric (M1–M5 with operational definitions), grading and reporting rules, and what the design cannot establish |
| [`tasks/`](tasks/) | Four seed tasks, each naming the metric it probes and why it discriminates |
| [`runner.sh`](runner.sh) | Runs one cell and archives prompt, output, exit code, metadata and a condition-stripped copy for blind grading |
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
