# Clamp Operation Architecture

## Context

The calculator project exposes `add` and `subtract` from a single module
(`src/calculator.js`) with matching tests in `test/calculator.test.js`. The
request is to add a `clamp(x, lo, hi)` function that returns `x` bounded to
`[lo, hi]`.

Two architectural questions were escalated from the plan:

1. **Module placement** — does `clamp` belong in the existing `calculator.js`
   or in a new file?
2. **Inverted-bounds policy** — what happens when `lo > hi`?

## Options Considered

### Module placement

| Option | Description | Tradeoffs |
|--------|-------------|-----------|
| **A. Add to `calculator.js`** | Export `clamp` alongside `add` and `subtract`. | (+) Follows existing one-module convention. (+) No new files, no import changes. (-) The module grows, though still small. |
| **B. New `src/clamp.js` module** | Separate file with its own test file. | (+) Single-responsibility per file. (-) Breaks the established pattern for a three-line function. (-) Adds coordination cost for builder and reviewer with no proportional benefit. |

### Inverted-bounds (`lo > hi`) policy

| Option | Description | Tradeoffs |
|--------|-------------|-----------|
| **A. Undefined behavior (no guard)** | If `lo > hi`, the result depends on evaluation order of the comparisons. The function does not validate. | (+) Simplest implementation — zero extra logic. (+) Matches scope boundary ("no input validation"). (-) Caller gets a silent wrong answer on misuse. |
| **B. Throw a `RangeError`** | Validate `lo <= hi` and throw otherwise. | (+) Fail-fast; caller knows immediately. (-) Adds validation logic the plan explicitly scoped out. (-) Changes the function from pure-arithmetic to defensive. |
| **C. Auto-swap bounds** | If `lo > hi`, treat them as `(hi, lo)`. | (+) Always returns a sensible value. (-) Masks a caller bug. (-) Adds a branch and test burden. |

## Decision

1. **Module placement — Option A**: add `clamp` to `src/calculator.js`. The
   project has two functions in one file today; adding a third keeps the
   convention intact. A new module is warranted when the file outgrows a
   handful of pure functions, not before.

2. **Inverted-bounds — Option A**: no guard. The plan scopes out input
   validation, and the project has no precedent for defensive checks in `add`
   or `subtract`. Keeping `clamp` consistent with the existing contract
   (caller provides valid arguments) is the right default. If a future
   requirement demands stricter handling, it can be added as a separate
   concern without changing the happy-path signature.

## Consequences

- `src/calculator.js` exports `{ add, subtract, clamp }`.
- `test/calculator.test.js` gains tests for the six acceptance-criteria
  scenarios (below range, above range, in range, equal to `lo`, equal to `hi`,
  `lo === hi`).
- No new files, no dependency changes, no build-tool changes.
- The designer is free to specify exact parameter names and an edge-case
  matrix; the architect's only constraint is that the function lives in
  `calculator.js` and does not validate bounds.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Silent wrong result on inverted bounds | Low | Medium | Document the precondition in the design spec; add a note in the test file. |
| `calculator.js` grows unwieldy over time | Low | Low | Revisit module split if the file exceeds ~10 exported functions. |

## References

- Plan artifact: `docs/plans/clamp.md`
- Project conventions: `CLAUDE.md` (module placement, export style, test naming)
- Existing source: `src/calculator.js`, `test/calculator.test.js`
