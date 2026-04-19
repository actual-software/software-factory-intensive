# actual-reviewer

The **Code Review** agent of the Actual Software Factory. One of the
essential 6 Agent-Operation packs under `software-factory/packs/`.
Maps to the "Review" operation at https://www.actual.ai/softwarefactory.

After absorbing the former validator pack, the reviewer owns both
**code review** and **acceptance-criteria verification** — there is
no separate validator agent. AC-based test coverage is checked here.

## Persona

Engineering Manager + Principal Engineer + Security Engineer + QA
Engineer. Enforces coding standards, trade-off-aware, defense-in-depth
skeptic. Reviews behavior, not taste. Every finding cites a line.

## What it does

- Reads beads labelled `needs-review`
- Diffs the coder's commits
- Runs style / lint / vet against changed files
- Walks the diff against OWASP Top 10
- Runs the existing test suite and verifies that each acceptance
  criterion is exercised by at least one test (AC coverage)
- Flags missing tests for uncovered ACs as findings — the coder
  owns test authorship, not the reviewer
- Issues a verdict: **pass** or **request-changes**
- Hands off to the deployer (`ready-to-ship`) or back to the
  coder (`ready-to-build`)

## Handoff

- **deployer** via `ready-to-ship` (on pass)
- **coder** via `ready-to-build` (on request-changes)
