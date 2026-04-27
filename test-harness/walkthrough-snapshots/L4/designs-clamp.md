# Clamp Operation Design

## Interface

```js
function clamp(x, lo, hi)
```

- **Parameters**: three numbers — `x` (value to clamp), `lo` (lower bound), `hi` (upper bound).
- **Returns**: a number in the range `[lo, hi]`.
- **Exported from**: `src/calculator.js` alongside `add` and `subtract`.
- **Precondition**: caller must ensure `lo <= hi`. Behavior is unspecified when `lo > hi` (per architecture decision — no input validation).

## Behavior

| Condition | Result |
|-----------|--------|
| `x < lo` | `lo` |
| `x > hi` | `hi` |
| `lo <= x <= hi` | `x` |
| `x === lo` | `lo` (boundary-inclusive) |
| `x === hi` | `hi` (boundary-inclusive) |
| `lo === hi` | `lo` (regardless of `x`) |

Implementation is a single expression: `Math.max(lo, Math.min(x, hi))`.

No type coercion, no defensive checks, no thrown errors — consistent with how `add` and `subtract` treat their arguments.

## Edge Cases

| Case | Input | Expected | Notes |
|------|-------|----------|-------|
| Below range | `clamp(-5, 0, 10)` | `0` | |
| Above range | `clamp(15, 0, 10)` | `10` | |
| Within range | `clamp(5, 0, 10)` | `5` | |
| Equal to lo | `clamp(0, 0, 10)` | `0` | Boundary-inclusive |
| Equal to hi | `clamp(10, 0, 10)` | `10` | Boundary-inclusive |
| lo === hi | `clamp(5, 7, 7)` | `7` | Degenerate range |
| Negative range | `clamp(-3, -10, -1)` | `-3` | Works with negatives |
| Inverted bounds | `clamp(5, 10, 0)` | Unspecified | Precondition violated; no guard |

## Test Plan

Add tests to `test/calculator.test.js`. Import `clamp` alongside existing destructured imports. Each test is a single `assert.equal` call following the existing style.

| # | Test name | Call | Expected |
|---|-----------|------|----------|
| 1 | `clamp returns lo when x is below range` | `clamp(-5, 0, 10)` | `0` |
| 2 | `clamp returns hi when x is above range` | `clamp(15, 0, 10)` | `10` |
| 3 | `clamp returns x when x is within range` | `clamp(5, 0, 10)` | `5` |
| 4 | `clamp returns lo when x equals lo` | `clamp(0, 0, 10)` | `0` |
| 5 | `clamp returns hi when x equals hi` | `clamp(10, 0, 10)` | `10` |
| 6 | `clamp returns the bound when lo equals hi` | `clamp(5, 7, 7)` | `7` |

These six tests cover every acceptance criterion from the plan.

## Build Notes

Files to change:

1. **`src/calculator.js`** — Add the `clamp` function after `subtract`. Add `clamp` to the `module.exports` object.
2. **`test/calculator.test.js`** — Add `clamp` to the destructured require. Add the six test cases listed above, each as a top-level `test()` call matching the existing naming convention (`'clamp ...'`).

No new files. No dependency changes. `npm test` (`node --test`) must pass with zero failures after the changes.

## References

- Plan: `docs/plans/clamp.md`
- Architecture: `docs/architecture/clamp.md`
- Source: `src/calculator.js`
- Tests: `test/calculator.test.js`
- Project conventions: `CLAUDE.md`
