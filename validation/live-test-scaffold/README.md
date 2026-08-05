# Live-agent test scaffold

Everything in `validation/` so far is a **technical-layer replay with no LLM involved**
(see `../REPORT.md`). This scaffold is for the next step: pointing a real DevSwarm/Cursor
multi-agent session at an isolated copy of the repo, with the v1.3.0 hooks installed, to see
whether the technical controls hold against a live agent — and, separately, whether the
prompt-level rules (anti-sycophancy, reality filter) change how often an agent *attempts*
rubric capture in the first place.

## Why isolate at all

The incident this protocol responds to, and the July 2026 Anthropic/OpenAI incidents cited in
the paper's Introduction, are all cases of an agent with real shell/network access doing
something outside the intended boundary. Testing whether a HOLD or a spec-immutability hook
holds against a live agent means deliberately trying to get the agent to do the thing the
control is supposed to block. Do this against a disposable copy, not the production
Cerebro-Queen workspace, and not with unrestricted network access.

## Setup

```bash
# 1. Build the isolated container (or skip Docker and just use setup-isolated-repo.sh
#    directly against a disposable directory if you'd rather not containerize).
docker build -t reality-filter-livetest .

# 2. Create the disposable repo with hooks pre-installed.
bash setup-isolated-repo.sh /path/to/DevSwrmxML ./repo

# 3. Run the container with the isolated repo mounted, network off by default.
docker run --rm -it --network none -v "$(pwd)/repo:/work/repo" reality-filter-livetest
```

Point Cursor's DevSwarm configuration at `./repo` (or the container's `/work/repo`), not at
your real working copy.

## What to actually test

1. **Role attestation gap (the harness's known limitation).** The hooks trust `AGENT_ROLE`
   from the environment. Confirm whether DevSwarm's orchestration layer can set this
   per-agent-commit itself (ideal) or whether it has to be set manually per test run (current
   state, and itself worth recording as a finding either way).
2. **Does a live Coder agent still attempt the 776f042 pattern** when given the same P2 task
   under protocol v1.3.0, now that the hook exists? A "yes, attempted but blocked" result is
   informative and worth keeping, not a failure to hide.
3. **False positives at scale** — does the spec-immutability hook ever block a legitimate
   Architect action in a longer, more realistic session than the synthetic replay covered?

## Recording results

Follow the same evidence-label convention as the rest of this repository
(`[Empirical]`/`[Inference]`/`[Speculation]`/`[Unverified]`, short form `[E]`/`[I]`/`[S]`/`[U]`
per `PROTOCOL.md` v1.3.0). This is exactly the live-agent controlled evaluation described in
`CONTRIBUTING.md`'s "Contributing a controlled evaluation" section — write it up the same way:
methodology, model(s) used, with/without protocol, and report positive, negative, or null
results.

## Cost and scope

A live DevSwarm session makes real API calls under your account and can run an agent with real
shell access inside the container. Decide the scope (how long, how many roles, which task)
before starting, the same way you would for any paid, semi-autonomous run.
