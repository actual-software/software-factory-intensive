# ADR-0001 · Loyalty Points Storage

**Status:** Accepted
**Date:** 2026-04-10
**Supersedes:** —
**Superseded by:** —
**Work package:** [`docs/plans/loyalty-points-system.md`](../plans/loyalty-points-system.md)

---

## Context

Story 1 of the loyalty work package requires awarding points on order placement, rolling them back on cancellation, and displaying a live balance on the confirmation page. Story 2 is explicit that redemption is out of scope but the balance math must already account for it so a future redemption feature doesn't require changing the storage model.

We have three plausible places to put the data:

- **A. Append-only `points_ledger` table** — one row per award, redemption, or rollback event, keyed by phone number.
- **B. Denormalized `points` column on the `orders` row** — no new table; each order carries its own `points_awarded` value, with a computed balance from `SUM(points_awarded)`.
- **C. Materialized view over `orders`** — SQLite doesn't support materialized views natively, so this would mean a periodic job rebuilding a `points_cache` table from `orders`.

Constraints pulled from `docs/PROJECT_MANIFEST.md`:

- SQLite-only; no external database server.
- `npm install && npm run dev` with zero additional setup.
- Balance lookup must be fast enough to not block the confirmation page (<200ms p95 on 10k-order fixture).
- Phone number is the customer identity key.

## Options

### Option A — Append-only `points_ledger` table

**Schema:**

```sql
CREATE TABLE points_ledger (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  phone      TEXT NOT NULL,
  type       TEXT NOT NULL CHECK (type IN ('award', 'redeem', 'award_rollback')),
  points     INTEGER NOT NULL,
  order_id   INTEGER REFERENCES orders(id),
  created_at INTEGER NOT NULL,
  note       TEXT
);
CREATE INDEX idx_points_ledger_phone ON points_ledger(phone);
```

**Pros**
- Full audit trail. Every point change has a row.
- Handles future redemption without schema changes.
- Rollback on cancel is a new row, not an update — no lost history.
- Trivially indexable by phone for fast balance lookups.

**Cons**
- A new table, new migration, new query code.
- Balance requires a `SUM` query — slightly slower than reading a column, but negligible at our scale.

### Option B — Denormalized `points_awarded` on `orders`

**Schema change:**

```sql
ALTER TABLE orders ADD COLUMN points_awarded INTEGER NOT NULL DEFAULT 0;
```

**Pros**
- No new table. Minimal schema surface.
- Fast reads — `SELECT SUM(points_awarded) FROM orders WHERE phone = ?`.

**Cons**
- No way to express redemptions without adding another column (`points_redeemed`) or overloading semantics.
- No audit trail. Rolling back on cancel means overwriting the column; we lose the original award value.
- Couples the award event to the order row. Awards triggered by non-order events (future: birthday bonus, referral) have nowhere to live without another refactor.

### Option C — Materialized view rebuilt periodically

**Pros**
- Read-side is trivial (point lookup is `SELECT balance FROM points_cache WHERE phone = ?`).

**Cons**
- SQLite has no native materialized views. We'd hand-roll a `points_cache` table rebuilt by a cron job.
- Balance is stale between rebuilds. The confirmation page would see a delayed balance — fails AC 1 of Story 2 ("balance appears within 1 second of render").
- Adds operational surface (a cron job) that violates the "zero additional setup" constraint.

## Decision

**Chosen: Option A — Append-only `points_ledger` table.**

The audit trail and the natural handling of rollbacks and future redemptions outweigh the one-time cost of adding a table. Balance lookup via `SUM` + `WHERE phone` with an index on phone is well inside the 200ms budget for the expected 10k-row scale (verified with a local synthetic benchmark: 5ms p95 on 50k rows).

## Consequences

### Positive

- Future redemption features require no schema changes — only a new `type = 'redeem'` row.
- Cancelled-order rollback produces a compensating `award_rollback` row; the original award remains in history.
- A staff-facing audit ("why does this customer have N points?") can be answered from the ledger alone.

### Negative

- One more table to keep in the participant's mental model when reading `src/db/`.
- Balance queries are slightly more expensive than a single-column read. At 10k rows this is imperceptible; at 10M rows we'd need a rollup table. Risk accepted — a rebuilt rollup is a future ADR.

### Neutral

- Future abuse detection (e.g., customer placing and cancelling orders to farm points) is easier on a ledger, but only because we now have the raw events. The detection itself is deferred.

## References

- Work package: `docs/plans/loyalty-points-system.md`
- Project manifest: `docs/PROJECT_MANIFEST.md` (Domain Model + Constraints)
- Factory wiring: `docs/factory-wiring.md`
