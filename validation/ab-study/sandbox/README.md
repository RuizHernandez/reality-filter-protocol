# Running the A/B study in Windows Sandbox

Each sandbox session is a throwaway Windows: agents run with permissions
bypassed, so they must not run on the host. Results are written back through the
mapped repository (`runs/`); everything else vanishes when the sandbox closes.

## 1. Secrets (host, once)

Create a folder outside the repository, e.g. `C:\ab-secrets\`, with `secrets.env`:

```
DEEPSEEK_API_KEY=...
DEEPSEEK_MODEL=...        # exact id from api-docs.deepseek.com
GEMINI_API_KEY=...
GEMINI_MODEL=...          # exact id, e.g. from `gemini` model docs
# ANTHROPIC_API_KEY=...   # only for the optional claude backend
```

Define only the keys for backends you run. The comparison that matters is A vs B
*within* a backend, so each backend is a complete study on its own.

It is mapped read-only and only sourced; no script prints it. Never put it in the repo.

## 2. Generate and start the sandbox (host)

```powershell
cd validation\ab-study\sandbox
.\make-wsb.ps1 -SecretsDir C:\ab-secrets
.\ab-study.wsb
```

`ab-study.wsb` embeds this machine's paths and is git-ignored.

## 3. Preregister (before any real run)

```bash
./preregister.sh <n> "deepseek:<model>,google:<model>"
git add preregistration.json && git commit -m "Preregister A/B study"
```

## 4. Run a batch (inside the sandbox bash window)

```bash
bash sandbox/run-batch.sh deepseek <n>
bash sandbox/run-batch.sh gemini <n>
```

The batch refuses to start unless the backend passes `smoke.sh`. Cells run in a
shuffled order (seed recorded in `runs/batch-*.plan.meta`) so A and B are
interleaved in time.

## Pilot first

Before preregistering the real n, run a pilot in a scratch clone with n=1 to
measure cost and time per cell and to confirm `for-grading.txt` does not leak the
condition (stream-json must not echo the prompt). Pilot runs are not data and are
never mixed into the study.

## Not covered yet

- Gemini runs through Gemini CLI (`backends/gemini.env`), which must be
  installed on the host (`npm i -g @google/gemini-cli`; the global npm folder is
  mapped into the sandbox). OmniRoute into Claude Code remains an alternative,
  admitted only if it passes `smoke.sh`.
- DevSwarm: a multi-agent orchestrator with a GUI; whether it runs unattended in
  the sandbox is unverified. Planned as a separate phase, not pooled with this study.
