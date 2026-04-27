# Multiply Operation Design

## Interface

Add one exported function to `src/calculator.js`:

```js
function multiply(a, b) {
  return a * b;
}
```

Export it alongside the existing functions:

```js
module.exports = { add, subtract, multiply };
```

The function signature follows the same `(a, b) -> number` convention as `add`
and `subtract`. Both parameters are raw JS numbers with no type guards.

## Behavior

- `multiply(a, b)` returns the numeric product `a * b` using the `*` operator.
- No input validation, type coercion, or error handling. This matches the
  existing `add` and `subtract` functions, which accept any JS value and rely on
  the operator's default coercion.
- The function is pure: no side effects, no state, no external dependencies.

## Edge Cases

Per the architecture decision, no guards are added. The `*` operator's standard
IEEE 754 behavior applies:

| Input                     | Result       | Notes                              |
|---------------------------|--------------|------------------------------------|
| `multiply(3, 4)`         | `12`         | Happy path.                        |
| `multiply(0, 5)`         | `0`          | Zero identity.                     |
| `multiply(-2, 3)`        | `-6`         | Negative operand.                  |
| `multiply(0.1, 0.2)`     | `0.020...04` | Floating-point precision artifact. |
| `multiply(Infinity, 2)`  | `Infinity`   | IEEE 754 propagation.              |
| `multiply(Infinity, 0)`  | `NaN`        | IEEE 754 indeterminate form.       |
| `multiply("3", 4)`       | `12`         | JS implicit coercion (not guarded).|
| `multiply(undefined, 1)` | `NaN`        | JS implicit coercion (not guarded).|

None of these require special handling. The builder should not add guards or
special-case logic for any of them.

## Test Plan

Add one test to `test/calculator.test.js`, matching the existing style:

```js
test('multiply returns the product of two numbers', () => {
  assert.equal(multiply(3, 4), 12);
});
```

The test must:

1. Import `multiply` from `../src/calculator` alongside `add` and `subtract`.
2. Use `assert.equal` with a simple integer pair.
3. Pass when run via `node --test`.

Edge-case tests (zero, negatives, floats) are permitted but not required per the
architecture decision. All existing tests must continue to pass unchanged.

## Build Notes

The builder should inspect and modify exactly two files:

| File                        | Change                                              |
|-----------------------------|-----------------------------------------------------|
| `src/calculator.js`        | Add `multiply` function; add it to `module.exports`.|
| `test/calculator.test.js`  | Import `multiply`; add one happy-path test.         |

No new files, no new dependencies, no build configuration changes.

Commit the change on a `feature/multiply` branch per project conventions.

## References

- Plan: `docs/plans/multiply.md`
- Architecture: `docs/architecture/multiply.md`
- Source: `src/calculator.js`
- Tests: `test/calculator.test.js`
- Project conventions: `CLAUDE.md`
