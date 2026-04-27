# Modulo Operation Design

## Interface

```js
function mod(a, b)
```

- **Parameters**: two numbers — `a` (dividend), `b` (divisor).
- **Returns**: the remainder of `a / b` using JavaScript's `%` operator. Result type is `number` (may be `NaN`).
- **Exported from**: `src/calculator.js` alongside `add`, `subtract`, and `clamp`.
- **JSDoc**: one-line description noting JS `%` semantics and `NaN` on zero divisor.

## Behavior

| Condition | Result |
|-----------|--------|
| `b !== 0` | `a % b` |
| `b === 0` | `NaN` |

The implementation is a single expression: `a % b`.

No type coercion, no defensive checks, no thrown errors — consistent with `add`, `subtract`, and `clamp`.

Sign of the result matches the sign of `a` (JavaScript `%` semantics):
- Positive dividend, positive divisor: positive or zero result.
- Negative dividend, positive divisor: negative or zero result.
- Positive dividend, negative divisor: positive or zero result.
- Negative dividend, negative divisor: negative or zero result.

## Edge Cases

| Case | Input | Expected | Notes |
|------|-------|----------|-------|
| Happy path | `mod(10, 3)` | `1` | Basic remainder |
| Exact division | `mod(10, 5)` | `0` | No remainder |
| Negative dividend | `mod(-7, 3)` | `-1` | Sign follows dividend |
| Negative divisor | `mod(7, -3)` | `1` | Sign follows dividend |
| Both negative | `mod(-7, -3)` | `-1` | Sign follows dividend |
| Zero dividend | `mod(0, 5)` | `0` | 0 % anything is 0 |
| Division by zero | `mod(10, 0)` | `NaN` | Native JS behavior |
| Floating point | `mod(5.5, 2)` | `1.5` | Works with non-integers |

## Test Plan

Add tests to `test/calculator.test.js`. Import `mod` alongside existing destructured imports. Each test is a single `assert.equal` or `assert.ok` call following the existing style.

| # | Test name | Call | Expected | Assert |
|---|-----------|------|----------|--------|
| 1 | `mod returns the remainder` | `mod(10, 3)` | `1` | `assert.equal` |
| 2 | `mod returns zero for exact division` | `mod(10, 5)` | `0` | `assert.equal` |
| 3 | `mod returns negative remainder for negative dividend` | `mod(-7, 3)` | `-1` | `assert.equal` |
| 4 | `mod returns NaN when divisor is zero` | `mod(10, 0)` | `NaN` | `assert.ok(Number.isNaN(...))` |

These four tests cover the acceptance criteria from the plan: happy path, exact division, negative dividend, and division by zero.

## Build Notes

Files to change:

1. **`src/calculator.js`** — Add the `mod` function after `clamp`. Add a JSDoc comment. Add `mod` to the `module.exports` object.
2. **`test/calculator.test.js`** — Add `mod` to the destructured require. Add the four test cases listed above, each as a top-level `test()` call matching the existing naming convention (`'mod ...'`).

No new files. No dependency changes. `npm test` (`node --test`) must pass with zero failures after the changes.

## References

- Plan: `docs/plans/mod.md`
- Architecture: `docs/architecture/mod.md`
- Source: `src/calculator.js`
- Tests: `test/calculator.test.js`
- Project conventions: `CLAUDE.md`
