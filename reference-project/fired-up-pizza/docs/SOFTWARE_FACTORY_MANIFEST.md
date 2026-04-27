# Software Factory Manifest: Fired Up Pizza

## Factory Overview

Fired Up Pizza. This factory runs a 6-agent sequential pipeline (Planner → Architect → Designer → Coder → Reviewer → Deployer) with two human gates. Tech stack: React 18 + TypeScript + Vite on the frontend, Tailwind for styling, Node.js + Express REST API on the backend, SQLite via `better-sqlite3` for storage, Vitest + React Testing Library for tests. Deployment target is a single back-office laptop — no cloud infra, no external services.

## Pipeline Sequence

1. **Planner**
   - Reads: feature request + PROJECT_MANIFEST.md
   - Writes: `work-packages/fired-up-pizza.md`

2. **Architect**
   - Reads: Planner work package + Tech Stack section of PROJECT_MANIFEST.md
   - Writes: `docs/adr/NNNN-fired-up-pizza.md`

3. **Designer**
   - Reads: Architect ADR + Domain Model section of PROJECT_MANIFEST.md
   - Writes: `design/fired-up-pizza-spec.md`

4. **Coder**
   - Reads: Designer spec + Conventions section of PROJECT_MANIFEST.md
   - Writes: `src/` on feature branch `fired-up-pizza-<feature>`

5. **Reviewer**
   - Reads: code diff + Review Standards section of PROJECT_MANIFEST.md
   - Writes: `review-reports/fired-up-pizza-review.md`

6. **Deployer**
   - Reads: Reviewer report + Release Criteria section of PROJECT_MANIFEST.md
   - Writes: `release-gates/fired-up-pizza-gate.md`

## Human Gates

- **Gate 1 — After Architect:** Human approves the ADR before Designer runs. Intent: confirm the chosen approach (data model changes, endpoint shape, status-transition rules) before a spec is written against it.
- **Gate 2 — After Reviewer:** Human approves the review report before Deployer runs. Intent: triage Medium findings and confirm no High findings before the release gate runs.

## Per-Agent System Prompt Seeds

**Planner:** "You are the Planner for Fired Up Pizza. You decompose feature requests into work packages using the Domain Model (MenuItem, Order, OrderItem) and Tech Stack in PROJECT_MANIFEST.md."

**Architect:** "You are the Architect for Fired Up Pizza. You write architectural decision records using the Tech Stack and Constraints in PROJECT_MANIFEST.md, honoring the single-laptop, no-cloud, polling-only deployment target when weighing options for Order and MenuItem flows."

**Designer:** "You are the Designer for Fired Up Pizza. You write UX specs and interaction designs using the Domain Model (MenuItem, Order, OrderItem, status transitions `placed → preparing → ready → delivered`) and Conventions in PROJECT_MANIFEST.md."

**Coder:** "You are the Coder for Fired Up Pizza. You implement features for MenuItem, Order, and OrderItem following the Conventions and Task Inputs in PROJECT_MANIFEST.md, using React 18 + Vite on the client and Express + `better-sqlite3` on the server."

**Reviewer:** "You are the Reviewer for Fired Up Pizza. You enforce the Review Standards in PROJECT_MANIFEST.md against every code diff — especially prepared-statement usage on Order/MenuItem queries, input validation on Express routes, and the fixed Order status transition order."

**Deployer:** "You are the Deployer for Fired Up Pizza. You gate releases against the Release Criteria in PROJECT_MANIFEST.md — confirming `npm install && npm run dev` works on a clean checkout, tests pass, no High findings remain, any SQLite migration affecting Order / MenuItem / OrderItem runs idempotently, and a manual smoke test of placing and advancing an Order succeeds."

## Quality Gates

- **Stage 1 (Planner) passes when:** the work package names the affected domain entities (MenuItem, Order, OrderItem), lists acceptance criteria tied to Per-Feature Success in the manifest, and identifies in-scope vs. out-of-scope items against the Constraints section.
- **Stage 2 (Architect) passes when:** the ADR picks one approach, lists tradeoffs, respects the no-cloud/polling/SQLite constraints, and flags any schema or API-contract changes explicitly. **Human Gate 1.**
- **Stage 3 (Designer) passes when:** every UI flow, API contract, and status transition the Coder will implement is specified; ambiguity is resolved or explicitly deferred.
- **Stage 4 (Coder) passes when:** implementation matches the spec, TypeScript strict passes, ESLint/Prettier clean, no `any` without justification, SQL via prepared statements only, input validation on every Express route, co-located `*.test.ts` tests added for new logic.
- **Stage 5 (Reviewer) passes when:** the review report enumerates findings by severity (Low/Medium/High), cites spec and manifest sections, and records zero **High** findings. **Human Gate 2.**
- **Stage 6 (Deployer) passes when:** all six Release Criteria PASS — tests green, branch rebased clean, `npm run dev` boots cleanly, no outstanding High findings, manual smoke test of the customer-place-order + staff-advance-status flow succeeds, and any SQLite migration is idempotent.

## Orchestrator Configuration

- **Coordination pattern:** sequential pipeline with handoffs — each agent's Writes become the next agent's Reads.
- **Failure handling:** stop pipeline at the failing agent, surface the error (and any partial output) to the human operator.
- **Retry policy:** no automatic retries. Human decides whether to re-run the failing agent, edit inputs, or abort.
- **Branch strategy:** feature branch per work item, named `fired-up-pizza-<feature>`. Merge to `main` via squash after the Deployer gate passes.

## Conventions Reference

- **File naming:** kebab-case for files (`order-queue.tsx`), PascalCase for React components, camelCase for functions/variables.
- **Test files:** co-located `*.test.ts` / `*.test.tsx` next to source.
- **API routes:** REST under `/api/v1/*`. Resources plural: `/api/v1/orders`, `/api/v1/menu-items`. Use HTTP verbs (GET/POST/PATCH/DELETE).
- **Commits:** Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`, `test:`, `docs:`).
- **Branches:** `feature/<slug>`, `fix/<slug>`, `chore/<slug>`. Merge to `main` via squash.
