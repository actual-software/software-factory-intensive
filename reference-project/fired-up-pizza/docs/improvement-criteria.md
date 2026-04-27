# Improvement Criteria · Fired Up Pizza

The W4 deliverable. Defines the rules used to judge "is run N+1 better than
run N?" for the Fired Up Pizza factory. Every criterion is anchored to a
signal that the factory already emits, so improvement is measured rather
than vibed.

---

## Signal Inventory

Signals the factory emits today, drawn from the L2–L4 runs of the
loyalty-points and order-history features.

| Signal | Source | What it tells you | Volume so far |
|--------|--------|-------------------|---------------|
| Review findings by severity | `review-reports/*.md` (Findings table) | Where the Coder is falling short of `PROJECT_MANIFEST.md → Review Standards` | 11 reviews · 38 Low · 14 Med · 3 High |
| Review → Coder loop-backs   | `factory-iterations.md` + REQUEST_CHANGES verdicts | How often a feature needed ≥2 Coder runs | 3 of 7 features looped back at least once |
| Release-gate FAILs by criterion | `release-gates/*.md` (Required table rows) | Which release criterion is the bottleneck | Lint failure × 4, missing AC test × 2 |
| Prompt iterations per stage | `factory-iterations.md` | Which stage's config is most unstable | Reviewer 5 edits, Coder 4, Designer 3, Planner 2, Architect 1 |
| Time to first work package  | `gc events --follow` (Planner sling → bead update) | Planner throughput | Median 7m, p95 18m across 7 features |
| External bug reports        | GitHub issues filed by the founder against shipped features | Real-world validation of factory output | 2 bugs in 7 features (1 spec gap, 1 lint regression that landed pre-tightening) |

---

## Improvement Criteria

### Criterion 1: Review loop-backs trend down

**Signal:** Review → Coder loop-backs per feature.

**Direction of improvement:** Lower.

**Target:** ≤1 loop-back on the next five features.

**How we measure:** Count REQUEST_CHANGES verdicts in `review-reports/*.md`
that are matched by a subsequent Coder iteration in `factory-iterations.md`.
Roll up over the most recent five features.

**Cadence:** Per run.

---

### Criterion 2: High-severity review findings trend down

**Signal:** Review findings tagged `High` in `review-reports/*.md`.

**Direction of improvement:** Lower.

**Target:** Zero High-severity findings in the next five features.

**How we measure:** `grep -c "Severity: High"` across the five most recent
review reports. The `## Severity Scale` in `PROJECT_MANIFEST.md` defines
High; the count is unambiguous.

**Cadence:** Per run.

---

### Criterion 3: Lint regressions caught by the Coder, not the Deployer

**Signal:** Release-gate FAILs whose evidence row is `npm run lint` on the
feature branch.

**Direction of improvement:** Lower (toward zero).

**Target:** Zero lint-failure FAILs in the next five features.

**How we measure:** Count rows in `release-gates/*.md` where the criterion
`Lint clean` reads FAIL. The Deployer cites the line that failed; counting
those gives the per-run rate.

**Cadence:** Per run.

---

### Criterion 4: Acceptance-criteria tests are present at first review

**Signal:** Reviewer findings citing the rule "Every acceptance criterion in
the work package has a matching test" from Review Standards.

**Direction of improvement:** Lower.

**Target:** Zero such findings in the next five features.

**How we measure:** Search review reports for that exact rule citation; one
mention is one missed test mapping. The Reviewer is required to cite the
rule verbatim under `## Constraints`.

**Cadence:** Per run.

---

### Criterion 5: Planner work packages cite the manifest's Domain Model

**Signal:** Manual scan of `work-packages/*.md` for explicit references to
the entities listed in `PROJECT_MANIFEST.md → Domain Model` (Order,
MenuItem, Topping, etc.).

**Direction of improvement:** Higher (every work package should cite at
least one domain entity).

**Target:** 100% of new work packages cite ≥1 domain entity.

**How we measure:** Manual review of the most recent five work packages.
Promote to an automated check via the `actual` CLI once the rule is stable.

**Cadence:** Weekly review.

---

### Criterion 6: External bugs trace back to a logged factory iteration

**Signal:** GitHub issues filed against shipped features, cross-referenced
with `factory-iterations.md`.

**Direction of improvement:** Higher (every external bug should produce a
follow-up iteration entry).

**Target:** 100% of external bugs filed since the last review have a
matching `factory-iterations.md` entry within 7 days.

**How we measure:** Open the GitHub issues list filtered to "shipped from
factory"; for each, find the `factory-iterations.md` row that addresses it.
Missing rows are themselves the gap to close.

**Cadence:** Per incident.

---

## Loop 1 Result

The first loop run for Fired Up Pizza targeted **Criterion 3** (lint
regressions). The lever was a single Coder-prompt edit.

- **Criterion touched:** Criterion 3 — Lint regressions caught by the Coder.
- **Change applied:** `packs/actual/builder/prompts/builder.md.tmpl` — added
  a final-step hard gate requiring `npm run lint && npm run type-check` to
  exit 0 before the Coder flips the bead to `needs-review`. Previously the
  Coder ran lint but did not block on it.
- **Feature used to measure:** `feat/menu-search` (a small, scope-bounded
  feature comparable to the loyalty-points run that produced the original
  signal).
- **Before:** Lint-failure FAILs in the prior five features = 4 of 5.
- **After:** Lint-failure FAILs in `feat/menu-search` = 0; Reviewer flagged
  no lint-related Med-severity findings either.
- **Net movement:** Improved. The change is committed and the iteration is
  logged in `factory-iterations.md` under 2026-04-12.

---

## Loop 2 Plan

A second loop is already queued, targeting **Criterion 1** (loop-backs).
The signal: the loyalty-points and order-history runs both looped back
because the work packages had ambiguous "happy path" definitions.

- **Lever:** Tighten the Planner prompt (`packs/actual/planner/prompts/planner.md.tmpl`)
  to require an explicit "Happy path narrative" subsection in every work
  package, with three to five concrete user actions and the system response.
- **Expected impact:** Drops the loop-back rate from 3-of-7 toward the
  target of ≤1-in-5. To be measured against the next five features.
- **Owner:** the founder (manual prompt edit, then the loop self-measures).
