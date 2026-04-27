# Multiply Operation Architecture

## Context

The calculator module (`src/calculator.js`) currently exports two pure
functions—`add` and `subtract`—via CommonJS `module.exports`. The project
uses no build tooling, no input validation, and no external dependencies.

The request is to add `multiply(a, b)` returning `a * b`, matching the
conventions of the existing operations. The planner artifact identifies three
open decisions for the architect: placement, edge-case behavior, and test
breadth.

## Options Considered

### Option A — Extend the existing module

Add `multiply` directly to `src/calculator.js` alongside `add` and `subtract`,
and export it from the same `module.exports` object.

| Dimension       | Assessment                                                      |
|-----------------|-----------------------------------------------------------------|
| Consistency     | Matches the established one-module pattern exactly.             |
| Change surface  | One file touched for implementation, one for tests.             |
| Risk            | Near zero — pure function, no side effects, no new imports.     |
| Scalability     | Module grows linearly with operations; acceptable at this size. |

### Option B — Separate module per operation

Create `src/multiply.js` with its own export and a dedicated
`test/multiply.test.js`, then optionally re-export from a barrel module.

| Dimension       | Assessment                                                      |
|-----------------|-----------------------------------------------------------------|
| Consistency     | Breaks the existing single-file pattern; would orphan `add`     |
|                 | and `subtract` in the original file until they are migrated.    |
| Change surface  | Two new files plus an optional barrel — more churn.             |
| Risk            | Low inherent risk, but the refactoring is out of scope per the  |
|                 | plan and CLAUDE.md conventions.                                 |
| Scalability     | Better isolation per file, but premature for a three-function   |
|                 | module with no build step.                                      |

## Decision

**Option A — extend the existing module.**

Rationale:

1. The plan explicitly scopes changes to `src/calculator.js` and
   `test/calculator.test.js` only; Option B violates the scope boundary.
2. CLAUDE.md states "prefer small pure functions over classes" and
   "every new src file needs a matching test file." Adding multiply to the
   existing file avoids creating new files that would need their own tests.
3. The module currently has two functions. A third does not warrant splitting.

### Handoff decisions

The planner flagged three questions; the architecture resolves them:

| Question             | Decision                                                      |
|----------------------|---------------------------------------------------------------|
| Placement            | `src/calculator.js` — confirmed; no new module.               |
| Edge-case behavior   | Match the existing pattern: accept raw JS number arguments    |
|                      | with no guards. Adding validation would be inconsistent with  |
|                      | `add`/`subtract` and out of the plan's scope.                 |
| Test breadth         | One happy-path test is required to match the existing style.  |
|                      | Edge-case tests (zero, negatives, floats) are welcome but     |
|                      | not mandated by this architecture.                            |

## Consequences

- The designer and builder have a single-file, two-line implementation target
  with no ambiguity about placement or validation.
- No existing code needs to change beyond appending the new function and its
  export.
- All existing tests remain unaffected.
- Future operations (e.g., `divide`) should follow the same extend-in-place
  pattern until the module grows large enough to warrant splitting—a decision
  deferred to that future request.

## Risks

- **Low — JS numeric edge cases.** `multiply` inherits the standard IEEE 754
  behavior of the `*` operator (Infinity, NaN, -0). This is acceptable because
  `add` and `subtract` carry the same characteristic and no caller guards
  against it today.
- **Low — module size.** Three functions is well within a single-file comfort
  zone. No action needed now.

## References

- Plan artifact: `docs/plans/multiply.md`
- Source: `src/calculator.js`
- Tests: `test/calculator.test.js`
- Project conventions: `CLAUDE.md` (calculator project agent rules)
