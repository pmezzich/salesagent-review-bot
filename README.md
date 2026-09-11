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

**The pipeline runs end to end.** First full pass against a live PR:
[prebid/salesagent#1650](https://github.com/prebid/salesagent/pull/1650), 2026-09-10, run
`100926_2042`.

- Substrate ported — Chris's charter + 10 detectors + P1–P42 corpus (Apache-2.0), Konstantin's
  drivers + skill + references (MIT), with `NOTICE` + `licenses/`.
- 11 canonical review agents in `claude/agents/` — the union/dedup of both source sets per the
  mapping in the design doc.
- Orchestration skill merged (`claude/skills/review-queue/SKILL.md`) — 11 agents + a detector
  pre-pass + the §4b consolidation / §4c readiness gates + the ratchet post-pass, on
  Konstantin's draft-only, worktree-pinned backbone.
- `install.sh` exercised on Windows/Git-Bash: agents/skill/rules → `~/.claude/`, drivers →
  `~/.local/bin`, with the `{{BOT_RULES}}` token resolved at install so the repo stays portable.
  Symlink mode falls back to copy on Windows.
- Run state lands in `~/.local/state/pr-review-queue/<repo>/queue/<ddmmyy_HHMM>/` — a manifest,
  one directory per PR (11 agent reports + `FINDINGS.md` + `DRAFT-COMMENT.md` +
  `REVIEW-INLINE.json`), and a single HTML artifact for the run.
- AdCP pin reconciled: the `recovery_audit` / `sdk_spec_drift` snapshots sit at spec **3.1.1**,
  which matches the target repo's pin (adcp 6.6.0). `bump_check` exits 0 against it.

What the #1650 pass produced: 8 should-fix / 6 notes / 14 verified inline anchors, with
`disposition_ledger` exiting 0 on both the findings and the draft. The synthesis caught and
repaired a site-drop in its own consolidation — the §4b failure mode that detector exists for —
and settled two flagged disputes with measurements rather than adjudication.

**Open:**

- **Layer 3 has never been exercised.** Nothing has been posted to GitHub by this tool. The
  draft-only post path is written but unrun, so its failure modes are unknown.
- No CI in this repo; `bump_check` is not wired to a gate, so snapshot rot is caught only when a
  run happens to trip it.
- `recovery_audit` / `sdk_spec_drift` / `suggestion_audit` still each load `error-code.json` and
  walk the subclass tree independently — the shared single-load is unbuilt.
- `review-bdd` still has no `inspect_bdd_steps.py` (absent from the source repo); `bdd.md`
  instructs hand-tracing instead, which is slower and less complete.
- `pr-radar` prints decorated text only — no structured emit, so nothing downstream can consume
  its triage.

## Credits

Built on the design and code of **Konstantin Mirin** and **Chris Huie** (repos linked above).
Their attribution and license terms are tracked in [`NOTICE`](NOTICE) and [`licenses/`](licenses/),
with per-file provenance in this repo's git history.
