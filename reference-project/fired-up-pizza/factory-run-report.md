# Factory Run Report · Order History Page

**Capstone run date:** 2026-04-16
**Feature bead:** `fup-order-history-2026-04-16`
**Feature ticket:** FUP-6 (Order History page)
**Run duration:** 78 minutes (target: ~90 minutes)
**Final stage reached:** Deployer (release gate emitted)
**Branch:** `feat/order-history`

---

## Feature

**Order history page** — Customers can view their past orders by entering their phone number. Each order shows the item list with customizations, order total, date, and final status. The page lists orders in reverse chronological order and shows "no orders found" when the phone number has no matches.

Chosen as the capstone feature because:
- It touches three layers (DB query, API handler, page component) without architectural drift from prior loyalty work
- It has one genuine open question (pagination strategy for phone numbers with many orders) for the Architect
- The acceptance criteria from FUP-6 are specific enough to test

---

## Pipeline Results

| Stage | Agent | Status | Artifact | Slings | Config Changes |
|-------|-------|--------|----------|--------|----------------|
| Plan | planner | PASS | `work-packages/order-history-page.md` | 1 | None |
| Architect | architect | PASS | `docs/adr/0002-order-history-pagination.md` | 2 | Architect prompt: added rule *"List ≥3 storage or access-pattern alternatives when a scaling question exists. One-option ADRs are rejected."* |
| Design | designer | PASS | `design/order-history-spec.md` | 1 | None |
| Code | coder | PASS | `src/pages/OrderHistoryPage.tsx`, `src/api/orderHistory.ts`, `src/db/orderHistory.ts` + tests | 2 | Coder prompt: added rule *"Pagination helpers must accept `cursor` as `string \| null`, not `number`. Never rely on sequential numeric offsets for ordered lists."* |
| Review | reviewer | PASS (APPROVE, 2 Low findings) | `review-reports/order-history-review.md` | 1 | None |
| Deploy | deployer | PASS (6/6 required) | `release-gates/order-history-gate.md` | 1 | None |

**Total slings across the run:** 8 (target for a well-tuned factory: ≤10)
**Total config edits during the run:** 2 (both encoded into pack prompts; no ad-hoc chat corrections)

---

## Timeline

| Time | Event |
|------|-------|
| 00:00 | Bead created: `fup-order-history-2026-04-16`. Slung to Planner. |
| 00:06 | Planner emitted `work-packages/order-history-page.md`. Slung to Architect. |
| 00:14 | Architect sling 1 returned a single-option ADR (only proposed cursor pagination). Rejected; architect prompt edited with the ≥3 options rule; re-slung. |
| 00:22 | Architect sling 2 emitted `docs/adr/0002-order-history-pagination.md` with three options (numeric offset, cursor pagination, keyset pagination). Decision: cursor pagination on `created_at`. Human gate approved at 00:24. |
| 00:32 | Designer emitted `design/order-history-spec.md`. Slung to Coder. |
| 00:48 | Coder sling 1 failed a test: cursor was typed as `number` instead of `string \| null`. Coder prompt edited; `git reset --hard HEAD`; re-slung. |
| 00:59 | Coder sling 2 clean. 12/12 tests passing. Feature branch pushed. Slung to Reviewer. |
| 01:08 | Reviewer emitted `review-reports/order-history-review.md` — APPROVE with 2 Low findings (JSDoc terseness, missing `aria-busy` during fetch). Human gate approved at 01:10. |
| 01:18 | Deployer emitted `release-gates/order-history-gate.md` — PASS (6/6 required). |

---

## Ad-Hoc Prompts Used

**Target:** 0 ad-hoc prompts. Result: **0** ad-hoc prompts.

Every correction during the run was encoded into a pack prompt file and re-slung. The two config edits (Architect alternatives rule, Coder cursor-typing rule) are committed on the `expand-curriculum-readmes` branch alongside this report.

---

## Feedback Rules Triggered

Three feedback rules loaded at the start of the run. Results:

| Rule | File | Triggered? | Notes |
|------|------|-----------|-------|
| Reactive: missing `try`/`catch` on async handlers | `feedback-loops/coder-missing-try-catch.md` | No | Rule caught it up front — Coder wrote handlers with explicit `try`/`catch`. |
| Aggregate: vague acceptance criteria | `feedback-loops/aggregate-vague-acceptance-criteria.md` | No | Work package ACs were measurable. |
| External: customer points discrepancy | `feedback-loops/external-customer-points-discrepancy.md` | No | Capstone run, no customer events. |

Two feedback rules were *created* during this run (the Architect and Coder prompt edits above). Both recorded as new entries in `DECISIONS.md` but not yet promoted to full reactive rules under `feedback-loops/`.

---

## Success Criteria Check

Pulled from `docs/PROJECT_MANIFEST.md` → Factory-Level Success.

| Criterion | Result |
|-----------|--------|
| Feature completed with zero ad-hoc prompts (all behavior from config) | PASS |
| All 6 pipeline stages produced committed artifacts | PASS |
| Each handoff between agents used the defined artifact paths (no out-of-band communication) | PASS |

---

## Retrospective

### Keep

The **single-bead-across-the-run** discipline worked. Every stage referenced the same `fup-order-history-2026-04-16` bead, and `bd show` at any time told us where the work was. No ambiguity about which work package, which ADR, which branch a reviewer was reviewing.

### Change

The Architect's initial single-option ADR caught us off guard. The Architect prompt already said "consider alternatives" but not "list at least three." Vague imperatives get vague output. Next capstone, re-read every agent prompt for *measurable constraints* the night before and tighten any that read as aspirations.

### Question

When should an ADR reject an option outright vs. document it as a trade-off? The cursor-pagination ADR documented keyset pagination as "rejected for SQLite performance reasons." Should it have been removed from the ADR entirely? Leaning toward keeping it — the rejection rationale is itself valuable history. Revisit after a few more capstone runs.

---

## Artifacts Produced

- `work-packages/order-history-page.md`
- `docs/adr/0002-order-history-pagination.md`
- `design/order-history-spec.md`
- `src/pages/OrderHistoryPage.tsx` + tests
- `src/api/orderHistory.ts` + tests
- `src/db/orderHistory.ts` + tests
- `review-reports/order-history-review.md`
- `release-gates/order-history-gate.md`
- `DECISIONS.md` — two new entries
- Updated: `packs/architect/prompts/architect.md`
- Updated: `packs/coder/prompts/coder.md`

Feature branch `feat/order-history` is mergeable with `main`. Final merge pending founder sign-off outside the capstone session.
