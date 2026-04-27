# Negate Operation Design

## Interface

Add one exported function to `src/calculator.js`:

```js
function negate(x) {
  return -x;
}

module.exports = { add, subtract, percent, negate };
```

- **Name:** `negate`
- **Parameters:** `x` (number)
- **Returns:** `number` — the result of `-x`
- **Validation:** None. Follows the existing convention — non-numeric inputs
  produce `NaN` via standard JavaScript arithmetic coercion.

## Behavior

| Input          | Output   | Notes                            |
|----------------|----------|----------------------------------|
| `negate(5)`    | `-5`     | Positive to negative             |
| `negate(-3)`   | `3`      | Negative to positive             |
| `negate(0)`    | `-0`     | Unary minus on zero (=== 0)      |
| `negate(3.14)` | `-3.14`  | Floating-point precision kept    |
| `negate(1)`    | `-1`     | Unit value                       |

The function is a single unary-minus expression with no branching, rounding, or
special-casing. It delegates entirely to JavaScript's unary `-` operator.

Per the architecture decision (Option Z1), `negate(0)` returns `-0`. This is
`=== 0` in JavaScript and prints as `"0"` in most contexts. Tests should use
`=== 0` rather than `Object.is` to stay consistent with the existing assertion
style.

## Edge Cases

Per the architecture decision (Option V1 — no validation), `negate` does not
guard against unusual inputs. The behavior below follows naturally from the
expression `-x`:

| Input                    | Output       | Reason                          |
|--------------------------|--------------|---------------------------------|
| `negate(0)`              | `-0`         | IEEE 754 signed zero            |
| `negate(-0)`             | `0`          | Double negation of signed zero  |
| `negate(Infinity)`       | `-Infinity`  | IEEE 754 arithmetic             |
| `negate(-Infinity)`      | `Infinity`   | IEEE 754 arithmetic             |
| `negate(NaN)`            | `NaN`        | NaN propagation                 |
| `negate("5")`            | `-5`         | String-to-number coercion by `-`|
| `negate(undefined)`      | `NaN`        | `-undefined` → `NaN`           |
| `negate()`               | `NaN`        | Missing arg is `undefined`      |
| `negate(null)`           | `-0`         | `-null` → `-0`                 |
| `negate(true)`           | `-1`         | Boolean coercion (`true` → 1)  |

None of these cases require special handling. The builder should not add
guards, type checks, or early returns.

## Test Plan

Add tests to `test/calculator.test.js`. Import `negate` alongside `add`,
`subtract`, and `percent` from `../src/calculator`. Each test uses
`assert.equal` following the existing pattern.

**Required tests (from acceptance criteria):**

1. `negate(5)` → `-5` — positive integer
2. `negate(-3)` → `3` — negative integer
3. `negate(0)` === `0` — zero (use `assert.equal` which treats `-0 === 0`)
4. `negate(3.14)` → `-3.14` — floating-point

**Additional edge-case tests:**

5. `negate(-3.14)` → `3.14` — negative float
6. `negate(1)` → `-1` — unit value

Use one `test()` call per assertion, matching the existing style of one
behavior per test. Test descriptions should follow the pattern
`'negate <description>'`.

Run with `node --test` and confirm zero failures.

## Build Notes

Files to modify:

- **`src/calculator.js`** — Add the `negate` function definition (one line:
  `return -x;`) and add `negate` to the `module.exports` object on line 13.
- **`test/calculator.test.js`** — Add `negate` to the destructured import on
  line 3. Add 6 new `test()` blocks after the existing `percent` tests.

No new files. No dependency changes. No `package.json` changes.

The builder should create a `feature/negate-op` branch before committing.

## References

- Plan: `docs/plans/negate-op.md`
- Architecture: `docs/architecture/negate-op.md`
- Source: `src/calculator.js`
- Tests: `test/calculator.test.js`
- Project rules: `CLAUDE.md`
