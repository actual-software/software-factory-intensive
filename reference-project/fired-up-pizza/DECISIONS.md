# Decisions

Running log of changes to `CLAUDE.md` (and later, agent pack prompts) with the context that made each change necessary. Every entry names the bead that triggered the change, the rule added, and what happened on the next sling.

---

## 2026-04-07 · mc-a1b2c3 · Show Order Total in Cart (L1 calibration)

### Context

First L1 sling. `dev-agent` with baseline `CLAUDE.md` imported from `workflow-card.md`. The feature was FUP-3 scoped to just the running cart total line.

### What Happened

- **Sling 1:** Agent implemented the total but called `parseFloat` on the price field. Project convention is cents-as-integer internally, formatted as dollars at render time. Agent didn't know the convention.
- **Sling 2:** Fixed the cents issue but used inline styles on the total span. Project convention is Tailwind utility classes.
- **Sling 3:** Clean. `npm run lint && npm test && npm run build` all green. Committed.

### `CLAUDE.md` Changes

- Added to **Project Context → Conventions**: *"Prices are stored and manipulated as integer cents. Format to dollars only at render, using `formatCents(n: number): string` from `src/utils/format.ts`. Never call `parseFloat` on a price field."*
- Added to **Quality Gates**: *"No inline styles. All styling goes through Tailwind utility classes. If a utility doesn't exist, extend `tailwind.config.ts` — do not inline."*

### Lessons

- `CLAUDE.md` is treated as law, but only for rules written as imperatives. "Prefer X" is routinely ignored. "NEVER X. Use Y instead." is followed.
- The existence of `formatCents` was obvious to me but invisible to the agent. When a convention relies on a helper, the helper's path must be named.
- Re-slinging after `git reset --hard` is cheap — three slings from scratch was faster than a single session of ad-hoc corrections would have been.

---

## 2026-04-08 · mc-d4e5f6 · Add loyalty indicator to MenuCard (scoped out)

### Context

Second L1 sling. Attempt to add a small "Earn 2x points" badge to featured menu cards. Feature proved too ambiguous for a calibration-grade sling; retired.

### What Happened

- **Sling 1:** Agent invented a new `FeaturedBadge.tsx` component inside `src/components/` and modified `MenuCard.tsx` to import it. No ticket mentioned "featured." The agent filled in ambiguity on its own.
- Decision: kill the bead rather than tighten the CLAUDE.md — the feature itself was under-specified.

### `CLAUDE.md` Changes

- Added to **Iteration Rule**: *"If the bead description is ambiguous about which files to touch, STOP and write a 3-line clarification question as a bead comment. Do not infer scope by adding new files."*

### Lessons

- Not every sling failure is a prompt failure. Sometimes the bead itself is wrong. This rule makes the agent surface the ambiguity instead of inventing around it.

---

## 2026-04-09 · mc-g7h8i9 · Order lookup by phone (FUP-5 prep)

### Context

Third L1 sling. Feature: a read-only query by phone number returning the customer's orders ordered by date.

### What Happened

- **Sling 1:** Agent wrote raw SQL with string interpolation (`\`SELECT * FROM orders WHERE phone = '${phone}'\``). This is a SQL injection risk; the project convention is parameterized queries via `better-sqlite3`'s `.prepare(...).all(...)` pattern.
- **Sling 2:** Clean. Used the existing `db.prepare` pattern from `src/db/orders.ts`.

### `CLAUDE.md` Changes

- Added to **Project Context → Security**: *"All SQL queries use `better-sqlite3`'s parameterized form: `db.prepare('SELECT ... WHERE phone = ?').all(phone)`. Never interpolate user input into a SQL string, even in helpers. If you need a dynamic column or table name, add it to an allow-list and look it up — never string-concat it."*

### Lessons

- Security rules can't be stated once and assumed absorbed. They need to name the *specific* idiom the project uses (`better-sqlite3`'s API form) and the *specific* anti-pattern (string interpolation).
- `CLAUDE.md` is a memory, not a filter. Every rule takes up agent attention budget — I trimmed two older rules that the agent had clearly internalized (no inline styles, no `any` types) into a terser "Style contract" section.

---

## 2026-04-10 · (L2 transition)

L1 complete. The dev-agent loop is reliable at ≤3 slings per feature. Next step is splitting `CLAUDE.md` into per-agent pack prompts (L2: planner + architect). This log continues to capture decisions about the *global* `CLAUDE.md`; per-agent prompt changes are captured in the corresponding pack's commit history.
