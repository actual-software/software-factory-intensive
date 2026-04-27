# Percent Operation Work Package

## Goal

Add a `percent(whole, fraction)` function to the calculator that returns
`whole * fraction / 100`. This gives users a single call to compute a
percentage of a value (e.g., `percent(200, 15)` → `30`).

## User Stories

1. As a caller, I can compute a percentage of a number with
   `percent(whole, fraction)` so I don't have to inline the arithmetic.
2. As a caller, I receive a numeric result (not rounded/truncated) so
   fractional percentages are preserved (e.g., `percent(200, 33)` → `66`).

## Acceptance Criteria

- `percent(whole, fraction)` is exported from `src/calculator.js`.
- `percent(200, 15)` returns `30`.
- `percent(0, 50)` returns `0`.
- `percent(200, 0)` returns `0`.
- `percent(200, 100)` returns `200`.
- `percent(200, 33.33)` returns `66.66`.
- A matching test file covers at least the cases above.
- `node --test` passes with zero failures.

## Scope Boundary

- **In scope:** one pure function, its export, and its tests.
- **Out of scope:** CLI/REPL integration, input validation beyond what the
  formula implies, rounding modes, new modules or files beyond the existing
  `src/calculator.js` + `test/calculator.test.js` pair.

## Dependencies

- None. The function is self-contained and has no external dependencies.
- Follows the existing CommonJS export pattern in `src/calculator.js`.

## Open Questions

- Should `percent` coerce or reject non-numeric inputs? The existing `add` and
  `subtract` do no validation, so the assumption is to follow suit. Architect
  should confirm.

## Handoff

- **Architect:** Confirm that adding `percent` directly to `calculator.js` (vs.
  a new module) is the right call given the project's "small pure functions"
  convention. Decide on input-validation stance.
- **Designer:** Specify exact edge-case behavior (negative inputs, NaN, Infinity)
  and finalize the test plan.
