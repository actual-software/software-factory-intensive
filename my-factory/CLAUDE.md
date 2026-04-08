# [Your Project Name] — Agent Instructions

<!-- This file tells agents how to work on your project. -->
<!-- Fill it in during L1 (Build a Structured Development Loop). -->

## Project Context

- **Manifest**: `docs/PROJECT_MANIFEST.md` — read this first for all project decisions

## Pipeline

Features flow through six agents. Each reads its inputs from the repo and commits its outputs:

1. **Planner** → `work-packages/<slug>.md`
2. **Architect** → `docs/adr/NNNN-<slug>.md`
3. **Designer** → `design/<slug>-spec.md`
4. **Coder** → `src/` implementation
5. **Reviewer** → `review-reports/<slug>-review.md`
6. **Deployer** → `release-gates/<slug>-gate.md`

## Rules

- Change agent behavior via config (this file, prompts, manifest) — never via ad-hoc re-prompting
- All work on feature branches, never directly on main
