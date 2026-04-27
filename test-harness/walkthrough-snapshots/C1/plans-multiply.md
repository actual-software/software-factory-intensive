# Multiply Operation Work Package

## Goal

Add a `multiply(a, b)` function to the calculator module that returns the
product of two numbers, following the same conventions as the existing `add` and
`subtract` operations.

## User Stories

- As a caller of the calculator module, I can call `multiply(a, b)` and receive
  `a * b` so that the module covers basic arithmetic multiplication.

## Acceptance Criteria

- `multiply` is exported from `src/calculator.js` via `module.exports`.
- `multiply(a, b)` returns the numeric product `a * b`.
- At least one happy-path test exists in `test/calculator.test.js` (e.g.,
  `multiply(3, 4)` returns `12`).
- All existing tests continue to pass (`node --test`).
- The change ships on a `feature/multiply` branch, not directly on main.

## Scope Boundary

**In scope:**

- Adding the `multiply` function to `src/calculator.js`.
- Adding test coverage in `test/calculator.test.js`.
- Exporting the new function alongside `add` and `subtract`.

**Out of scope:**

- Division or other new operations.
- Input validation, type coercion, or error handling beyond what `add`/`subtract`
  already do (they accept raw JS number arguments with no guards).
- Refactoring existing code.
- CI/CD or packaging changes.

## Dependencies

- None. The existing `src/calculator.js` and `test/calculator.test.js` are the
  only files that need changes.

## Open Questions

- None. The request is explicit and the existing codebase conventions are clear.

## Handoff

Decisions for the architect and designer to resolve:

1. **Placement**: confirm that `multiply` belongs in the existing
   `src/calculator.js` file rather than a new module (the scope boundary assumes
   it does, consistent with `add`/`subtract`).
2. **Edge-case behavior**: decide whether to specify behavior for non-numeric
   inputs (current functions do not guard against this; designer should document
   whether to match that pattern or tighten it).
3. **Test breadth**: designer should specify whether edge-case tests
   (zero, negatives, floating-point) are required or if one happy-path test
   suffices to match the existing test style.
