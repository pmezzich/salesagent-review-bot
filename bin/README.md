# bin/ — deterministic drivers

The scripted, reproducible plumbing (no LLM judgment here). Port from Konstantin's `bin/`:

- `pr-review-queue` — Layer 1 (scout candidates, build canonical diffs, pin a sibling worktree to the exact PR head) and Layer 3 (post **one** `event=COMMENT` review after per-PR approval, validating inline anchors against the diff first).
- `pr-radar` — buckets every open PR into "what action you owe." **Add a JSON emit** and consume that instead of scraping header text.
- `pr-review-artifact` — deterministically assembles a run into one self-contained local HTML page.

Make all three **cross-platform** (they are currently POSIX/Git-Bash-only).
