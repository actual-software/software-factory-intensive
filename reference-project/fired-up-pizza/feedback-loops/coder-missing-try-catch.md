# Feedback Loop · Coder Missing `try`/`catch` on Async Handlers

**Category:** Reactive
**Created:** 2026-04-12
**Last triggered:** 2026-04-16 (Order History feature)

---

## Signal

Source: `review-reports/*.md`
Pattern: Any High-severity finding whose title contains the substring `uncaught async` OR `unhandled promise rejection`.

## Trigger

One occurrence in a single Reviewer run. Reactive loops are cheap — catching it on the first signal prevents the Coder from repeating the mistake on the next feature.

## Target

`packs/coder/prompts/coder.md` — Error Handling section.

## Action

Append the following to the Coder's Error Handling rules:

```markdown
Every `async` function that is exported or registered as a handler
(Express route, React event handler, React Query mutation fn) must
wrap its body in `try`/`catch`. The `catch` block must either:
  (a) re-throw as a typed error with the same name + a `cause` field, or
  (b) log with `console.error` and return a typed failure response.

Never let an async function leak an unhandled rejection. The Reviewer
will flag any `async` handler without an explicit `catch` as High
severity.
```

Then re-sling the Coder against the same bead. The Reviewer is expected to re-run after the Coder commits; verify the finding is gone before closing the feedback loop.

## Verification

- `grep -c "try \{" src/api/orders.ts` increased by at least 1 after re-sling
- `review-reports/<slug>-review.md` no longer contains the High-severity finding
- `git log --oneline packs/coder/prompts/coder.md` shows the rule was added in a commit referencing this feedback loop

## History

| Run | Feature | Found by | Resolved by | Time cost |
|-----|---------|----------|-------------|-----------|
| 2026-04-12 | Loyalty Points | Reviewer (sling 2) | Coder prompt edit + re-sling | ~8 min |
| 2026-04-14 | Menu Category CRUD | Reviewer (sling 1) | Rule caught it up front | 0 min — the prompt was already loaded |
| 2026-04-16 | Order History | Reviewer (sling 1) | Rule caught it up front | 0 min |
