---
name: review-queue
description: >
  Automated multi-agent PR review for prebid/salesagent. For the PRs you name (or
  pr-radar's RE-REVIEW + NEVER-REVIEWED buckets), checks each out safely to a pinned
  worktree, runs the deterministic detector pre-pass, fans out 11 review agents
  (spec-conformance, bdd, error-wire, test-integrity, dry, consistency, layering,
  python-practices, ratchet-allowlists, security-isolation, admin-ui), and synthesizes
  ONE draft review per PR under the charter's consolidation + readiness gates.
  Draft-only — you approve, then it posts. Use for "review my PR queue", "run the review
  pipeline".
args: "[PR...]  (empty = pull candidates from pr-radar)"
---

# Review Queue

The merged salesagent PR-review pipeline: Konstantin's deterministic scout → review →
draft-only-post **chassis**, carrying Chris's **rigor substrate** (the charter, the 10
mechanized detectors, the P1–P42 catalog). Konstantin's tool is the pipeline; Chris's is
the brain — this skill runs the brain in the pipeline. See `docs/merge-design.md`.

Three layers. You run this skill; it drives all three and STOPS for your approval before
anything reaches GitHub. No separate engine — the skill fans the agents out itself.

**Always-on posture — the charter.** Every agent and the synthesis load
[`{{BOT_RULES}}/charter/review-charter.md`]({{BOT_RULES}}/charter/review-charter.md) as
Step-0: trust nothing your own tools report (the §2 masking-gotcha doctrine), verify
symmetrically ("an empty result is a hypothesis to falsify"), tag `[observed]`/`[inferred]`,
carry a Disposition on every finding, and honor the banned-language list. The reviewing
bar is [`references/review-policy.md`](references/review-policy.md); the synthesis contract
is [`references/synthesis.md`](references/synthesis.md); the AI-tell voice pass is
[`references/review-voice.md`](references/review-voice.md).

## 1. Scout + setup (Layer 1)

```bash
pr-review-queue manifest $ARGUMENTS
```

Prints/saves `manifest.json` with, per PR: the author diff, changed files, prior human
review comments, and a **sibling worktree pinned to the exact PR head the diff was built
from** (fast-forward on a lag, hard-reset on a divergence; old HEAD recoverable via
`git reflog`). `worktree ≡ diff scope` is one snapshot — **Layer 2 must NOT re-fetch or
reset**, or agents grade code newer than the diff.

## 2. Review fan-out + synthesis (Layer 2)

Process PRs one at a time (a few in parallel if the run is large). Within a PR:

### Stage 0 — detector pre-pass (deterministic, before any agent)

Run the mechanized detectors in
[`{{BOT_RULES}}/detectors/`]({{BOT_RULES}}/detectors/) against the pinned checkout. They are
the floor beneath LLM judgment — each catches a defect class a green `make quality`
provably misses. **They live outside the target tree, so invoke by ABSOLUTE path with
`cwd` = the worktree**:

```bash
# from the PR's pinned worktree (cwd = the checkout), for each detector.
# Use `uv run python`, NOT bare `python`: uv run guarantees a real interpreter AND makes
# adcp/src importable for the SDK-grounded detectors (recovery_audit, sdk_spec_drift,
# suggestion_audit). Bare `python` on Windows is the Microsoft Store shim — it prints
# "Python was not found" and runs nothing; `python3` works for the non-adcp detectors only.
uv run python {{BOT_RULES}}/detectors/<name>.py --base <PR-base-sha>
```

**Scope caveat — do NOT pass a bare `--base origin/main`.** On a fork checkout, `origin`
is the contributor's fork and `origin/main` is often stale, so `origin/main...HEAD` balloons
to hundreds of unrelated files. Pass the PR's real base: the SHA the manifest built the diff
from (`merge-base(<upstream>/main, HEAD)`), or scope the diff-based detectors to the manifest's
`changed_files`. `bump_check` needs no `--base` (it is a repo-wide freshness gate). Run it once
via `uv run python {{BOT_RULES}}/detectors/bump_check.py` first; exit 2 there means the SDK
snapshots are stale and the SDK-grounded scans below cannot be trusted.

Exit taxonomy: **2 = tool/snapshot broken — do NOT trust** (fix the pin; run
`bump_check.py`; the SDK-snapshot detectors hard-fail when the installed `adcp` pin ≠
their snapshot); **1 = actionable worklist** (seed it into the relevant agent below);
**0 = clean**. 8 of 10 are worklists you adjudicate, not gates — only the two
snapshot-staleness paths and `disposition_ledger` / `review_completeness` are true gates.
Collect the exit-1 hits as a **worklist** and hand each agent its slice.

### Stage 1 — fan out the 11 review agents in parallel

In a SINGLE message, spawn all eleven via the Task tool. Each prompt is: the full text of
`references/review-policy.md`, a pointer to the charter (Step-0), the PR inputs (absolute
paths from the manifest: `diff`, `changed_files`, `checkout`, `prior_comments`), that
agent's slice of the detector worklist, and: *"Read your own agent definition for your
dimension's checklist and finding format, apply it to the diff, read the prior-comments
file first, adjudicate your seeded detector hits, and write your findings to
`<review_dir>/review-<name>.md`. Do not modify any source file; your final message is a
one-line status only."*

| agent type | dimension | owns |
|---|---|---|
| `review-spec-conformance` | protocol behavior grounded in the pinned AdCP spec + graded storyboard | pin integrity, schema-vs-SDK |
| `review-bdd` | behavior graded by wired BDD across all four transports | **transport-parametrization** |
| `review-error-wire` | error responses assert the wire envelope via guarded helpers | **wire-assertion mechanics** |
| `review-test-integrity` | unit-test quality — behavior vs mock theater | unit false-floors |
| `review-dry` | logic duplication / missing abstraction | semantic duplication |
| `review-consistency` | naming, error/response shape, convention drift | |
| `review-layering` | transport/business/repo/adapter boundaries + structural guards | **thin-wrappers, typed errors** |
| `review-python-practices` | Pythonic idioms, Pydantic, SQLAlchemy 2.0, async | (most portable) |
| `review-ratchet-allowlists` | guards / duplication / xfail allowlists only shrink | + synthesis post-pass |
| `review-security-isolation` | tenant isolation, authz, money paths | isolation reasoning |
| `review-admin-ui` | Flask admin UI: routes, `script_root`, OAuth/CSRF, SSTI, tenant scoping in the UI | |

Overlaps are deduped by ownership (see each agent's checklist header): transport-parity →
`bdd`; wire mechanics → `error-wire`; thin-wrappers / typed-errors → `layering`; grep-omission
tenant checks → `consistency`/`code-patterns`, authz reasoning → `security-isolation`.

### Stage 2 — synthesize (with the charter's gates)

Once a PR's eleven `review-*.md` exist, spawn ONE synthesis agent (prompt = full text of
`references/synthesis.md` + the PR inputs). It:

1. Dedups and **verifies each finding against the checkout** (symmetric verification —
   spot-check the "clean" verdicts too).
2. Runs the charter **§4b semantic-SSOT consolidation**: unify one concept raised as N
   shards across agents into a single finding while preserving one ledger row per site
   (plain `(path,line)` de-dup is explicitly insufficient — it's how real findings get
   dropped). Gate with `disposition_ledger.py` (exit 0 required).
3. Runs the **`review-ratchet-allowlists` post-pass over ALL recommendations**: reject any
   "fix" that grows an xfail set / allowlist / `.duplication-baseline`.
4. Runs the voice pass over `references/review-voice.md` LAST (prose only, never technical
   content; strip internal vocab + detector names).

Writes three artifacts, posts nothing: `FINDINGS.md` (internal working doc + verification
log + convergence table), `DRAFT-COMMENT.md` (postable body), `REVIEW-INLINE.json` (inline
comments anchored to diff lines).

**The bar in one line: ONE fix tier — Should fix — no "nice to have".** Scope +
is-it-a-smell, not importance. Out-of-scope-but-real → Notes, with the reason and a
verified link. A maintainer's still-unaddressed prior item leads its section. Do not
restate a shorter, drifting copy of `review-policy.md`.

### Stage 3 — readiness gate (§4c, before any "ready" claim)

A readiness/approve verdict is the highest-stakes thing this suite emits. Before emitting
one: re-pull fresh review state (`review_completeness.py` exit 0), mutation-test the
claimed invariants (a guard that changes nothing when deleted is dead), enumerate siblings
of every changed symbol, and **stamp the verdict to (head SHA + pull timestamp)**. No
mechanized precondition met → no readiness claim; downgrade to "reviewed, findings above".

## 3. Present + post (Layer 3)

**Presentation is a script, not a vibe.** Build the deterministic artifact and open it:

```bash
pr-review-queue artifact --open        # newest run -> <run_dir>/review-artifact.html
```

Renders ONE self-contained local HTML file (summary table + per-PR postable comment,
inline comments, and full findings collapsed). This IS the presentation — point the user
at the file; do not paraphrase it. Then, per PR:

1. The artifact is the working surface; if the user edits the body/inline JSON, re-run
   `pr-review-queue artifact` (same input → same page).
2. Wait for explicit approval **per PR**.
3. Preview then post as ONE `event=COMMENT` GitHub review (anchors validated against the
   diff, out-of-diff ones dropped with a warning):

```bash
pr-review-queue post <PR> --preview
pr-review-queue post <PR>
```

Do NOT post without per-PR approval. Do NOT batch-post silently.

## Cleanup

```bash
pr-review-queue clean     # prune driver-owned checkouts
```
