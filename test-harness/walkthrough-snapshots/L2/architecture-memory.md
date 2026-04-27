# Calculator Memory Architecture

## Context

The calculator project needs memory operations (store, recall, clear) matching
classic M+/MR/MC behavior. The planner artifact defines three functions —
`memoryStore`, `memoryRecall`, `memoryClear` — with module-lifetime persistence
and a default recall value of 0.

The existing codebase is a single `src/calculator.js` exporting pure functions
(`add`, `subtract`) with a matching test file. There are no classes, no shared
state, and no build tooling. The project follows a one-file-per-concern
convention with CommonJS modules.

The architect must resolve three open questions from the planner: module
placement, state encapsulation strategy, and the return value of `memoryStore`.

## Options Considered

### 1. Module Placement

**Option A — New `src/memory.js` file (recommended)**

- Keeps memory state isolated from the pure arithmetic functions.
- Follows the project's one-file-per-concern convention.
- Produces a clean `test/memory.test.js` that does not need to reset calculator
  state between runs.
- Tradeoff: consumers needing both arithmetic and memory must import two modules.

**Option B — Extend `src/calculator.js`**

- Single import point for all calculator functionality.
- Tradeoff: introduces mutable module state into a currently pure module, making
  `calculator.js` harder to reason about. Violates the existing separation where
  each file owns one concern. Test isolation becomes more fragile because
  arithmetic tests now share a module with stateful memory.

### 2. State Encapsulation

**Option A — Module-scoped `let` variable (recommended)**

- A single `let _stored = 0;` at the top of `memory.js`, read and written by
  the three exported functions.
- Matches the project's style: plain functions, no classes, minimal abstraction.
- Tradeoff: only one memory instance per process. Tests that need isolation must
  call `memoryClear()` in a setup hook.

**Option B — Factory/closure pattern**

- `createMemory()` returns `{ store, recall, clear }` with private state
  captured in a closure.
- Supports multiple independent memory instances, which simplifies parallel test
  isolation.
- Tradeoff: adds a layer of indirection that nothing else in the project uses.
  Over-engineers a module that the planner scoped to a single memory slot with
  no concurrency requirement.

### 3. `memoryStore` Return Value

**Option A — Return the stored value (recommended)**

- `memoryStore(42)` returns `42`.
- Consistent with the existing API style where functions return a useful numeric
  result (`add` returns the sum, `subtract` returns the difference).
- Enables chaining or inline use: `const x = memoryStore(result)`.
- Tradeoff: callers who ignore the return value pay no cost; callers who want it
  get it for free.

**Option B — Return `undefined` (void)**

- Signals that store is a side-effect-only operation.
- Tradeoff: breaks the project's convention that exported functions return a
  number. Forces callers who want the value to call `memoryRecall()` immediately
  after storing, which is redundant.

## Decision

1. **New module**: create `src/memory.js` with a matching `test/memory.test.js`.
2. **Module-scoped state**: use a plain `let _stored = 0;` variable. No factory,
   no class.
3. **Return stored value**: `memoryStore(value)` returns `value` so the API
   stays consistent with the existing numeric-return convention.

Rationale: every choice picks the simpler option that fits the project's
existing patterns. The project is minimal and has no concurrency, multi-tenant,
or persistence requirements — complexity is not justified.

## Consequences

- `src/memory.js` exports `{ memoryStore, memoryRecall, memoryClear }`.
- `memoryRecall()` returns `0` before any store or after a clear.
- `memoryStore(n)` saves `n` and returns `n`.
- `memoryClear()` resets `_stored` to `0` (return value: `void` or `0` at the
  builder's discretion, since no caller depends on it).
- Tests in `test/memory.test.js` must call `memoryClear()` before or after each
  test to avoid cross-test leakage.
- Arithmetic tests in `test/calculator.test.js` are unaffected.

## Risks

- **Test ordering sensitivity**: because state is module-scoped, tests that
  forget to clear memory may pass individually but fail when run together.
  Mitigation: each test calls `memoryClear()` in a `beforeEach` or at the start
  of the test body.
- **Future multi-slot needs**: if a later feature requires named memory
  registers (M1, M2, …), the module-scoped variable will need to become an
  object or map. This is a known limitation accepted for this iteration, and the
  refactor is small.

## References

- Planning artifact: `docs/plans/memory.md`
- Project rules: `CLAUDE.md` (tech stack, conventions, workflow expectations)
- Existing implementation: `src/calculator.js`, `test/calculator.test.js`
