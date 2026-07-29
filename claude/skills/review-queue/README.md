# claude/skills/review-queue/ — the orchestrator (Layer 2)

The skill *is* the orchestrator (no separate engine). Port from Konstantin's `skills/pr-review-queue` and fold in Chris's gates:

1. Fan out the canonical agents in parallel over the pinned worktree.
2. Run the **detector pre-pass** (see `../rules/detectors/`) to seed each agent's worklist.
3. One **synthesis** pass: semantic-SSOT consolidation (Chris §4b) + `disposition_ledger` gate + Konstantin's convergence/verification log + the `ratchet-allowlists` post-pass over *all* recommendations.
4. The **§4c readiness gate** stamps any "ready" claim to (head SHA + pull timestamp) via `review_completeness`.

Enforce the `worktree ≡ diff-scope` invariant end-to-end: never grade code newer than the diff. Load the doctrine files verbatim into every agent + synthesis.
