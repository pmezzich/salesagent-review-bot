---
name: pr-review-queue
description: >
  Automated multi-agent PR review. For the PRs you name (or pr-radar's RE-REVIEW +
  NEVER-REVIEWED buckets), checks each out safely, fans out 8 review agents
  (dry, testing, python-practices, consistency, layering, adcp-grounding,
  ratchet-allowlists, bdd-grounding), and synthesizes a draft review comment per PR.
  Draft-only — you approve, then it posts. Use for "review my PR queue", "run the PR
  review pipeline".
args: "[PR...]  (empty = pull candidates from pr-radar)"
---

# PR Review Queue

Automates the manual loop: pr-radar → checkout → 8 review agents → synthesis →
deterministic local review artifact → you approve → post.

Three layers. You run this skill; it drives all three and STOPS for your approval
before anything reaches GitHub. There is no separate orchestration engine — the skill
itself fans the agents out (Layer 2), so it works anywhere the agents and `bin/`
scripts are installed.

The shared reviewing bar lives in [`references/review-policy.md`](references/review-policy.md)
and the synthesis contract in [`references/synthesis.md`](references/synthesis.md).
Both are resolved from this skill's installed directory
(`~/.claude/skills/pr-review-queue/references/`). Edit them to tune the review — the
whole skill dir is symlinked into `~/.claude/skills`, so changes take effect with no
re-install.

## 1. Scout + setup (Layer 1)

Run the driver to prepare review inputs. Pass the PR numbers the user picked; if none
were given, the driver pulls candidates from pr-radar.

```bash
pr-review-queue manifest $ARGUMENTS
```

This prints (and saves) a `manifest.json` with, per PR: the author diff, changed
files, prior human review comments, and a sibling worktree at
`<worktree-base>/<repo>-pr<NNNN>` (branch `pr-<NNNN>-review`; the base is set at install,
default `~/projects`, overridable with `PR_REVIEW_WT_BASE`). The review agents grep that
worktree, so the driver brings it to the **exact PR head the diff was built from** on
every run — fast-forward on a lag, hard-reset on a divergence (the old HEAD stays
recoverable via `git reflog`). These worktrees are disposable: worktree ≡ diff scope is
one snapshot. Layer 2 must NOT re-fetch or reset — that would drift the tree newer than
the diff the agents are grading.

## 2. Review fan-out + synthesis (Layer 2)

For each PR in the manifest, drive two stages. Process PRs one at a time (or a few in
parallel if the run is large) — within a PR, run the 8 reviewers concurrently.

**Stage 1 — fan out the 8 review agents in parallel.** In a SINGLE message, spawn all
eight via the Task tool. Each agent's prompt is: the full text of
`references/review-policy.md`, followed by the PR inputs (absolute paths from the
manifest: `diff`, `changed_files`, `checkout`, `prior_comments`) and this instruction —
"Read your own agent definition for your dimension's checklist and finding format,
apply it to the diff, read the prior-comments file first, and write your findings to
`<review_dir>/review-<name>.md`. Do not modify any source file; your final message is a
one-line status only." The eight agent types:

| agent type | dimension |
|---|---|
| `review-dry` | logic duplication / missing abstraction |
| `review-testing` | test quality — behavior vs mock theater |
| `review-python-practices` | Pythonic idioms, Pydantic, SQLAlchemy 2.0, async |
| `review-consistency` | naming, error/response shape, convention drift |
| `review-layering` | transport vs business vs repo vs adapter boundaries |
| `review-adcp-grounding` | protocol-behavior changes cite the pinned AdCP spec |
| `review-ratchet-allowlists` | structural-guard / duplication / xfail allowlists only shrink |
| `review-bdd-grounding` | behavior graded by wired BDD across all four transports |

**Stage 2 — synthesize.** Once a PR's eight `review-*.md` exist, spawn ONE synthesis
agent whose prompt is the full text of `references/synthesis.md` plus the same PR
inputs. It dedups, verifies each finding against the checkout, distills patterns, runs
the voice pass over `references/review-voice.md` LAST, and writes three artifacts:
`FINDINGS.md` (full internal working doc), `DRAFT-COMMENT.md` (the postable review
**body**), and `REVIEW-INLINE.json` (inline comments anchored to diff lines). It never
posts.

If you only need to re-format an existing run (e.g. after editing `synthesis.md` or the
voice guide), re-run Stage 2 alone over the `review-*.md` already on disk — the eight
dimension reviews do not need to re-run.

The bar in one line: **ONE fix tier — Should fix — no "nice to have".** Scope +
is-it-a-smell, not importance. DRY, type-safety (`Any`/`dict` where a concrete type
exists), layer/boundary, missing coverage, and single-transport grading are all Should
fix, each diagnosed to its architectural root. Never soften a DRY/in-scope smell to
"optional" or defer it behind an unverified issue number. Wired BDD across all four
transports is the verification bar; unit tests are not functional proof. Guard
allowlists may only shrink. Out-of-scope-but-real → Notes, with the reason. A
maintainer's still-unaddressed prior item leads its section, flagged respectfully. Two
standing checks: for every behavior the diff changes, ask "which BDD test grades this,
and does it execute?"; and reconcile with prior rounds in the body — credit what was
fixed, own anything you previously softened that has since slid. The full text of all
this is `references/review-policy.md`; do not restate a shorter, drifting copy.

## 3. Present + post (Layer 3)

**Presentation is a script, not a vibe.** Do NOT hand-assemble a summary or hand-write
an HTML page each run — the layout must be identical every time. Build the local review
artifact with the deterministic assembler and open it:

```bash
pr-review-queue artifact --open        # newest run -> <run_dir>/review-artifact.html
# or a specific run:  pr-review-queue artifact <run_dir> --open
```

`pr-review-artifact` renders ONE self-contained local HTML file from the run's
`manifest.json` + each PR's `DRAFT-COMMENT.md` / `REVIEW-INLINE.json` / `FINDINGS.md`:
a summary table (PR number, title, author, last-updated, state, inline count) followed,
per PR, by the postable comment, the inline comments, and the full findings
(collapsed). This IS the presentation of `FINDINGS.md` in full — the maintainer reasons
over the complete data in the page, not a chat distillation. Point the user at the
file; do not paraphrase it back.

Then, per PR:
1. The artifact is the working surface. If the user edits the body or the inline JSON,
   re-run `pr-review-queue artifact` to regenerate (same input -> same page).
2. Wait for explicit approval per PR.
3. Preview the exact payload, then on approval post it as ONE GitHub review (body +
   inline comments at the cited diff lines; anchors are validated against the diff,
   out-of-diff ones dropped with a warning):

```bash
pr-review-queue post <PR> --preview   # show body + inline anchors, post nothing
pr-review-queue post <PR>             # post the review
```

Do NOT post without per-PR approval. Do NOT batch-post silently.

## Cleanup

After posting (or to reclaim disk), prune the driver-owned checkouts:

```bash
pr-review-queue clean
```
