# Modulo Operation Work Package

## Goal

Add a `mod(a, b)` function to the calculator library that returns the remainder of `a` divided by `b` using JavaScript's `%` operator.

## User Stories

- As a library consumer, I want to call `mod(a, b)` and receive `a % b` so I can perform remainder calculations without importing another utility.
- As a library consumer, I want `mod` to handle edge cases (division by zero, negative operands) predictably so my code does not silently produce wrong results.

## Acceptance Criteria

1. `mod(a, b)` is exported from `src/calculator.js` alongside existing functions.
2. `mod(10, 3)` returns `1`.
3. `mod(10, 5)` returns `0`.
4. `mod(-7, 3)` returns the JS-native result (`-1`), matching `%` semantics.
5. `mod(a, 0)` returns `NaN` (native JS behavior for `x % 0`).
6. At least one happy-path test and edge-case tests exist in `test/calculator.test.js`.
7. The function has a JSDoc comment per project review standards.

## Scope Boundary

- **In scope**: the `mod` function, its export, and its tests.
- **Out of scope**: mathematical modulo (always-positive remainder), floored division, input type coercion or validation beyond what `%` provides natively, changes to existing functions.

## Dependencies

- None. `mod` is a standalone pure function with no new runtime or dev dependencies.

## Open Questions

1. Should `mod` follow JS `%` semantics exactly (which returns a negative remainder for negative dividends), or implement a mathematical/Euclidean modulo that always returns a non-negative result? This plan assumes JS-native `%` per the request wording `a%b`.
2. Should the function throw on `b === 0` instead of returning `NaN`? The existing library does not throw for invalid inputs (`add` accepts anything), so this plan assumes `NaN` is acceptable.

## Handoff

- **Architect**: Decide whether `mod` lives in `calculator.js` (consistent with current single-file layout) or warrants a new module. Confirm JS `%` semantics vs. Euclidean modulo.
- **Designer**: Specify exact error-handling behavior for `b === 0` and non-numeric inputs. Define the full test matrix including negative operands, zero dividend, and floating-point operands.
