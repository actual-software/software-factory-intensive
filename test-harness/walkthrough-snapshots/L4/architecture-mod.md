# Modulo Operation Architecture

## Context

The calculator project exports `add`, `subtract`, and `clamp` from a single
module (`src/calculator.js`) with tests in `test/calculator.test.js`. The
request is to add a `mod(a, b)` function that returns the remainder of `a`
divided by `b`.

Two questions were escalated from the plan:

1. **Module placement** — does `mod` belong in `calculator.js` or a new file?
2. **Remainder semantics** — should `mod` use JS-native `%` (which preserves
   the dividend's sign) or implement a mathematical/Euclidean modulo (always
   non-negative)?

A secondary question was raised about error handling for `b === 0`.

## Options Considered

### Module placement

| Option | Description | Tradeoffs |
|--------|-------------|-----------|
| **A. Add to `calculator.js`** | Export `mod` alongside existing functions. | (+) Follows the established one-module convention. (+) No new files or import changes. (-) Module grows by one function, though still small. |
| **B. New `src/mod.js` module** | Separate file with its own test file. | (+) Single-responsibility per file. (-) Breaks the pattern for a one-line function. (-) Adds coordination cost with no proportional benefit at current scale. |

### Remainder semantics

| Option | Description | Tradeoffs |
|--------|-------------|-----------|
| **A. JS-native `%` operator** | `mod(a, b)` returns `a % b` directly. | (+) Matches the request wording (`a%b`). (+) Zero surprise for JS developers. (+) One-line implementation. (-) Returns negative remainders for negative dividends (`mod(-7, 3)` → `-1`). |
| **B. Euclidean modulo** | `((a % b) + b) % b`, always non-negative. | (+) Mathematically conventional. (+) Avoids negative remainders that surprise non-JS users. (-) Diverges from the explicit request. (-) Adds a formula the designer must document and the reviewer must verify. |

### Division-by-zero policy

| Option | Description | Tradeoffs |
|--------|-------------|-----------|
| **A. Return `NaN` (native behavior)** | Let `a % 0` evaluate to `NaN` per JS semantics. | (+) Consistent with how `add` and `subtract` handle bad inputs — no defensive checks. (+) Zero extra logic. (-) Caller gets `NaN` silently. |
| **B. Throw an error** | Guard `b === 0` and throw `RangeError` or `Error`. | (+) Fail-fast on misuse. (-) No precedent in this project for throwing. (-) Adds validation the plan scoped out. |

## Decision

1. **Module placement — Option A**: add `mod` to `src/calculator.js`. The
   project currently has three functions in one file; adding a fourth keeps the
   convention intact. A module split is warranted when the file outgrows a
   handful of pure functions, not before.

2. **Remainder semantics — Option A**: use JS-native `%`. The request
   explicitly says `a%b`, and the plan assumes JS semantics. Euclidean modulo
   is a different operation that could be added later under a separate name
   (e.g., `euclideanMod`) if needed.

3. **Division-by-zero — Option A**: return `NaN`. The project has no precedent
   for defensive input checks in its arithmetic functions, and the plan
   explicitly assumes `NaN` is acceptable. This keeps `mod` consistent with the
   existing contract where callers provide valid arguments.

## Consequences

- `src/calculator.js` exports `{ add, subtract, clamp, mod }`.
- `test/calculator.test.js` gains tests covering: happy path (`mod(10, 3)` →
  `1`), exact division (`mod(10, 5)` → `0`), negative dividend (`mod(-7, 3)` →
  `-1`), and division by zero (`mod(a, 0)` → `NaN`).
- No new files, no dependency changes, no build-tool changes.
- The designer specifies exact parameter names, JSDoc shape, and the full
  edge-case test matrix; the architect's constraints are: function lives in
  `calculator.js`, uses native `%`, and does not validate inputs.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Negative remainder surprises non-JS consumers | Low | Low | Document JS `%` semantics in JSDoc and test file. |
| `calculator.js` grows unwieldy over time | Low | Low | Revisit module split if the file exceeds ~10 exported functions. |
| Caller misuses `mod(a, 0)` and propagates `NaN` | Low | Medium | Document the `b === 0` behavior; leave stricter handling for a future requirement. |

## References

- Plan artifact: `docs/plans/mod.md`
- Existing architecture precedent: `docs/architecture/clamp.md`
- Project conventions: `CLAUDE.md`
- Existing source: `src/calculator.js`, `test/calculator.test.js`
