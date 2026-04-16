# Design Spec · Loyalty Points

**Work package:** [`work-packages/loyalty-points-system.md`](../work-packages/loyalty-points-system.md)
**ADR:** [`docs/adr/0001-loyalty-points-storage.md`](../docs/adr/0001-loyalty-points-storage.md)
**Designer run:** sling 2 (first rejected for missing edge cases — see `DECISIONS.md`)
**Generated:** 2026-04-11

---

## Purpose

Specify the data-layer module and UI component that together implement Story 1 and Story 2 of the loyalty points work package. The Coder agent consumes this spec directly; every bullet below must be implemented unchanged unless the Reviewer explicitly approves a deviation.

---

## Module 1 — `src/db/pointsLedger.ts`

### Location

`src/db/pointsLedger.ts` — mirrors the pattern of `src/db/orders.ts`. Same file layout (prepared statements at top, exported functions below).

### Exports

```ts
export type LedgerEntryType = 'award' | 'redeem' | 'award_rollback';

export interface LedgerEntry {
  id: number;
  phone: string;
  type: LedgerEntryType;
  points: number;
  orderId: number | null;
  createdAt: number;
  note: string | null;
}

export function award(phone: string, orderId: number, totalCents: number): number;
export function rollback(phone: string, orderId: number): void;
export function balance(phone: string): number;
```

### Behavior

- `award(phone, orderId, totalCents)` computes points as `Math.floor(totalCents / 100)`, inserts a row with `type = 'award'`, and returns the points awarded. If the `totalCents` yields 0 points, the function still inserts a row with `points = 0` so the audit trail remains complete.
- `rollback(phone, orderId)` finds the original `award` row for that `orderId` and inserts a compensating `award_rollback` row with the negated points value. Idempotent: calling it twice inserts only one rollback row. Throws if no original award is found.
- `balance(phone)` returns `SUM(points)` where `phone = ?`, summed across all `type` values. Rollbacks are negative, so the sum naturally produces the correct balance. Returns 0 for phones with no ledger entries.

### Prepared statements

Declare at module top-level:

```ts
const insertAward = db.prepare(`
  INSERT INTO points_ledger (phone, type, points, order_id, created_at)
  VALUES (?, 'award', ?, ?, strftime('%s', 'now'))
`);
// ... rollback and balance statements ...
```

### Edge cases

| Case | Expected behavior |
|------|-------------------|
| `totalCents` is 0 | Insert `award` row with `points = 0`. Return 0. Do not throw. |
| `totalCents` is negative | Throw `InvalidOrderTotalError`. Never happens in practice; signals a data corruption bug upstream. |
| `phone` is empty string | Throw `InvalidPhoneError`. |
| `rollback` called on an unknown `orderId` | Throw `NoAwardToRollbackError`. The API layer catches and ignores for idempotency. |
| `rollback` called twice for same `orderId` | Second call is a no-op. No second rollback row. |
| Concurrent `award` calls for the same phone | SQLite's single-writer model serializes. No extra locking needed. |

---

## Module 2 — `src/components/LoyaltyBalance.tsx`

### Location

`src/components/LoyaltyBalance.tsx` — new file, colocated test at `src/components/LoyaltyBalance.test.tsx`. Follows the same structure as `src/components/OrderStatusCard.tsx`.

### Props

```ts
export interface LoyaltyBalanceProps {
  phone: string;
}
```

### State

- `balance: number | null` — fetched from `/api/v1/loyalty/balance?phone=<phone>`. `null` while loading, a number after success, `null` again on error.
- `error: Error | null` — set on fetch failure. Non-blocking: the component returns `null` (renders nothing) on error, and logs via `console.error`.

### Layout

```tsx
<section
  aria-label="Loyalty balance"
  className="flex items-center gap-2 rounded-md border border-amber-200 bg-amber-50 px-3 py-2 text-sm"
>
  <StarIcon className="h-4 w-4 text-amber-500" />
  <span className="font-medium">{balance} points</span>
  <span className="text-amber-700">earned with Fired Up Pizza</span>
</section>
```

Match `src/components/OrderStatusCard.tsx`'s visual language — same `rounded-md`, same `px-3 py-2`, same icon-plus-text pattern. No inline styles. All colors via the Tailwind `amber` palette.

### Interactions

- On mount, fetch `/api/v1/loyalty/balance?phone=<phone>`.
- No user interaction. Component is read-only in this work package.
- Future redemption work package will add an "Apply discount" button; design is stable for that extension.

### Data Flow

```
<OrderConfirmation>
    └─ <LoyaltyBalance phone={order.phone} />
           └─ GET /api/v1/loyalty/balance?phone=...
                  └─ balance(phone) from src/db/pointsLedger.ts
```

### Edge cases

| Case | Expected behavior |
|------|-------------------|
| `phone` is empty | Component returns `null` immediately. Does not fetch. |
| Balance is 0 | Renders the section with "0 points earned." The copy does not say "no points" — it says "0 points." |
| Fetch fails (network, 500) | Logs to `console.error`. Renders `null`. Does not show a toast or modal. |
| Fetch takes >3s | Shows no skeleton. The absence of the component is preferable to a confusion-inducing skeleton; the confirmation page's core information is the order, not the balance. |

---

## API Integration

### New endpoint: `GET /api/v1/loyalty/balance`

**Location:** `src/api/loyalty.ts` (new file; register in `src/api/index.ts`).

**Request:** `GET /api/v1/loyalty/balance?phone=5551234567`

**Response:** `{ "phone": "5551234567", "balance": 42 }`

**Errors:** 400 if `phone` query param is missing or empty. 500 on any internal error (handled by existing `asyncHandler` wrapper).

### Modification to `POST /api/v1/orders`

After the `orders` row is inserted with status `'placed'`, call `award(phone, orderId, totalCents)`. Include the returned value in the response body as `points_earned`.

### Modification to the cancel path

Wherever the order transitions to `cancelled` (currently `PATCH /api/v1/orders/:id/status`), call `rollback(phone, orderId)` before responding. Swallow `NoAwardToRollbackError` — it's safe to cancel an order that somehow didn't earn points.

---

## Test Plan

Co-located tests the Coder must write:

- `src/db/pointsLedger.test.ts`:
  - award computes points from cents (three cases: 950¢→9, 1234¢→12, 99¢→0)
  - award with 0 cents writes a row and returns 0
  - rollback writes a compensating row and balance reflects the rollback
  - rollback is idempotent for the same order
  - balance on an empty ledger returns 0
- `src/components/LoyaltyBalance.test.tsx`:
  - renders "N points" after fetch resolves
  - renders nothing on fetch error
  - renders nothing when `phone` is empty
- `src/api/loyalty.test.ts`:
  - GET `/api/v1/loyalty/balance?phone=X` returns correct balance
  - GET without phone param returns 400

---

## References

- Work package: `work-packages/loyalty-points-system.md`
- ADR: `docs/adr/0001-loyalty-points-storage.md`
- Similar existing module: `src/db/orders.ts`
- Similar existing component: `src/components/OrderStatusCard.tsx`
- Project manifest: `docs/PROJECT_MANIFEST.md`
