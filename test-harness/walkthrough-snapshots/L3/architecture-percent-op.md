# Percent Operation Architecture

## Context

The feature request asks for a `percent(whole, fraction)` function that returns
`whole * fraction / 100`. The project is a minimal CommonJS calculator with two
existing pure functions (`add`, `subtract`) in a single module
(`src/calculator.js`) and a single test file (`test/calculator.test.js`). There
are no external dependencies.

The planner raised two open questions for the architect:

1. Should `percent` live in the existing `calculator.js` or in a new module?
2. Should `percent` validate its inputs, given that the existing functions do not?

## Options Considered

### Option A: Add `percent` to existing `src/calculator.js`

Add the function alongside `add` and `subtract` in the same file and export it
from the existing `module.exports` object. Tests go in the existing test file.

| Dimension        | Assessment |
|------------------|------------|
| Consistency      | Matches the current one-module, one-test-file pattern exactly. |
| Discoverability  | All operations are in one place; a single import gets everything. |
| Change size      | Minimal — a few lines of source and test additions. |
| Scalability      | If the project grows to dozens of operations the file becomes large, but that is a future concern outside current scope. |

### Option B: Create a new `src/percent.js` module

Place the function in its own file with a dedicated `test/percent.test.js`.

| Dimension        | Assessment |
|------------------|------------|
| Isolation        | Each operation lives in its own module — clean separation. |
| Consistency      | Breaks the established pattern; `add` and `subtract` would still share one file while `percent` lives alone. |
| Change size      | Larger — new files, new test file, potential re-export or barrel file to keep imports ergonomic. |
| Scalability      | Better long-term if operations multiply, but premature for a three-function project. |

### Input Validation: Option V1 — No validation (follow convention)

Existing functions pass inputs straight through with no type checks. `percent`
does the same. Non-numeric inputs produce `NaN` via normal JavaScript
arithmetic, which is predictable and consistent.

### Input Validation: Option V2 — Add validation to `percent`

Throw or return a sentinel for non-numeric inputs. This is safer in isolation
but inconsistent with `add` and `subtract`, creating a split contract across the
module.

## Decision

**Option A + V1.** Add `percent` directly to `src/calculator.js` with no input
validation.

Rationale:

- The project's explicit convention is "small pure functions" in a shared
  module. One function does not justify a new file.
- `CLAUDE.md` states "every new src file needs a matching test file"; avoiding a
  new source file avoids unnecessary scaffolding.
- The scope boundary in the plan excludes validation beyond what the formula
  implies, and the existing functions set the precedent of no validation.
- Keeping the validation contract uniform avoids surprising callers who expect
  all calculator operations to behave the same way.

## Consequences

- `src/calculator.js` gains one export (`percent`); `module.exports` grows from
  two entries to three.
- `test/calculator.test.js` gains test cases covering the acceptance criteria
  from the plan.
- No new files are created. No dependency changes.
- If the project later adopts input validation, it should be applied uniformly
  across all operations in a dedicated effort — not introduced piecemeal.

## Risks

- **Module growth:** If many more operations are added, `calculator.js` may
  become unwieldy. Mitigation: revisit file-per-operation structure when the
  module exceeds roughly ten functions.
- **Silent NaN propagation:** Non-numeric inputs produce `NaN` silently.
  Mitigation: this matches existing behavior; callers already accept this
  contract. A future validation layer can be added uniformly.

## References

- Plan artifact: `docs/plans/percent-op.md`
- Source: `src/calculator.js`
- Tests: `test/calculator.test.js`
- Project rules: `CLAUDE.md`
