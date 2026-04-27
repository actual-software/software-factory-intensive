# Undo/Redo History Work Package

## Goal

Add undo/redo capability to the calculator so users can step backward through
a history of computed results and step forward again after undoing. This gives
users a safety net when exploring multi-step calculations.

## User Stories

1. **Record a result** -- As a user, I can push a computed result onto the
   history so that it becomes available for undo later.
2. **Undo** -- As a user, I can undo the most recent result to return to the
   previous value, so that I can recover from a wrong calculation.
3. **Redo** -- As a user, after undoing, I can redo to restore the value I
   just undid, so that I can move forward again without recalculating.
4. **Redo invalidation** -- As a user, when I push a new result after undoing,
   the redo stack is cleared so that the history stays linear and predictable.
5. **Empty history** -- As a user, undoing when there is no prior history
   returns `null` (no value) so that the caller can detect the boundary.
6. **Empty redo** -- As a user, redoing when there is nothing to redo returns
   `null` so that the caller can detect the boundary.

## Acceptance Criteria

- `historyPush(value)` appends a number to the history and clears the redo
  stack. Returns the pushed value.
- `historyUndo()` removes the most recent entry from the history, moves it to
  the redo stack, and returns the new current value (the entry now on top of
  the history). Returns `null` when the history is empty.
- `historyRedo()` pops the most recent entry from the redo stack, pushes it
  back onto the history, and returns it. Returns `null` when the redo stack is
  empty.
- `historyClear()` resets both the history and redo stacks to empty.
- Pushing a new value after an undo discards the entire redo stack.
- Multiple sequential undos walk backward through the full history.
- Multiple sequential redos walk forward through the full redo stack.
- Each function is exported from a module and has at least one passing test
  using `node:test`.
- Tests use `describe` and `it` from `node:test` for grouping, `beforeEach`
  to call `historyClear()` before each test to avoid cross-test state leakage,
  and `assert.strictEqual` / `assert.equal` from `node:assert/strict` for
  assertions.
- Storing non-number values is outside scope for this iteration.

## Scope Boundary

**In scope:**

- Four exported functions: `historyPush`, `historyUndo`, `historyRedo`,
  `historyClear`.
- Module-level state for the history stack and the redo stack (arrays).
- Unit tests covering: push then undo, push-undo-redo round trip,
  redo-invalidation after a new push, multiple sequential undos, multiple
  sequential redos, undo on empty history, redo on empty redo stack, and
  clear.

**Out of scope:**

- Named snapshots, branching history, or tree-shaped undo.
- Persistence across process restarts.
- Integration with a UI or REPL.
- Recording the operation itself (operands + operator) -- only the result
  value is tracked.
- Input validation or type coercion on pushed values.
- Integration with the memory feature (M+/MR/MC).

## Dependencies

- No new production dependencies. Implementation uses only module-scoped
  arrays in JavaScript.
- Existing `src/calculator.js` and `test/calculator.test.js` are not modified;
  history is a new module alongside the existing ones.
- Does not depend on the memory feature; the two are independent modules.

## Open Questions

1. **Separate module vs. extend an existing file?** -- The architect should
   decide whether history lives in its own `src/history.js` or is folded into
   another module. A separate module matches the project's one-file-per-concern
   convention.
2. **Return value on boundary conditions** -- Should `historyUndo()` and
   `historyRedo()` return `null` or `undefined` when there is nothing to
   undo/redo? `null` is explicit; `undefined` is the JS default for "no value."
   The architect should pick one and document the convention.
3. **Max history depth** -- Should there be an upper bound on the history
   stack size? For this iteration the assumption is unbounded, but the
   architect should note whether a cap is warranted.

## Architect Handoff

The architect should resolve:

1. **Module placement** -- New `src/history.js` file vs. extending an existing
   module. Consider the one-file-per-concern convention and testability.
2. **State encapsulation** -- Module-scoped arrays (`let _history = []`,
   `let _redo = []`) vs. a factory/closure pattern. The factory supports
   independent instances in tests but adds complexity to a minimal project.
3. **Boundary return value** -- `null` vs. `undefined` for undo/redo when
   there is nothing to undo/redo. Pick the convention that signals "no value"
   most clearly to callers.
4. **`historyPush` return value** -- Return the pushed value (consistent with
   the existing API style where functions return a useful numeric result) or
   return `void`.
5. **Max depth** -- Unbounded history for this iteration, or introduce an
   optional cap. Note the tradeoff between simplicity and memory safety for
   long-running sessions.
