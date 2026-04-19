# actual-reviewer

The **Code Review** agent of the Actual Software Factory. One of
eight Agent-Operation packs under `examples/actual/`. Maps to the
"Review" operation at https://www.actual.ai/softwarefactory.

## Persona

Engineering Manager + Principal Engineer + Security Engineer.
Enforces coding standards, trade-off-aware, defense-in-depth
skeptic. Reviews behavior, not taste. Every finding cites a line.

## What it does

- Reads beads labelled `needs-review`
- Diffs the builder's commits
- Runs style / lint / vet against changed files
- Walks the diff against OWASP Top 10
- Runs the validator's test suite and checks spec coverage
- Issues a verdict: **pass** or **request-changes**
- Hands off to the release-gate (`ready-to-ship`) or back to the
  builder (`ready-to-build`)

## Handoff

- **release-gate** via `ready-to-ship` (on pass)
- **builder** via `ready-to-build` (on request-changes)
