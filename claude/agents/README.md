# claude/agents/ — the canonical review agents

The ~11 dimensions are the **union/dedup** of the two source sets (see the mapping table in `docs/merge-design.md`):

- Konstantin's 8: `adcp-grounding`, `bdd-grounding`, `consistency`, `dry`, `layering`, `python-practices`, `ratchet-allowlists`, `testing`.
- Chris's 8: `admin-ui`, `architecture-guards`, `bdd`, `code-patterns`, `error-wire`, `security`, `spec-conformance`, `test-integrity`.

Deduped overlaps: transport-parity (BDD owns it) · wire-envelope (one guarded-helper rule) · thin-wrappers/typed-errors (one) · mock-floor tests (routed by scope). `ratchet-allowlists` runs as a **synthesis post-pass**, not just a dimension. Promote **security/isolation** to first-class; give **admin-ui** the catalog it lacks.

Each agent: diff-first traversal (read callees one level deep), the charter as Step-0, reproduction-command discipline on every high-severity finding, and single-fix-tier output.
