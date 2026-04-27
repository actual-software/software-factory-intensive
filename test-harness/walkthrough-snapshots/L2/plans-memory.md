# Calculator Memory Work Package

## Goal

Add memory operations to the calculator so users can store a numeric value,
recall it later, and clear the stored value. This mirrors the classic M+/MR/MC
behavior found on physical and software calculators.

## User Stories

1. **Store a value** -- As a user, I can store a number so that I can reuse it
   in a later calculation without retyping it.
2. **Recall a value** -- As a user, I can recall the stored number so that I
   can use it as an operand in a new calculation.
3. **Clear memory** -- As a user, I can clear the stored number so that memory
   returns to its default empty state.
4. **Default state** -- As a user, when no value has been stored (or memory has
   been cleared), recalling memory returns 0 so that calculations using recall
   do not fail.

## Acceptance Criteria

- `memoryStore(value)` saves the given number.
- `memoryRecall()` returns the most recently stored number.
- `memoryClear()` resets the stored value; a subsequent `memoryRecall()` returns 0.
- Calling `memoryRecall()` before any store returns 0.
- Memory persists across multiple store/recall cycles within the same module
  lifetime (no cross-process persistence required).
- Each function is exported from a module and has at least one passing test.
- Storing a non-number (e.g. `undefined`, `null`, a string) is outside scope
  for this iteration.

## Scope Boundary

**In scope:**
- Three pure-ish functions: `memoryStore`, `memoryRecall`, `memoryClear`.
- Module-level state to hold the stored value.
- Unit tests covering happy path, default-before-store, and clear-then-recall.

**Out of scope:**
- Multiple memory slots or named registers.
- Persistent storage (file, database, localStorage).
- Integration with a UI or REPL.
- Input validation or type coercion on the stored value.
- Memory add/subtract (M+, M-) operations -- those can be a follow-up feature.

## Dependencies

- No new production dependencies. The implementation uses only module-scoped
  state in JavaScript.
- Existing `src/calculator.js` and `test/calculator.test.js` are not modified;
  memory is a new module alongside the existing one.

## Open Questions

1. **Separate module vs. extend `calculator.js`?** -- The architect should
   decide whether memory lives in its own `src/memory.js` or is added to the
   existing `calculator.js`. A separate module keeps concerns isolated; a single
   module keeps the surface area small.
2. **Return value of `memoryStore`?** -- Should it return the stored value (for
   chaining) or `undefined`? The architect should decide based on API
   ergonomics.

## Architect Handoff

The architect should resolve:

1. **Module placement** -- New `src/memory.js` file vs. extending
   `src/calculator.js`. Consider testability, import ergonomics, and the
   project's one-file-per-concern convention.
2. **State encapsulation** -- Module-scoped `let` variable vs. a factory/closure
   pattern. The factory approach supports multiple independent memory instances
   in tests but adds complexity to a minimal project.
3. **`memoryStore` return value** -- Return the stored value, return `void`, or
   return the previous value. Pick the convention that best fits the existing
   API style (current functions return computed results).
