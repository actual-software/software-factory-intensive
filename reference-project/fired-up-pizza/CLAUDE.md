# Fired Up Pizza — Agent Instructions

This is a pizza restaurant web application built by a 6-agent software factory.

## Project Context

- **Manifest**: `docs/PROJECT_MANIFEST.md` — tech stack, conventions, domain model
- **Review Policy**: `docs/REVIEW_POLICY.md` — code review standards
- **Release Criteria**: `docs/RELEASE_CRITERIA.md` — deployment gate requirements
- **Tickets**: `tickets.md` — initial feature backlog

## Pipeline

Features flow through six stages. Each agent reads its inputs from the repo and writes its outputs as committed files:

1. **Planner** → `work-packages/<slug>.md`
2. **Architect** → `docs/adr/NNNN-<slug>.md`
3. **Designer** → `design/<slug>-spec.md`
4. **Coder** → `src/` implementation
5. **Reviewer** → `review-reports/<slug>-review.md`
6. **Deployer** → `release-gates/<slug>-gate.md`

## Rules

- Change agent behavior via config files (this file, prompts, manifests) — never via ad-hoc re-prompting
- All work on feature branches, never directly on main
- Follow conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Prices in cents internally, formatted as dollars for display
- TypeScript strict mode, Tailwind CSS, no inline styles
