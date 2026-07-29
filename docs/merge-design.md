# Ultimate Review Bot — Merge Design

*Merging **KonstantinMirin/prebid-salesagent-pr-review** (K) and **ChrisHuie/salesagent-review-harness** (C) into one salesagent PR-review bot. Grounded in a file-level read of both repos, not the READMEs.*

## TL;DR

They're **complementary halves of the same machine**:

- **K is the pipeline/shell** — deterministic scout→review→post plumbing, worktree pinning, HTML artifact, diff-anchored draft-only posting, `pr-radar` triage, zero-footprint install, single-sourced doctrine.
- **C is the rigor/brain** — the masking-gotcha doctrine, 10 mechanized self-testing detectors, the P1–P42 pattern catalog + reference corpus, and hard consolidation/readiness gates.

**Merge thesis:** take **K's 3-layer pipeline as the chassis**, drop **C's charter + detectors + corpus in as the grounding substrate**, and **union/dedup the 16 agents into ~11 canonical dimensions**. One synthesis+verify stage, one readiness gate. Then treat the merged agent/skill files as the trainable surface for SkillOpt (Chris's "single surface").

---

## What each tool actually is (code-verified)

### Konstantin — the pipeline
- **3 layers, skill-as-orchestrator (no separate engine).** `bin/pr-review-queue manifest` (L1) scouts candidates and builds deterministic inputs: canonical git diffs, changed files, prior human-review history, and a **sibling worktree pinned to the exact PR head**. The `pr-review-queue` SKILL (L2) fans out the 8 agents in parallel, then runs **one synthesis agent** that dedups/verifies/distills into 3 artifacts. `bin/pr-review-queue post` (L3) posts **one** `event=COMMENT` review after per-PR human approval, **validating inline anchors against the diff first** (avoids a 422 that rejects the whole review).
- **`worktree ≡ diff-scope` invariant** enforced end-to-end — agents never grade code newer than the diff; docs forbid re-fetching.
- **Doctrine single-sourced & live:** `review-policy.md` injected verbatim into all 8 agents + synthesis; skill dir symlinked so edits are live ("do not restate a shorter, drifting copy").
- **8 agents**, shared template (diff-first traversal reading callees one level deep, per-agent ID prefixes SG/BG/CON/DRY/LR/PP/RA/TQ, reproduction command mandatory on Critical/High): 3 doctrine (`adcp-grounding`, `bdd-grounding`, `ratchet-allowlists`) + 5 generic-but-tuned (`consistency`, `dry`, `layering`, `python-practices`, `testing`).
- **House style mechanized:** one-fix-tier severity ("Should fix" vs Notes vs dropped, banned hedging), plus `review-voice.md` — an AI-tell kill-list that changes prose only.
- **Notable gaps:** `pr-radar` has **no JSON output** (driver scrapes ANSI header text with `awk` — self-flagged as fragile); **Unix-only** (bash, `ln -sfn`, `xdg-open`, XDG dirs) — on this Windows box it's Git-Bash-only; salesagent specifics hardcoded in the shared policy.

### Chris — the rigor
- **Orchestrator** (`/full-review`, run from main session) with a **target-derivation ladder** (explicit path/glob > PR > working-tree) and a **dispatch-when table** (file globs → only the relevant specialists; logs which it *didn't* dispatch and why).
- **8 specialists, non-overlapping surfaces with explicit handoffs** (e.g. tenant-scoping: `code-patterns` owns grep-omission, `security` owns authz; wire tests: `test-integrity` owns existence/mock-only, `error-wire` owns envelope shape): `admin-ui`, `architecture-guards`, `bdd`, `code-patterns`, `error-wire`, `security`, `spec-conformance`, `test-integrity`.
- **The charter (`review-charter.md`) is the crown governance layer:** 13 non-negotiables, the **masking-gotcha doctrine** (§2 — 9 documented ways the toolchain false-greens: tox "congratulations" banner, agent-db port desync, persistent-schema false-green, DIRTY-merge CI skip, BDD auto-xfail masking dormant-vs-pass, worktree Read serving main content…), **symmetric verification** ("an empty result is a hypothesis to falsify"), `[observed]/[inferred]` tagging, a **banned-language list** ("clean/ready/looks good/optional/nice-to-have" forbidden), the **Disposition ladder** (FIX-NOW / FOLD-IN / FOLLOW-UP-with-link / WON'T-FIX), and two hard gates: **§4b semantic-SSOT consolidation** and **§4c readiness** (mechanized preconditions, stamped to head SHA + pull timestamp).
- **10 detectors** (`.claude/rules/private/detectors/*.py`), each a pure core + thin CLI + `--selftest` on synthetic fixtures, born from real misses: `disposition_ledger`, `review_completeness`, `citation_freshness`, `recovery_audit`, `sdk_spec_drift`, `ssot_docstring_duplication`, `pr_import_cycle`, `fixme_format`, `suggestion_audit`, `bump_check`. Correct exit taxonomy (2 = tool broken, 1 = worklist/gate, 0 = clean); 8 are **worklists** (adjudicate, don't block), 2 snapshot-staleness paths + the 2 process gates are true gates.
- **Reference corpus (17 files)** read as Step-0 grounding: the **P1–P42 pattern catalog** (frequency-ranked, detection-command-per-pattern — the "crown jewel"), `wire_envelope_policy`, BDD patterns+pitfalls, AdCP spec-grounding + SDK mapping, and the test-infra masking-gotcha files.
- **Notable gaps/risks:** `.claude/scripts/` is **empty** → `review-bdd` depends on `inspect_bdd_steps.py` / `detect_misrouted_transport.py` / `compile_bdd.py` that **don't exist** in the checkout; `.claude/reports/` empty (no golden exemplar); `review-admin-ui` has **no catalog** file; detectors hard-pin `SNAPSHOT_SPEC_VERSION='3.1.1'` which **already diverges** from the SDK-mapping memory (`3.1.0-beta.3` for adcp 5.7.0) — verify current pin; POSIX-only (`grep -rll` fails on native Windows).

---

## Where they already converge (shared DNA — merge on these, don't reconcile)

Diff-first traversal · wire-envelope-as-authority (guarded helpers `assert_wire_error`/`wire_field`/`wire_dict`) · spec/storyboard as ground-truth, SDK as cross-check · transport-parity across a2a/mcp/rest/e2e · reproduction/verification discipline · single-sourced doctrine injected into every agent · draft-only, human-in-the-loop posting · "green is necessary but not sufficient."

---

## Merge architecture

```
┌─ DELIVERY  (Konstantin's chassis) ───────────────────────────────┐
│  pr-radar (add JSON emit)  →  L1 scout + worktree-pin  →          │
│  L2 fan-out agents + synthesis  →  HTML artifact  →               │
│  L3 diff-anchored, preview-gated, draft-only post                 │
└──────────────────────────────────────────────────────────────────┘
        ▲ grounds every agent + the synthesis/readiness gates on ▼
┌─ RIGOR SUBSTRATE  (Chris's brain) ───────────────────────────────┐
│  review-charter (masking-gotcha doctrine, Disposition, banned     │
│  language, §4b/§4c gates)  +  10 detectors (deterministic pre-pass │
│  seeding the agents' worklist)  +  P1–P42 catalog & corpus        │
└──────────────────────────────────────────────────────────────────┘
        drives ▼
┌─ CANONICAL AGENTS  (union/dedup of the 16 → ~11) ────────────────┐
└──────────────────────────────────────────────────────────────────┘
```

**Flow:** `pr-radar` picks candidates → L1 pins the worktree & builds the diff → **detectors run as a deterministic pre-pass** that seeds each agent's worklist → agents review their dimension (charter as always-on posture) → **synthesis** does §4b semantic-SSOT + `disposition_ledger` gate + K's convergence/verification log, with `ratchet-allowlists` as a post-pass over *all* recommendations → **§4c readiness gate** stamps any "ready" claim → HTML artifact → draft-only post.

---

## Canonical agent set (16 → ~11)

| Merged dimension | From K | From C | Merge action |
|---|---|---|---|
| **spec-conformance** | adcp-grounding | spec-conformance | Unify; K's SG-rules + C's per-run pin derivation + verbatim gh-api fallback |
| **behavior-grading (BDD)** | bdd-grounding | bdd | Unify; owns transport-parametrization (K's BG-3). **Must supply C's missing `inspect_bdd_steps.py` or downgrade** |
| **wire-envelope / error** | (adcp SG-4, bdd BG-6) | error-wire | One "assert on wire through guarded helpers" rule; keep `harness_error_wire` MCP-bypass detail |
| **test-integrity** | testing | test-integrity | Unify; route protocol mock-floors → BDD dim, unit-quality → here |
| **dry** | dry | — | Keep (semantic, not textual, duplication) |
| **consistency** | consistency | — | Keep (pockets-of-convention) |
| **layering** | layering | architecture-guards | Merge (both = thin-wrappers / boundary / repo-pattern) |
| **python-practices** | python-practices | — | Keep — **most portable**, reusable across repos |
| **ratchet-allowlists** | ratchet-allowlists | — | Keep **as a synthesis post-pass**, not just a dimension |
| **security / isolation** | — | security | **Promote to first-class** (K noted this gap — isolation was scattered across dry/layering/testing) |
| **admin-ui** | — | admin-ui | Keep; **build it the catalog it lacks** |
| **code-patterns** | (spread) | code-patterns | Fold into the above dimensions (it's C's P1–P42 driver) |

**Deduped overlaps:** transport-parity (3 agents → BDD owns) · wire-vs-model-dump (2 → one rule) · thin-wrappers/typed-errors (3 → one) · mock-floor tests (2 → routed by scope).

---

## What to keep from each (crisp)

**Keep from Konstantin:** the 3-layer pipeline & skill-as-orchestrator · worktree≡diff-scope pinning · single-sourced doctrine injection · the deterministic HTML artifact · diff-anchored/preview-gated/draft-only posting · one-fix-tier severity + `review-voice` AI-tell kill-list · the 5 generic agents.

**Keep from Chris:** the charter wholesale (masking-gotcha doctrine, Disposition ladder, banned language, §4b/§4c gates, symmetric verification, "what I could not verify") · all 10 detectors as the deterministic floor · P1–P42 + the reference corpus · non-overlapping surface partition with explicit handoffs · target-derivation ladder + dispatch-when routing · internal-vocab hygiene (never leak detector names / "gold standard" into public comments).

---

## Gaps to fix during the merge

1. **Supply or downgrade** C's `review-bdd` dependency — `.claude/scripts/inspect_bdd_steps.py` is missing.
2. **Give `pr-radar` a JSON emit** and consume that instead of `awk`-scraping headers.
3. **Cross-platform** install/run (both are POSIX-only; this is a Windows-primary box → Git-Bash today). Make `grep -rll` etc. Python-native.
4. **Reconcile the AdCP pin** — detectors say `3.1.1`, SDK-mapping memory says `3.1.0-beta.3`/adcp 5.7.0. Verify the live pin; wire `bump_check` into CI so drift is a loud gate, not silent rot.
5. **Ship a golden reference report** (C's `.claude/reports/` is empty) and **a catalog for `admin-ui`**.
6. **Dedup the corpus vs charter**: many charter rules are pointers to memory files — keep charter as the operative rule, memory as the worked example, one canonical home per lesson.
7. **Detector efficiency**: `recovery_audit` + `sdk_spec_drift` + `suggestion_audit` all import `src.core.exceptions` + parse the same `error-code.json` — load the snapshot + subclass walk **once**.

---

## Build order

1. **Skeleton = K's repo layout** (bin/ drivers + skill + agents), zero-footprint install, Windows-portable.
2. **Drop in C's substrate**: copy the 10 detectors + charter + P1–P42 corpus; wire the detector pre-pass into L2; fix the shared-snapshot load.
3. **Author the ~11 canonical agents** (K template + C surface partition + charter as Step-0), deduping the overlaps per the table.
4. **Synthesis stage**: K's synthesis agent + C's §4b/§4c gates + `disposition_ledger`/`review_completeness` + `ratchet` post-pass; output = one-fix-tier + Disposition ladder + banned-language + "what I could not verify."
5. **Fix the gaps** (missing inspector, pr-radar JSON, golden report, admin-ui catalog, pin reconcile).
6. **Portability layer**: charter doctrine = transferable spine; salesagent detectors + P1–P42 + corpus = a swappable **knowledge pack** → lets the same engine serve the **buyer side** (one wire/spec engine for buyer + seller) and feeds the buyer-bug→companion-issue workflow.
7. **SkillOpt**: register the canonical agent/skill files as the trainable surface — the "single surface" endgame.

---

## Ties to Chris's directions

- **Adversarial multi-agent review** — this *is* the reviewer half; pairs against the buyer-agent's fix side (the loop we just ran live).
- **Single surface / SkillOpt** — the merged agent+skill set is the optimization target.
- **Buyer↔seller shared contract** — spec-conformance + wire-envelope + error taxonomy are the same surface on both sides; run one engine, swap the knowledge pack.

> *Caveat: `.claude/scripts/` emptiness, the `3.1.1` pin, and `.duplication-baseline` staleness are point-in-time reads of the two checkouts (2026-07-29) — re-verify before building.*
