# Percent Operation Design

## Interface

Add one exported function to `src/calculator.js`:

```js
function percent(whole, fraction) {
  return whole * fraction / 100;
}

module.exports = { add, subtract, percent };
```

- **Name:** `percent`
- **Parameters:** `whole` (number), `fraction` (number)
- **Returns:** `number` — the result of `whole * fraction / 100`
- **Validation:** None. Follows the existing convention — non-numeric inputs
  produce `NaN` via standard JavaScript arithmetic coercion.

## Behavior

| Input                      | Output   | Notes                              |
|----------------------------|----------|------------------------------------|
| `percent(200, 15)`         | `30`     | Basic percentage                   |
| `percent(0, 50)`           | `0`      | Zero whole                         |
| `percent(200, 0)`          | `0`      | Zero fraction                      |
| `percent(200, 100)`        | `200`    | 100% returns the whole             |
| `percent(200, 33.33)`      | `66.66`  | Fractional percentage preserved    |
| `percent(200, 50)`         | `100`    | Half                               |
| `percent(1, 1)`            | `0.01`   | Small values                       |

The function is a single arithmetic expression with no branching, rounding, or
clamping. It delegates entirely to JavaScript's `*` and `/` operators.

## Edge Cases

Per the architecture decision (Option V1 — no validation), `percent` does not
guard against unusual inputs. The behavior below follows naturally from the
formula `whole * fraction / 100`:

| Input                          | Output       | Reason                          |
|--------------------------------|--------------|---------------------------------|
| `percent(-200, 15)`           | `-30`        | Negative whole propagates sign  |
| `percent(200, -15)`           | `-30`        | Negative fraction propagates sign |
| `percent(-200, -15)`          | `30`         | Double negative yields positive |
| `percent(Infinity, 50)`       | `Infinity`   | IEEE 754 arithmetic             |
| `percent(200, Infinity)`      | `Infinity`   | IEEE 754 arithmetic             |
| `percent(NaN, 50)`            | `NaN`        | NaN propagation                 |
| `percent(200, NaN)`           | `NaN`        | NaN propagation                 |
| `percent("200", "15")`        | `30`         | String-to-number coercion by `*` |
| `percent(undefined, 15)`      | `NaN`        | `undefined * 15` → `NaN`       |
| `percent()`                   | `NaN`        | Missing args are `undefined`    |

None of these cases require special handling. The builder should not add
guards, type checks, or early returns.

## Test Plan

Add tests to `test/calculator.test.js`. Import `percent` alongside `add` and
`subtract` from `../src/calculator`. Each test uses `assert.equal` or
`assert.strictEqual` following the existing pattern.

**Required tests (from acceptance criteria):**

1. `percent(200, 15)` → `30`
2. `percent(0, 50)` → `0`
3. `percent(200, 0)` → `0`
4. `percent(200, 100)` → `200`
5. `percent(200, 33.33)` → `66.66`

**Additional edge-case tests:**

6. `percent(-200, 15)` → `-30` (negative whole)
7. `percent(200, -15)` → `-30` (negative fraction)

Use one `test()` call per assertion, matching the existing style of one
behavior per test. Test descriptions should follow the pattern
`'percent <description>'`.

Run with `node --test` and confirm zero failures.

## Build Notes

Files to modify:

- **`src/calculator.js`** — Add the `percent` function definition (one line)
  and add `percent` to the `module.exports` object.
- **`test/calculator.test.js`** — Add `percent` to the destructured import on
  line 3. Add 7 new `test()` blocks after the existing `subtract` test.

No new files. No dependency changes. No `package.json` changes.

The builder should create a `feature/percent-op` branch before committing.

## References

- Plan: `docs/plans/percent-op.md`
- Architecture: `docs/architecture/percent-op.md`
- Source: `src/calculator.js`
- Tests: `test/calculator.test.js`
- Project rules: `CLAUDE.md`
