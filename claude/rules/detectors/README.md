# claude/rules/detectors/ — mechanized, self-testing gates

The deterministic floor beneath LLM judgment — run as a **pre-pass** that seeds the agents' worklists. Port Chris's 10 detectors (each: pure core + thin CLI + `--selftest` on synthetic fixtures, offline):

`disposition_ledger` · `review_completeness` · `citation_freshness` · `recovery_audit` · `sdk_spec_drift` · `ssot_docstring_duplication` · `pr_import_cycle` · `fixme_format` · `suggestion_audit` · `bump_check`

- **Exit taxonomy:** `2` = tool/snapshot broken (don't trust), `1` = actionable worklist/gate, `0` = clean.
- 8 are **worklists** (adjudicate, don't block); the 2 snapshot-staleness paths + `disposition_ledger`/`review_completeness` are true gates.
- **Efficiency:** `recovery_audit` + `sdk_spec_drift` + `suggestion_audit` all import `src.core.exceptions` and parse the same `error-code.json` — load the snapshot + subclass walk **once** and share.
- **Portability:** make `grep -rll` etc. Python-native; `review_completeness` must parametrize `--repo` (hardcodes `prebid/salesagent`) and has no `--selftest`.
- Wire `bump_check` into CI so an AdCP pin bump is a loud gate, not silent rot.
