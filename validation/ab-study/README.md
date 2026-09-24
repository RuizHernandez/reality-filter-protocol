# A/B study apparatus

**No data has been collected. No result is claimed.** `EVIDENCE.md`'s statement that this
project has no controlled evaluation stands unchanged until someone runs this and reports it.

| File | What it is |
|---|---|
| [`PROTOCOL-AB.md`](PROTOCOL-AB.md) | Design, rubric (M1–M6 with operational definitions), grading and reporting rules, and what the design cannot establish |
| [`tasks/`](tasks/) | Six tasks (T5 reproduces the antigravity n=2 tool-deprivation case; T6, orchestration only, reproduces the paper's rubric-capture incident). `tasks/<id>.md` is the experimenter's spec (never shown to an agent); `prompt.txt` / `orch-prompt.txt` is all an agent sees; `fixture.sh` builds its byte-reproducible workspace repo; optional `check.sh` records workspace facts (not scores) |
| [`docker/`](docker/) | Agent image (pinned base and CLI versions, tools only) and backend definitions (`deepseek`, `gemini`) |
| [`preregister.sh`](preregister.sh) | Freezes design, n, model(s), and the SHA-256 of every spec, prompt, fixture and check into `preregistration.json` |
| [`smoke-docker.sh`](smoke-docker.sh) | Admission gates: a backend must prove its file-read tool works; an orchestrator/worker pair must prove delegation works |
| [`runner-docker.sh`](runner-docker.sh) | Runs one cell, every agent in its own container; archives prompts, transcripts, workspace diff, check facts, redacted credentials, and condition-stripped copies for blind grading |
| [`run-batch-docker.sh`](run-batch-docker.sh) | Gates, then every cell in a seeded shuffle |
| [`RESULTS-TEMPLATE.md`](RESULTS-TEMPLATE.md) | Reporting skeleton, with a null/negative result treated as a first-class outcome |

## Running it

Needs Docker and Git Bash. Secrets live outside the repository in a file you create
(default `C:\ab-secrets\secrets.env`, override with `AB_SECRETS`):

```
DEEPSEEK_API_KEY=...
DEEPSEEK_MODEL=...     # exact id from the provider's docs
GEMINI_API_KEY=...
GEMINI_MODEL=...
```

```bash
docker build -t ab-agent:1 docker/
AB_DESIGN=orch ./preregister.sh 10 "google:<model>>deepseek:<model>"   # then commit it
./run-batch-docker.sh orch gemini deepseek 10
```

Results go to `AB_RUNS_DIR` (default `C:\ab-runs`), outside the repository and outside any synced
folder, because transcripts can contain whatever an agent printed.

Three choices worth knowing:

**The control is "no protocol."** Not a different protocol variant. Comparing two variants
measures nothing about whether the protocol causes any behaviour, since both arms have it.

**The runner does not grade.** Grading is blind and manual; the runner writes copies with the
evidence tags, protocol vocabulary, prompt echoes and token counts stripped, because those label
the arm. A harness that scored its own runs would be the evaluator-immunity violation §5 names.

**Agents cannot see the study.** Each agent container holds only its workspace (and, for an
orchestrator, a mailbox). See PROTOCOL-AB.md, "What the agent sees, and what it must not", for
why this replaced path-hiding after pilot 3.
