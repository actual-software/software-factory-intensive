# Calculator Project Agent Rules

This is a minimal JavaScript calculator project. Treat it as a real project
with the rules below. The active factory workflow owns step routing and
artifact contracts.

## Tech stack

- JavaScript (CommonJS modules, `require`/`module.exports`)
- Node's built-in `node:test` for testing — run `node --test`
- No build tooling — source runs directly under Node
- Zero production dependencies; zero devDependencies

## Project structure

- `src/` — implementation files
- `test/` — test files (one per src file, named `<name>.test.js`, using `node:test`)
- `docs/plans/` — Planner output, one markdown file per feature
- `docs/architecture/` — Architect output, one markdown file per feature
- `docs/designs/` — Designer output, one design spec per feature
- `docs/reviews/` — Reviewer output, one review report per feature
- `docs/releases/` — Release-Gate output, one gate report per feature

## Conventions

- Export functions via `module.exports = { foo, bar }`
- Every new src file needs a matching test file with at least one happy-path test
- Prefer small pure functions over classes
- Builder should commit each feature on a `feature/<slug>` branch — never straight to main

## Workflow Expectations

The active formula creates and routes the step beads. Each agent should
work only the current routed formula step and close that step when its artifact
or implementation work is complete. Do not create the next stage's bead, relabel
work, or wake another agent; the formula graph owns the order.

| Stage        | Produces                                      | On finish                 |
|--------------|-----------------------------------------------|---------------------------|
| Planner      | `docs/plans/<slug>.md`                        | close current step        |
| Architect    | `docs/architecture/<slug>.md`                 | close current step        |
| Designer     | `docs/designs/<slug>.md`                      | close current step        |
| Builder      | code + tests on `feature/<slug>` branch       | close current step        |
| Reviewer     | `docs/reviews/<slug>.md`                      | close current step        |
| Release-Gate | `docs/releases/<slug>.md` with PASS/FAIL      | close current step        |

## Artifact content requirements

- **Planner** → Plan: sections `## Goal`, `## User Stories`,
  `## Acceptance Criteria`, and `## Scope Boundary`.
- **Architect** → Architecture: sections `## Context`,
  `## Options Considered` (2+ options), and `## Decision` with rationale.
- **Designer** → Design spec: sections covering interface, behavior/edge cases, and a test plan.
- **Reviewer** → Review report: each finding labelled with severity (Critical / High / Medium / Low), location, impact, and suggested fix.
- **Release-Gate** → Gate report: explicit `PASS` or `FAIL` verdict plus evidence per check.
