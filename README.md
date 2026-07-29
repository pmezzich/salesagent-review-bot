# salesagent-review-bot

A single multi-agent pull-request reviewer for [prebid/salesagent](https://github.com/prebid/salesagent),
merging two existing reviewers into one pipeline:

- **[salesagent-review-harness](https://github.com/ChrisHuie/salesagent-review-harness)** (Chris Huie) — the **rigor**: the review charter + masking-gotcha doctrine, 10 self-testing detectors, and the P1–P42 pattern catalog.
- **[prebid-salesagent-pr-review](https://github.com/KonstantinMirin/prebid-salesagent-pr-review)** (Konstantin Mirin) — the **pipeline**: a 3-layer scout → review → draft-only post flow with worktree pinning, an HTML review artifact, and `pr-radar` triage.

Full design and rationale: **[docs/merge-design.md](docs/merge-design.md)**.

## Idea

Konstantin's tool is the **chassis** (deterministic pipeline + delivery); Chris's is the **brain** (grounding + verification rigor). This repo puts the brain in the chassis and unions their 16 review agents into ~11 canonical dimensions, behind one synthesis + readiness gate.

```
pr-radar → L1 scout + worktree-pin → L2 fan-out agents (+ detector pre-pass)
         → synthesis (SSOT + disposition gate + ratchet post-pass)
         → §4c readiness gate → HTML artifact → draft-only post
```

## Layout

| Path | Role | Source |
|---|---|---|
| `bin/` | deterministic drivers — L1 scout / L3 post, `pr-radar`, HTML artifact | port from Konstantin's `bin/` |
| `claude/skills/review-queue/` | orchestrator skill (L2 fan-out + synthesis) | port from Konstantin |
| `claude/agents/` | the ~11 canonical review agents | union/dedup of both sets |
| `claude/rules/charter/` | operating charter + masking-gotcha doctrine + tooling | port from Chris |
| `claude/rules/detectors/` | the 10 mechanized, self-testing detectors | port from Chris |
| `claude/rules/corpus/` | P1–P42 catalog + reference / knowledge pack | port from Chris |
| `docs/` | design docs | this repo |

## Status

**Scaffold (Phase 1).** Structure + design only — no agents/detectors ported yet. Build order is in the design doc. Known gaps to resolve while porting:

- Chris's `review-bdd` depends on `.claude/scripts/inspect_bdd_steps.py`, which is **not in that repo** — supply or downgrade.
- `pr-radar` has **no JSON output** (it scrapes its own header text) — add a structured emit.
- Both source tools are **Unix-only**; this needs a cross-platform (Windows/Git-Bash) install + run.
- Reconcile the AdCP pin — Chris's detectors hard-pin `3.1.1`, which diverges from the SDK-mapping memory (`3.1.0-beta.3` / adcp 5.7.0). Wire `bump_check` into CI.

## Credits

Built on the design and code of **Konstantin Mirin** and **Chris Huie** (repos linked above). Attribution and licensing for their source will be tracked here as it is ported in.
