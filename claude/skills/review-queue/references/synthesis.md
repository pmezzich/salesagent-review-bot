# Synthesis — one GitHub-ready review from the 8 agent reviews

Run this after the 8 dimensional reviewers have each written
`<review_dir>/review-<name>.md`. It produces the three artifacts the presentation and
post steps consume. Apply [`review-policy.md`](review-policy.md) throughout — the same
bar the agents used.

Inputs, per PR (absolute paths from the manifest):
- every `<review_dir>/review-*.md`
- the prior human review history at `<prior_comments>`
- the author diff at `<diff>` and the tree checked out at the PR head at `<checkout>`

## Steps

1. **Dedup** findings the agents raised independently — convergence across dimensions
   is the strongest signal.
2. **Verify** each Should-fix finding by re-running the agent's reproduction command
   against `<checkout>` (or the diff at `<diff>`). Drop false positives silently.
3. **Distill patterns, not a site catalog** (extract-a-helper-then-skip-the-siblings;
   guard-lands / variant-slips; convention-introduced-and-violated). Sites are evidence
   for a pattern, not the work queue.
4. Every surviving in-scope finding is a **Should fix** — there is NO Nice-to-have
   tier. DRY within scope, type-safety smells, layer/boundary smells, missing coverage
   for changed behavior, unit-instead-of-BDD, single-transport grading, and allowlist
   growth are ALL Should fix, each diagnosed to its architectural root. Order Should fix
   by impact (correctness first). Out-of-scope items go to Notes with a reason, never a
   fix tier.
5. **Prior review** — cross-reference `<prior_comments>`. Any Should-fix item a
   maintainer raised in an earlier round that is STILL unaddressed leads the Should-fix
   section, flagged "↩ raised in <round/date>, still open" — respectful, not scolding.
   Never re-raise a resolved point. Credit what got fixed in the Notes section.
6. **Voice pass — LAST**, after the substance is settled, over the postable body
   (artifact B) AND every inline comment (artifact C). FIRST read
   [`review-voice.md`](review-voice.md) and apply its full checklist. It changes ONLY
   prose — never a technical claim, file:line, code snippet, version citation, or call
   to action, and never drops or softens a finding.

## The three artifacts — do not conflate them

### A) `<review_dir>/FINDINGS.md` — the complete working document

The maintainer reasons over this in full. Structure:
1. A `# PR #<pr> — Review Findings` title.
2. A `## Recommended review (draft — not posted)` section at the VERY TOP containing
   the exact body you write to artifact B, PLUS a short "Inline comments" list
   mirroring artifact C (file:line → one-line gist), so the paste-ready review is the
   first thing the reader sees.
3. A `---` divider, then `# Full findings` — the complete working data.

The full-findings section is NOT a summary and must NOT be compressed: include the
verification log (each Should-fix finding + the reproduction you re-ran + its result —
this is where dropped false positives and stale-snapshot notes live, NOT in the
postable body), a convergence table (finding × agents-that-flagged), and EVERY
surviving finding written out in full — file:line, description, root-cause diagnosis,
reproduction command, recommended fix — Should fix ordered by impact. A reader must act
on this without opening the review-*.md files.

### B) `<draft>` — the postable review BODY

The overview + pattern explanations; inline site-comments go in artifact C, not here.

```
## Review — PR #<pr>
**Overview** — 2-4 sentences: what's right, then the headline of what needs fixing.
### Should fix
  For each pattern: a short **pattern name**, one-line explanation, a MINIMAL example
  (the before/after or the two drifted sites), the ROOT-CAUSE diagnosis (the missing
  abstraction / missing type contract / misplaced boundary), and a call to action that
  targets the root. Group the siblings of one pattern together (extract-then-skip-
  siblings DRY is ONE finding covering N sites, not N findings). Prior-raised-and-
  still-open items lead this section with "↩ raised in <round/date>, still open".
### Notes / prior-review follow-ups
  ONLY two kinds of line: (a) SPECIFIC credit for a prior-raised finding this push
  actually resolved (name it), and (b) a genuinely out-of-scope observation WITH the
  reason it is out of scope. Credit is a POINTER, not an inventory.
```

Hard rules for the postable body (the author sees only this file + the inline
comments):
- ONE fix tier (Should fix); the words "blocking", "non-blocking", "critical",
  "minor", "nice to have" MUST NOT appear.
- NEVER mention a dropped false positive, a stale snapshot/worktree, or which agent
  flagged/misfired. That bookkeeping lives ONLY in FINDINGS.md.
- NO clean-bill / "nothing found" / "dimension X clean" / generic-praise lines.
  Silence on a dimension IS the all-clear — do not narrate it. If a whole PR is clean,
  the review is SHORT: a one-line overview crediting that prior items landed,
  "### Should fix" with "None.", and at most one or two out-of-scope Notes.
- The voice pass (step 6) has run over this file and every inline comment.

### C) `<review_dir>/REVIEW-INLINE.json` — inline comments anchored to diff lines

A JSON array. Each element: `{"path": <repo-relative file>, "line": <line number in
the NEW version of the file>, "body": <the comment: the problematic pattern in one or
two sentences + a concrete call to action, GitHub markdown>}`.

Rules:
- ONLY anchor to a line this PR's diff actually adds or changes (a `+` line or an
  in-hunk context line in `<diff>`). Read the hunk headers to compute the correct
  NEW-file line number. A comment outside the diff is rejected by GitHub — if a
  finding's real site is not in the diff (a pre-existing sibling), keep it in the body.
- One inline comment per site. For an extract-then-skip-siblings DRY finding, put an
  inline comment on each in-diff duplicated site, each pointing back to the shared
  helper; describe the overall pattern once in the body.
- Keep each body tight and actionable; do not restate the overview.
- If nothing can be safely anchored, write `[]` — the body still posts.

Do NOT post anything to GitHub — the three files are the deliverable.
