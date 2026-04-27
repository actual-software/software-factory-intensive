# Work Package · Loyalty Points System

**Bead:** `fup-loyalty-2026-04-10`
**Planner run:** sling 2 (first run rejected for vague ACs — see `feedback-loops/aggregate-vague-acceptance-criteria.md`)
**Author agent:** planner
**Generated:** 2026-04-10

---

## Goal

Customers earn points for every order they place and can see their running balance on the order confirmation page. Redemption (spending points) is explicitly out of scope for this work package — a future work package will handle the redemption flow.

## User Stories

### Story 1 — Award points on order placement

**As a** customer who has just placed an order
**I want** my order to earn loyalty points proportional to the amount I spent
**So that** I'm rewarded for continuing to order from Fired Up Pizza

**Acceptance Criteria**

1. Points are awarded immediately after the `orders` row is inserted with status `placed`.
2. The point formula is `floor(order.total_cents / 100)` — 1 point per whole dollar of order total.
3. Points are associated with the customer's phone number (the project's existing identity key).
4. If the order is later cancelled (status transitions to `cancelled`), the points are rolled back.
5. Awarded points persist across app restarts.
6. The API response for `POST /api/v1/orders` includes a `points_earned` field whose value is the award for this order.

### Story 2 — Display running balance on confirmation page

**As a** customer on the order confirmation page
**I want** to see my running loyalty points balance
**So that** I know how close I am to future rewards

**Acceptance Criteria**

1. The confirmation page fetches the customer's balance using their phone number from the order just placed.
2. The balance appears within 1 second of the confirmation page render (p95 on an SQLite store with 10k ledger rows).
3. If the balance lookup fails, the page renders without the balance and logs the error — it does not block the confirmation.
4. The balance value shown equals the sum of all awards minus the sum of all redemptions for that phone number. Redemptions are always 0 in this work package but the query must account for them so later features don't require re-implementing the balance math.

## Tests

Required tests the Coder must write (enforced by the Reviewer):

1. `award(phone, points)` writes a row to `points_ledger` with the correct `type = 'award'`, `points`, and timestamp.
2. `award` computes points correctly from a given `order.total_cents`: 950¢ → 9 points, 1234¢ → 12 points, 100¢ → 1 point, 99¢ → 0 points.
3. `balance(phone)` returns `SUM(points) WHERE phone = ? AND type = 'award'` minus `SUM(points) WHERE phone = ? AND type = 'redeem'`, handling the empty-ledger case as 0.
4. Cancelling an order writes a compensating row (`type = 'award_rollback'`) and the balance reflects the rollback.
5. The confirmation page component renders `LoyaltyBalance` and `LoyaltyBalance` calls `balance(phone)` with the order's phone number.

## Scope

**IN**

- New `points_ledger` table and migration
- New `src/db/pointsLedger.ts` with `award`, `balance`, and `rollback` functions
- New `src/components/LoyaltyBalance.tsx` component
- Modification of `src/api/orders.ts` to call `award` on placement and `rollback` on cancel
- Modification of `src/pages/OrderConfirmation.tsx` to mount `LoyaltyBalance`
- Update to `docs/PROJECT_MANIFEST.md` to add `points_ledger` to the Domain Model section

**OUT**

- Redemption flow (customer spending points) — future work package
- Historical backfill for orders placed before this feature ships — separate one-off script, not a feature
- Admin UI for viewing all customers' balances — a staff-facing dashboard story, out of scope
- Anti-abuse (points awarded for a cancelled-and-reordered flow) — acknowledged as a future concern in the ADR

## Dependencies

- None from prior work packages. This is an independent feature.
- Blocked on the Architect ADR (the `points_ledger` storage shape is an open question).

## Open Questions

1. **Where does the ledger live?** Options: new table, denormalized column, materialized view. This is the architectural decision the Architect will resolve in `docs/architecture/0001-loyalty-points-storage.md`.
2. **Retention policy?** Not addressed here; the ledger is append-only for the foreseeable future.

## References

- Manifest: `docs/PROJECT_MANIFEST.md`
- Tickets: `tickets.md` (there is no existing loyalty ticket; this work package was created from a bead initiated by the founder)
- Factory wiring: `docs/factory-wiring.md`
