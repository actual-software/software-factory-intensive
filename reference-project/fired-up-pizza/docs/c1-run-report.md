# C1 Run Report · Fired Up Pizza

The C1 deliverable. Captures the capstone run end-to-end for one feature the
factory had not seen before, records every intervention, audits the run
against the criteria in [`improvement-criteria.md`](./improvement-criteria.md),
and ends with a ship/loop/retire decision.

---

## Feature

The feature is an optional **"Special instructions" text field** on the
order form. Customers can type a short note ("extra napkins", "ring the
buzzer twice") which is stored on the order row and surfaced to staff
wherever an order is displayed. It is a fair capstone test because no prior
Fired Up Pizza feature has touched the order-intake form or added a
staff-visible freeform string, and the scope is small enough that any
hand-holding would be visible in the run. What I personally did not know
going in: how much input sanitization the factory would require for a
freeform field rendered into a staff view, and whether the field should be
capped at one line, a few lines, or left unlimited — both are decisions I
wanted the factory's Review Standards to make without me.

---

## Run Summary

- **Feature:** Customer order notes (special instructions)
- **Source:** GitHub issue [#19 "Add special instructions field to order form"](https://github.com/example/fired-up-pizza/issues/19), filed by the founder and labeled `factory-ready`
- **Started:** 2026-04-19T09:12:00-04:00 (Planner sling)
- **Ended:** 2026-04-19T10:37:00-04:00 (Deployer PASS)
- **Total elapsed:** 1h 25m
- **Human interventions:** 2 (both config-level; see below)
- **Artifacts produced:**
  - `work-packages/order-notes.md`
  - `docs/adr/0002-order-notes-sanitization.md`
  - `design/order-notes-spec.md`
  - `src/**` commits on `feat/order-notes` (7 commits)
  - `review-reports/order-notes-review.md`
  - `release-gates/order-notes-gate.md`

---

## Interventions (from [`docs/factory-iterations.md`](./factory-iterations.md))

Only config-level interventions are allowed in C1. Both interventions below
were made *after* an upstream stage's output exposed a gap; the stage was
then re-slung with the updated config.

| Stage     | File edited                                             | Reason |
|-----------|---------------------------------------------------------|--------|
| Reviewer  | `docs/PROJECT_MANIFEST.md → Review Standards → Security` | First Reviewer pass did not flag an unsanitized render of the new field in the staff view. Added a rule: "Free-form user input rendered in staff views must be sanitized against XSS". Re-slung Reviewer; new verdict flagged the render as High-severity. |
| Coder     | `packs/actual/builder/prompts/builder.md.tmpl`          | After the Reviewer surfaced the High finding, the Coder's next sling attempted `dangerouslySetInnerHTML` as a fix. Added a pre-flight: any new React prop accepting freeform strings must either be sanitized at the API boundary or document its sanitizer at render. Re-slung Coder. |

No chat-level content was typed into any agent. No artifact was hand-edited.
No stage was skipped.

---

## Against W4 Improvement Criteria

Audit using every criterion in [`improvement-criteria.md`](./improvement-criteria.md).
"Movement vs. prior runs" compares this C1 run's value to the rolling
most-recent-five metric that criterion tracks.

| Criterion | Value observed on this run | Movement vs. prior runs |
|-----------|----------------------------|-------------------------|
| 1 · Review loop-backs trend down (target ≤1 of 5) | 1 Coder loop-back (after the Review Standards tightening) | **No change** — most-recent-5 aggregate now 1 of 5, at target |
| 2 · High-severity findings trend down (target 0 of 5) | 1 High surfaced by the re-slung Reviewer, resolved pre-merge | **Regressed** vs. target — but caught by the factory itself, not post-deploy |
| 3 · Lint regressions caught by Coder (target 0 of 5) | 0 lint-failure FAILs on the release gate | **No change** — at target, continuing the streak since Loop 1 |
| 4 · AC-test coverage at first review (target 0 of 5) | 0 findings citing missing AC tests on first Reviewer pass | **No change** — at target |
| 5 · Planner cites Domain Model (target 100%) | Work package cites `Order` and introduces the `Order.notes` field explicitly | **No change** — 100% held for the most-recent-5 work packages |
| 6 · External bugs trace to an iteration (Per incident) | N/A — no external bug from this run yet | **Not applicable this run** — re-evaluate after the feature has been in production for a week |

---

## One Follow-up

The single loudest signal from this run is the **Criterion 2 regression**:
a High-severity finding that only surfaced because the Review Standards got
tightened mid-run. Without the intervention, the XSS vector would have
shipped. That is exactly the pattern the factory is supposed to catch
*before* the Reviewer — at the Coder stage — so the next loop should push
the check upstream.

- **Target criterion:** Criterion 2 — High-severity review findings trend down
- **Proposed change (file + section):** `packs/actual/builder/prompts/builder.md.tmpl → ## Pre-flight checks` — add an explicit pre-flight: any new surface that accepts freeform user input must include either a Zod schema validating length + character set, or an explicit sanitizer call at render, before the Coder flips the bead to `needs-review`. If neither applies, the Coder must cite the reason in the commit message.
- **Expected impact:** Eliminate repeat High-severity XSS findings on first Reviewer pass. Moves Criterion 2 from the 1 High on this run toward the steady-state 0-of-5 target over the next five features.

Do **not** apply this change as part of closing the capstone — log it as
the next loop to enter in a W4-style cycle. See the Capstone Decision
section below for priority.

---

## Capstone Decision

Per Part 5 of `CAPSTONE_1_GUIDE.md`, three calls close the capstone:

### Ship?

**Yes.** `feat/order-notes` merges cleanly and all six Release Criteria
rows are PASS in `release-gates/order-notes-gate.md`. The one High finding
was resolved before the final Reviewer verdict; the Deployer's gate is
clean. Merging `feat/order-notes` into `main` immediately after this report
is committed.

### Loop?

**Yes — promote the Criterion 2 follow-up above the currently queued Loop 2.**
The "Happy-path narrative in every work package" lever queued in
`factory-iterations.md` 2026-04-18 targets Criterion 1 (already at target on
this run). High-severity regressions are more expensive than review
loop-backs, so the Criterion 2 follow-up is the higher-priority loop to run
next. `factory-iterations.md` has been updated to re-order the queue.

### Retire?

**One candidate: the `aggregate-vague-acceptance-criteria.md` feedback
loop** under `feedback-loops/`. It was introduced during the loyalty-points
run when the Planner produced an under-specified work package. The last
three Planner runs (menu-search, order-history, and this order-notes run)
have all produced acceptance criteria specific enough that the aggregator
never fired. The loop is a candidate for retirement; one more dormant run
and it should be deleted in favor of relying on the Criterion-5
manifest-citation check, which covers the same ground more directly.

---

## References

- Capstone guide: [`../../../curriculum/capstone/C1/CAPSTONE_1_GUIDE.md`](../../../curriculum/capstone/C1/CAPSTONE_1_GUIDE.md)
- Improvement criteria (the audit lens): [`./improvement-criteria.md`](./improvement-criteria.md)
- Iteration log (the full config-change history): [`./factory-iterations.md`](./factory-iterations.md)
- Project manifest (Review Standards, Release Criteria): [`./PROJECT_MANIFEST.md`](./PROJECT_MANIFEST.md)
