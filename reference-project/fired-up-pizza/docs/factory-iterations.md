# Factory Iterations · Fired Up Pizza

Running log of every config-level change made to the Fired Up Pizza factory
since L2. Each row names *which agent* the edit affected, *what file* changed,
*the change in one sentence*, and *the criterion* (or expected criterion) it
was meant to move. New entries go at the bottom.

This log is the seed for [`improvement-criteria.md`](./improvement-criteria.md)
— recurring entries on the same stage signal that an automated rule or a
manifest-section tightening is overdue.

---

| Date       | Stage     | File                                                                        | Change                                                                                                              | Expected criterion impact |
|------------|-----------|------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|---------------------------|
| 2026-03-29 | Planner   | `packs/actual/planner/prompts/planner.md.tmpl`                              | Added requirement to cite at least one entity from `PROJECT_MANIFEST.md → Domain Model` in every work package        | Criterion 5 (manifest-citation rate up) |
| 2026-03-30 | Architect | `packs/actual/architect/prompts/architect.md.tmpl`                          | Wired `actual adr-bot` under `## Inputs you consume`; required ADR seed before drafting decision                     | Fewer Architect re-drafts on stale or duplicate ADRs |
| 2026-04-02 | Designer  | `packs/actual/designer/prompts/designer.md.tmpl`                            | Added `## Inputs you consume` reference to the design system MCP; required component-name citation in every spec     | Fewer Reviewer findings on "invented component names" |
| 2026-04-04 | Coder     | `packs/actual/builder/prompts/builder.md.tmpl`                              | Required Postgres staging MCP introspection before writing any query; banned guessing column names                   | Fewer "schema mismatch" review findings |
| 2026-04-07 | Reviewer  | `docs/PROJECT_MANIFEST.md → Review Standards`                               | Added "no `any` types at module boundaries" rule; severity = Medium                                                  | Surface boundary-type drift earlier |
| 2026-04-09 | Deployer  | `docs/PROJECT_MANIFEST.md → Release Criteria`                               | Added row 7 — "Branch merges cleanly into `main` (`git merge --no-commit` dry run)"                                | Catch merge conflicts pre-deploy instead of at PR time |
| 2026-04-10 | Reviewer  | `packs/actual/reviewer/prompts/reviewer.md.tmpl`                            | Constrained to "MUST NOT invent rules outside Review Standards"; severity must come from the manifest's scale        | Eliminate ad-hoc severities; verdicts become reproducible |
| 2026-04-12 | Coder     | `packs/actual/builder/prompts/builder.md.tmpl`                              | Final-step hard gate: `npm run lint && npm run type-check` must exit 0 before flipping bead to `needs-review`         | **Loop 1** — Criterion 3 (lint regressions to zero) |
| 2026-04-14 | Reviewer  | `packs/actual/reviewer/prompts/reviewer.md.tmpl`                            | Added per-AC test mapping requirement: every acceptance criterion in the work package must be matched to a test       | Criterion 4 (AC-test coverage at first review) |
| 2026-04-15 | (channel) | `packs/actual/improver/formulas/orders/improver-cooldown/order.toml`        | Cooldown shortened from `24h` to `6h` so feedback signals surface within one working day                              | Faster loop iteration on improvement criteria |
| 2026-04-18 | Planner   | *(planned, not yet applied)* `packs/actual/planner/prompts/planner.md.tmpl` | **Loop 2 lever** — require an explicit "Happy path narrative" subsection in every work package (3–5 concrete actions) | Criterion 1 (review loop-backs ≤1 of 5) |

---

## Patterns surfaced from this log

- **Reviewer is the most-edited stage** (5 edits). The bottleneck is the
  manifest's Review Standards section catching up to the team's tacit rules,
  not the Reviewer prompt itself. Most recent two edits were manifest-side.
- **Coder edits cluster on hard gates** (3 edits). Lint, type-check, and
  schema introspection were all originally guidelines and had to become
  blocking. Pattern: anything the Reviewer flags repeatedly gets promoted
  to a Coder pre-flight gate.
- **Channel-level change** (improver cooldown) had outsized effect — feedback
  rules now surface same-day. Worth checking whether the supervisor / nudge
  cadences need a similar tightening.
