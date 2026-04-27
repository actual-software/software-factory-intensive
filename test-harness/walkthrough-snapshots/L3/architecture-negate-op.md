# Negate Operation Architecture

## Context

The feature request asks for a `negate(x)` function that returns `-x`. The
project is a minimal CommonJS calculator with three existing pure functions
(`add`, `subtract`, `percent`) in a single module (`src/calculator.js`) and a
single test file (`test/calculator.test.js`). There are no external
dependencies.

The planner raised three open questions for the architect:

1. Should `negate` live in the existing `calculator.js` or in a new module?
2. Should `negate(0)` return `0` or `-0`?
3. Should `negate` validate its inputs, given that the existing functions do not?

## Options Considered

### Option A: Add `negate` to existing `src/calculator.js`

Add the function alongside `add`, `subtract`, and `percent` in the same file
and export it from the existing `module.exports` object. Tests go in the
existing test file.

| Dimension        | Assessment |
|------------------|------------|
| Consistency      | Matches the established one-module, one-test-file pattern exactly. |
| Discoverability  | All operations remain in one place; a single import gets everything. |
| Change size      | Minimal — a few lines of source and test additions. |
| Scalability      | Four functions in one file is still small; not a concern at this scale. |

### Option B: Create a new `src/negate.js` module

Place the function in its own file with a dedicated `test/negate.test.js`.

| Dimension        | Assessment |
|------------------|------------|
| Isolation        | Each operation lives in its own module — clean separation. |
| Consistency      | Breaks the established pattern; the other three functions share one file while `negate` lives alone. |
| Change size      | Larger — new files, new test file, potential re-export to keep imports ergonomic. |
| Scalability      | Better long-term if operations multiply, but premature for a four-function project. |

### Zero Semantics: Option Z1 — Allow `-0` (use plain unary minus)

Implement as `return -x`. When `x` is `0`, JavaScript produces `-0`. This is
`=== 0` and prints as `"0"` in most contexts, but is distinguishable via
`Object.is(result, -0)`. The existing functions do not special-case any values,
so this follows the same passthrough convention.

### Zero Semantics: Option Z2 — Normalize to `0`

Implement as `return -x || 0` or use a conditional to map `-0` to `0`. This
avoids the `-0` edge case but adds a special case not present in any other
calculator function, creating inconsistent behavior expectations.

### Input Validation: Option V1 — No validation (follow convention)

Existing functions pass inputs straight through with no type checks. `negate`
does the same. Non-numeric inputs produce `NaN` via normal JavaScript
arithmetic, which is predictable and consistent.

### Input Validation: Option V2 — Add validation to `negate`

Throw or return a sentinel for non-numeric inputs. This is safer in isolation
but inconsistent with `add`, `subtract`, and `percent`, creating a split
contract across the module.

## Decision

**Option A + Z1 + V1.** Add `negate` directly to `src/calculator.js` using
plain unary minus (`return -x`) with no input validation.

Rationale:

- The project convention is "small pure functions" in a shared module. One
  unary function does not justify a new file.
- `CLAUDE.md` states "every new src file needs a matching test file"; avoiding a
  new source file avoids unnecessary scaffolding.
- Allowing `-0` is the natural JavaScript behavior. The existing functions do
  not normalize edge-case numeric values, and `-0 === 0` means callers using
  strict equality are unaffected. Tests should accept either `0` or `-0`.
- The scope boundary in the plan excludes validation beyond what the formula
  implies, and the existing functions set the precedent of no validation.

## Consequences

- `src/calculator.js` gains one export (`negate`); `module.exports` grows from
  three entries to four.
- `test/calculator.test.js` gains test cases covering the acceptance criteria
  from the plan.
- No new files are created. No dependency changes.
- Tests for `negate(0)` should use `=== 0` (which passes for both `0` and `-0`)
  rather than `Object.is`, keeping the assertion style consistent with existing
  tests.

## Risks

- **Module growth:** If many more operations are added, `calculator.js` may
  become unwieldy. Mitigation: revisit file-per-operation structure when the
  module exceeds roughly ten functions.
- **`-0` surprise:** A caller using `Object.is` or serializing to JSON with a
  sign-aware formatter could see `-0`. Mitigation: this matches standard
  JavaScript unary-minus behavior and is consistent with the no-special-casing
  convention. Document if it becomes a support issue.
- **Silent NaN propagation:** Non-numeric inputs produce `NaN` silently.
  Mitigation: this matches existing behavior; callers already accept this
  contract.

## References

- Plan artifact: `docs/plans/negate-op.md`
- Source: `src/calculator.js`
- Tests: `test/calculator.test.js`
- Project rules: `CLAUDE.md`
- Prior architecture decision: `docs/architecture/percent-op.md`
