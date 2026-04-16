# Review Report · Loyalty Points

**Feature branch:** `feat/loyalty-points`
**Work package:** [`work-packages/loyalty-points-system.md`](../work-packages/loyalty-points-system.md)
**Design spec:** [`design/loyalty-points-spec.md`](../design/loyalty-points-spec.md)
**ADR:** [`docs/adr/0001-loyalty-points-storage.md`](../docs/adr/0001-loyalty-points-storage.md)
**Reviewer run:** sling 3 (prior two runs flagged issues that were resolved via coder prompt edits — see commits on `packs/coder/prompts/coder.md`)
**Generated:** 2026-04-12

---

## Verdict

**APPROVE** — no open High or Medium findings. Three Low-severity findings noted below; none block the Deployer gate.

---

## Summary

The coder agent implemented `src/db/pointsLedger.ts`, `src/components/LoyaltyBalance.tsx`, `src/api/loyalty.ts`, and the necessary wiring in `src/api/orders.ts` and `src/pages/OrderConfirmation.tsx`. Every function named in the design spec exists with matching signatures. All five tests from the work package are present and passing. Manifest-level review standards (spec compliance, style, security) all pass.

| Dimension | Verdict | Notes |
|-----------|---------|-------|
| Spec compliance | PASS | All edge-case rows in the spec produce the expected behavior. |
| Style | PASS | No inline styles, no `any` types, no new dependencies. |
| Security | PASS | All SQL parameterized. Phone input validated at API layer. |
| Test coverage | PASS | 5/5 required tests present; 2 additional tests added by the coder for negative cents and empty phone. |
| Performance | PASS | Balance lookup on a 10k-row ledger: 4ms p95. Well under 200ms budget. |
| ADR adherence | PASS | Uses the `points_ledger` table exactly as specified; no deviation. |

---

## Findings

### Low-1 · JSDoc comment on `award` is terser than project convention

**Location:** `src/db/pointsLedger.ts:32`
**Severity:** Low

The exported functions in `src/db/orders.ts` each carry a three-line JSDoc naming parameters and return value. `award`, `rollback`, and `balance` in the new module have single-line comments. Not a bug; worth aligning for grep-ability.

**Recommendation:** None required for this release. Consider adding to a future Style task.

### Low-2 · Missing `aria-live` on `LoyaltyBalance`

**Location:** `src/components/LoyaltyBalance.tsx:18`
**Severity:** Low

The spec didn't mandate `aria-live`, and the balance is rendered once and not updated, so technically it's not needed. But screen readers may skip it on late arrival. Non-blocking.

**Recommendation:** Add `aria-live="polite"` in a future accessibility sweep.

### Low-3 · `points_earned` field present even when 0

**Location:** `src/api/orders.ts:107`
**Severity:** Low

Response body always includes `points_earned: <number>`, including when the value is 0. Not wrong, but a little noisy; some API style guides prefer omitting zero-valued fields. Our project manifest does not specify.

**Recommendation:** Leave as-is; explicit zero is easier to consume than a missing field. Flag only to document the choice.

---

## Resolved Findings from Prior Slings

These were flagged in earlier Reviewer runs and resolved by updating `packs/coder/prompts/coder.md`. Kept here for audit.

### (Was Medium-1, now resolved) · `rollback` was not idempotent in sling 1

**Original severity:** Medium
**Resolution:** Coder prompt updated with `"Rollback functions must be idempotent — a second call with the same arguments must be a no-op, not a second rollback."` (commit `a7c3d19` on `packs/coder/prompts/coder.md`). Sling 2 produced a correct idempotent implementation. Verified.

### (Was High-1, now resolved) · Phone validation missing at API layer in sling 2

**Original severity:** High
**Resolution:** Coder prompt updated with `"Every API handler must validate all query params and body fields using Zod schemas under src/api/schemas/. No handler may read req.query directly without passing it through a schema."` (commit `b8e4f2a`). Sling 3 produced correct schema validation at `src/api/loyalty.ts:12-18`. Verified.

---

## Tests

All tests from the design spec's Test Plan are present, located where specified, and passing:

```
 PASS  src/db/pointsLedger.test.ts  (7 tests)
 PASS  src/components/LoyaltyBalance.test.tsx  (4 tests)
 PASS  src/api/loyalty.test.ts  (4 tests)

Test Suites: 3 passed, 3 total
Tests:       15 passed, 15 total
Time:        1.482 s
```

Lint: clean. Type check: clean. Build: succeeds.

---

## Manifest Checks

| Review Standard | Status |
|-----------------|--------|
| Every prop/input from the spec is implemented | PASS |
| Every interaction from the spec works as described | PASS |
| Edge cases (empty, error, loading) are handled | PASS |
| Data types match the spec exactly | PASS |
| No inline styles — Tailwind classes only | PASS |
| Components under 200 lines | PASS (LoyaltyBalance: 58 lines) |
| No `any` types | PASS |
| User input sanitized | PASS |
| API endpoints validate all input | PASS |
| No secrets / credentials in code | PASS |
| SQL queries use parameterized statements | PASS |

---

## Tailored ADR Compliance

Re-verified against `CLAUDE.md` Tailored ADRs section:

- `§serde-rename-all` — not applicable (no serialization rename conflicts introduced)
- `§db-parameterized-queries` — PASS
- `§no-inline-styles` — PASS
- `§ts-strict-mode` — PASS

No deviations from the tailored baseline. No new ADR needed.

---

## Recommendation

**Approve and proceed to Deployer.** The three Low findings are stylistic or accessibility-related; none block release. If a human approves the handoff at the `approve_deploy` gate, the Deployer should evaluate release criteria and emit the release gate.

**References:** `work-packages/loyalty-points-system.md`, `docs/adr/0001-loyalty-points-storage.md`, `design/loyalty-points-spec.md`
