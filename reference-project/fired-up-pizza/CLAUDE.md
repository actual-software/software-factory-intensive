# Fired Up Pizza — Agent Instructions

This is a pizza restaurant web application built by a 6-agent software factory.

## Project Context

- **Manifest**: `docs/PROJECT_MANIFEST.md` — tech stack, conventions, domain model, review standards, release criteria, success metrics

Read the manifest before starting any work. It is the single source of truth for all project decisions.

## Pipeline

Features flow through six stages. Each agent reads its inputs from the repo and writes its outputs as committed files:

1. **Planner** → `docs/plans/<slug>.md`
2. **Architect** → `docs/architecture/NNNN-<slug>.md`
3. **Designer** → `docs/designs/<slug>-spec.md`
4. **Coder** → `src/` implementation
5. **Reviewer** → `docs/reviews/<slug>-review.md`
6. **Deployer** → `docs/releases/<slug>-gate.md`

## Rules

- Change agent behavior via config files (this file, prompts, manifest) — never via ad-hoc re-prompting
- All work on feature branches, never directly on main
- Follow conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Prices in cents internally, formatted as dollars for display
- TypeScript strict mode, Tailwind CSS, no inline styles
