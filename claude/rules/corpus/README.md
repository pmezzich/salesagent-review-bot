# claude/rules/corpus/ — knowledge pack (the swappable half)

Step-0 grounding the agents read. Port Chris's memory corpus:

- **`reference_review_patterns.md` — the P1–P42 catalog** (frequency-ranked, a detection command per pattern). The crown jewel and the bot's primary defect catalog.
- **Wire-contract testing** — `wire_envelope_policy.md` + `harness_error_wire_per_transport_mechanics.md` + P24/P28/P38. One concept at three altitudes; keep all three (the MCP direct-call bypass detail only lives in `harness_error_wire`).
- **BDD** — patterns (24 how-it-works) + pitfalls (9 how-it-silently-lies); complementary, keep both.
- **AdCP grounding** — spec-grounding + SDK mapping ("spec/storyboard is ground-truth, SDK is a cross-check; verify version timing verbatim, not via a summarizing fetch"). The mapping table is perishable — re-verify per wheel.
- **Masking-gotcha / false-green cluster** — the test-infra gotcha files (agent-db, tox banner, dirty-merge CI skip, venv corruption, precommit mypy pin). Demote the RESOLVED specifics; keep the durable diagnostic.

This whole directory is **salesagent-specific** — it's the knowledge pack. Swap it (e.g. a buyer-side pack) to point the same charter + engine at another repo.
