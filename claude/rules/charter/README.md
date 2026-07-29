# claude/rules/charter/ — operating charter + doctrine

The always-on reviewer posture. Port Chris's `review-charter.md` + `reviewer-tooling.md`:

- The 13 non-negotiables and the **masking-gotcha doctrine** — the 9 documented ways the toolchain reports false-green (tox "congratulations" banner, agent-db port desync, persistent-schema false-green, DIRTY-merge CI skip, BDD auto-xfail masking dormant-vs-pass, worktree Read serving main content …). **This is the single most transferable asset in either source tool.**
- Epistemics: symmetric verification ("an empty result is a hypothesis to falsify"), `[observed]/[inferred]` tagging, empirical-over-static.
- Output discipline: the **banned-language list** ("clean/ready/looks good/optional/nice-to-have"), the **Disposition ladder** (FIX-NOW / FOLD-IN / FOLLOW-UP-with-link / WON'T-FIX), and a mandatory "What I could not verify" section.
- The gates: §4b consolidation calibration and §4c readiness preconditions.

This is the **transferable spine** — keep it repo-agnostic; the salesagent specifics live in `../corpus/` as a swappable pack.
