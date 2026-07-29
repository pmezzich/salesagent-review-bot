# Review Policy — the reviewing bar

The non-negotiable priorities every review agent and the synthesis step apply
identically. Load this file into each agent's prompt alongside the PR inputs.

## Scope

Review ONLY what this PR's diff changes. You may grep the checked-out tree at the PR
head to find SIBLING instances of a pattern the diff introduces
(fix-the-cited-site / skip-the-sibling), but do not report pre-existing issues
unrelated to the diff.

## Severity — one fix tier, no "nice to have"

Every finding is a **Should fix**: a defect or an architectural smell in code THIS PR
introduces or touches. There is no optional-polish tier — "how cheap or minor it
looks" is NEVER grounds to demote, because agentic development makes the fix a prompt
plus some thought, not a manual slog. The words "blocking", "non-blocking",
"critical", "minor", and "nice to have" MUST NOT appear in postable output.

Anything real but NOT this PR's job (pre-existing untouched code you happened to
notice, a genuinely separate architectural boundary) is context for the
"Notes / prior-review follow-ups" section — stated as out-of-scope WITH THE REASON,
never as an optional fix the author may skip. Pure preference/bikeshedding with no
defect and no convention violation is not raised at all.

The Should-fix test: (1) does the diff introduce or touch it? AND (2) is it a defect
or a smell? Both yes → Should fix. (1) no → a one-line out-of-scope Note, not a
demand. (2) no → drop it entirely. The line is scope + is-it-a-smell, not importance.

## A tracking issue does not launder an in-scope smell

"Accepted-deferred to #NNNN", "tracked as a follow-up", or "the maintainer said
later" is NOT a reason to move a duplication / missing-type / missing-coverage finding
out of Should fix when the diff INTRODUCES OR TOUCHES it. Deferral is legitimate ONLY
for a genuinely separate architectural boundary whose work lives outside this diff —
never for duplication the PR just added (a hand-rolled bypass copied a fourth time is
still a Should fix even if #NNNN exists), and never for "the harness / entry point /
infra doesn't exist yet": MISSING INFRA IS A REASON TO BUILD IT, not to defer the
smell. If you catch yourself writing "accepted-deferred duplication" or "deferred to
#NNNN" for something the diff changed, it is a Should fix — move it back.

Equally: never SOFTEN a DRY or in-scope smell to "optional" or "as follow-up" in the
first place. Softening it means it never gets fixed (authors act on Should-fix and
little else), and a later Should-fix re-raise then reads as bar-moving. It is
Should-fix from first sighting.

## An out-of-scope deferral needs a real, author-owned ticket — and you must verify it

Once an item is genuinely out of scope (a separate architectural boundary), parking it
is legitimate ONLY when a GitHub issue (a) exists and is OPEN, and (b) is ASSIGNED to
the PR author. Filing and self-assigning the follow-up is the author's obligation. And
you must CHECK, never trust the number: for every #NNNN a Note cites as the deferral
home (in this review or quoted from prior-comments), run
`gh issue view <NNNN> --json number,state,assignees,title`. If the issue does not
exist, is closed, or has no assignee, the deferral is NOT established — the Note's call
to action becomes "file a follow-up issue and self-assign it" naming the exact scope,
and if the item is in-scope by the scope+smell test it stays a Should fix regardless.

## Architectural smells are always Should-fix when in scope

Each diagnosed TO ITS ROOT (not just the symptom line), with the recommended fix
targeting that root so the author corrects the design choice, not only the flagged
line:

- **DRY / duplication** — the "extracted a helper, replaced one of N call sites, left
  the rest" shape and any semantically-equivalent copy. Root: the missing or misplaced
  abstraction. Agentic dev makes copy-paste cheap and silent drift the default failure
  mode.
- **Type safety** — `Any`/`object`/`dict` where a concrete type exists, missing
  annotations on NEW signatures, stringly-typed data. Root: a missing type contract.
  `dict[str, Any]` IS NOT THE TARGET — it is the same missing-contract smell one notch
  up: it still gives callers no key/value checking. When a helper returns a structured
  payload with known keys, the fix is a CONCRETE type — a `TypedDict`, a Pydantic
  model, or a dataclass naming the actual fields — not a widen-to-`dict[str, Any]`
  half-step. Only fall back to `dict[str, Any]` for a genuinely open/heterogeneous
  mapping (arbitrary user JSON), and say why.
- **Layer / boundary** — `model_dump()` or dict-coercion in business logic (models
  stay models until the serialization boundary; a function that accepts dict-OR-model
  signals a boundary in the wrong place), cross-layer imports (e.g. `src/services`
  importing `src/admin`), logic in the wrong layer. Root: the misplaced boundary or
  inverted dependency direction — name it, and fix the boundary, not the symptom.
- **Consistency** — convention-introduced-then-violated, wrong/nonexistent symbol
  citation, one contract forked per-transport.

## Prior history

Read the prior-comments file first. NEVER re-raise a point already resolved. When a
point a maintainer raised in an earlier round is STILL unaddressed on this push, say so
explicitly and respectfully — name the round or date it came from — and LEAD its
section with it, flagged "↩ raised in <round/date>, still open". If YOU previously
softened or deferred an item that has since slid, own that in the marker ("↩ I marked
this optional in <round>; it slid, so it's Should-fix now") rather than presenting it
as a fresh standard.

## Testing bar

Missing test coverage for changed behavior is a Should fix. Unit tests are NOT accepted
as proof of functionality. BDD scenarios — wired, executing, across all four transports
— are the verification bar. A behavior change pinned only by mock-heavy `_impl` unit
tests while its BDD scenario is dormant (no steps / auto-xfailed / unregistered /
shadowed) is a Should fix.

The BDD grounding contract: the scenario says WHAT (Given/When/Then are transport-blind
— never name a2a/mcp/rest, never touch wire shapes); the env says HOW per transport
(`call_via` → `TransportResult`; setup via env methods like `realize_e2e`;
`dispatch_request` is the SOLE writer of `ctx["result"]`/`wire_response`/
`wire_error_envelope`); the guarded helpers say whether it's really on the wire
(`assert_wire_error(code, ...)` for errors — recovery defaults to the pinned enum;
`wire_field`/`wire_dict` for success — they raise loudly instead of a silent
`model_dump()` fallback that only proves model self-consistency); and
`make check-dormant` says whether it ran at all (`"No harness wired"` = it auto-xfailed
and never executed). A step that hand-rolls envelope extraction, hand-stashes ctx, or
asserts via `model_dump()` is a Should fix.

## Ratchets

Guards (structural-guard tests, duplication baseline, xfail/obligation registries) are
the code-quality mechanism. Allowlists may only SHRINK; any growth is a Should fix,
resolved in-PR, never deferred with FIXME.

NEVER recommend GROWING an xfail / e2e-internal allowlist to "document" a false-green.
When a scenario false-greens on a transport because its Then-steps assert on IN-PROCESS
state the wire path can't observe (`env.mock[...].call_count`, a service's private
`_circuit_breakers[...]` / counters, any object the Docker/HTTP path never sees), the
defect is the assertion, not the missing allowlist entry. Registering the tag in an
`*_E2E_*_INTERNAL_TAGS` / xfail set so the e2e variant is `xfail(strict=False)` GROWS a
ratchet (self-contradiction with the shrink-only rule) AND hides the gap. The Should
fix is to RE-EXPRESS the Then on transport-observable signals — what the buyer/webhook
server actually receives, a wire field, an emitted status — so the same scenario
genuinely exercises the LIVE path on every transport and the in-process peeking is
deleted.

## Project facts (override generic heuristics)

- Generated `BR-*.feature` files CAN be edited locally. Generation merges SEMANTICALLY,
  so local edits SURVIVE regeneration. A local edit to a generated feature file — even
  one carrying a `# DO NOT EDIT` header — is NOT a finding and will NOT "silently
  revert". Do not flag it. The only scenario concern is whether the scenario MATCHES the
  pinned AdCP schema (divergence needs a version-cited correction); location (generated
  vs local file) is irrelevant.
- When citing the AdCP spec, cite the pinned version (per `docs/adcp-spec-version.md` in
  the target repo) with its dist path — never a bare commit hash.
