# Negate Operation Work Package

## Goal

Add a `negate(x)` function to the calculator that returns `-x`. This gives
callers a single call to flip the sign of a numeric value (e.g., `negate(5)`
returns `-5`, `negate(-3)` returns `3`).

## User Stories

1. As a caller, I can negate a number with `negate(x)` so I don't have to
   inline the unary minus.
2. As a caller, I receive a numeric result that preserves floating-point
   precision (e.g., `negate(3.14)` returns `-3.14`).

## Acceptance Criteria

- `negate(x)` is exported from `src/calculator.js`.
- `negate(5)` returns `-5`.
- `negate(-3)` returns `3`.
- `negate(0)` returns `-0` (or `0`; architect should confirm).
- `negate(3.14)` returns `-3.14`.
- A matching test file covers at least the cases above.
- `node --test` passes with zero failures.

## Scope Boundary

- **In scope:** one pure function, its export, and its tests.
- **Out of scope:** CLI/REPL integration, input validation beyond what the
  formula implies, new modules or files beyond the existing
  `src/calculator.js` + `test/calculator.test.js` pair.

## Dependencies

- None. The function is self-contained and has no external dependencies.
- Follows the existing CommonJS export pattern in `src/calculator.js`.

## Open Questions

- Should `negate(0)` return `0` or `-0`? JavaScript's unary minus gives `-0`,
  which is `=== 0` but distinguishable via `Object.is`. The existing functions
  do not special-case zero. Architect should confirm.
- Should `negate` coerce or reject non-numeric inputs? The existing `add`,
  `subtract`, and `percent` do no validation, so the assumption is to follow
  suit. Architect should confirm.

## Handoff

- **Architect:** Confirm that adding `negate` directly to `calculator.js` (vs.
  a new module) is the right call given the project's "small pure functions"
  convention. Decide on zero semantics (`0` vs `-0`) and input-validation
  stance.
- **Designer:** Specify exact edge-case behavior (NaN, Infinity, `-0`) and
  finalize the test plan.
