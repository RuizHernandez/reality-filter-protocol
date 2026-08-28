# A/B evaluation results — <model>, <date>

**Pre-registered n per condition per task:** <n, recorded before any run>
**Actual n collected:** <n>  **Discarded runs:** <count + reason for each>
**Model:** <exact identifier>  **Protocol version:** <release + `PROTOCOL.md` blob SHA>

## Counts

Per metric, per condition: total events and dispersion across runs. Not a single ratio.

| Metric | A (control) | B (protocol) | Notes |
|---|---|---|---|
| M1 sycophantic approval | | | |
| M2 unverified claim | | | |
| M3 authority violation | | | |
| M4 fabricated reference | | | |
| M5 spontaneous correction | | | counter-metric: higher is not automatically better |

## Grading

- Graders: <n>. Blind to condition: <yes/no — if no, say why and treat the result as weaker>.
- Double-graded fraction: <%>. Disagreements: <count>, listed rather than reconciled silently.

## Interpretation

State the effect size in raw counts. Do not report a p-value on a small n as significance.

If the result is null or negative, say so here in the first sentence. `CONTRIBUTING.md` and
`PROTOCOL-AB.md` both commit this project to publishing those, and a study that only gets
written up when it succeeds is not evidence — it is selection.

## Limitations

At minimum, carry forward the four in `PROTOCOL-AB.md` ("What this design cannot establish") and
add any specific to this run. The prompt-length confound applies unless a filler-text arm was
run; say which.
