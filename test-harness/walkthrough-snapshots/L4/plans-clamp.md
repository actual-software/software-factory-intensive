# Clamp Operation Work Package

## Goal

Add a `clamp(x, lo, hi)` function to the calculator project that returns `x`
bounded to the interval `[lo, hi]`. This gives users a standard numeric
clamping primitive alongside the existing arithmetic operations.

## User Stories

- As a caller, I want `clamp(x, lo, hi)` to return `lo` when `x < lo`, `hi`
  when `x > hi`, and `x` otherwise, so that I can constrain a value to a range
  in a single call.
- As a caller, I want `clamp(5, 5, 10)` to return `5` (boundary-inclusive), so
  that edge values are not unexpectedly shifted.

## Acceptance Criteria

1. `clamp(x, lo, hi)` is exported from `src/calculator.js`.
2. Returns `lo` when `x < lo`.
3. Returns `hi` when `x > hi`.
4. Returns `x` when `lo <= x <= hi`.
5. When `lo === hi`, returns that value regardless of `x`.
6. `test/calculator.test.js` includes tests covering: value below range, value
   above range, value within range, value equal to `lo`, value equal to `hi`,
   and `lo === hi`.
7. `npm test` passes with zero failures.

## Scope Boundary

- **In scope**: the `clamp` function, its export, and its tests.
- **Out of scope**: input validation (e.g., `lo > hi`), type coercion, new
  source files, changes to existing `add`/`subtract` functions, CLI or UI
  integration.

## Dependencies

- None. The function is self-contained and has no external dependencies.
  Existing `src/calculator.js` and `test/calculator.test.js` are the only files
  that need changes.

## Open Questions

1. **Behavior when `lo > hi`**: The request does not specify. This plan assumes
   no validation — the architect and designer should decide whether to throw,
   swap, or leave the result undefined for inverted bounds.

## Handoff

The architect should resolve:
- Whether `clamp` belongs in `calculator.js` or warrants a new module (project
  convention favors keeping it in `calculator.js` given its size).
- The `lo > hi` edge-case policy (throw vs. swap vs. undefined behavior).

The designer should resolve:
- Exact function signature and parameter naming.
- Full edge-case matrix and test plan (especially around `NaN`, `Infinity`,
  and non-numeric inputs if the architect decides to handle them).
