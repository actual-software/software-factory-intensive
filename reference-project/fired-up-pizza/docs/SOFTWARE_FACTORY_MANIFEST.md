# Software Factory Manifest: Fired Up Pizza

## Factory Overview

Fired Up Pizza. This factory runs a 6-agent sequential pipeline (Planner → Architect → Designer → Coder → Reviewer → Deployer) with two human gates. Tech stack: React 18 + TypeScript + Vite frontend, Tailwind CSS styling, React hooks + Context state, React Router v6, Node.js + Express REST backend, SQLite via `better-sqlite3`, Vitest + React Testing Library, ESLint + Prettier. The factory produces a single-machine web app — no cloud, no payment processor, no external auth — with the goal of replacing the restaurant's phone-only ordering workflow.

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

- **Gate 1 — After Architect:** Human approves the ADR before the Designer runs. Use this gate to confirm the architectural direction (e.g., how status transitions are implemented, how pricing recomputation is layered) before downstream design and code commit to it.
- **Gate 2 — After Reviewer:** Human approves the review report before the Deployer runs. Use this gate to confirm no `High` severity findings remain and that any deferred `Medium` findings are explicitly accepted.

## Per-Agent System Prompt Seeds

**Planner:** "You are the Planner for Fired Up Pizza. You decompose feature requests into work packages — touching MenuItem, Order, OrderItem, and Topping entities — using the Domain Model and Tech Stack sections of PROJECT_MANIFEST.md."

**Architect:** "You are the Architect for Fired Up Pizza. You write architectural decision records covering Order status flow, OrderItem pricing recomputation, and SQLite access patterns, using the Tech Stack and Constraints sections of PROJECT_MANIFEST.md."

**Designer:** "You are the Designer for Fired Up Pizza. You write UX specs and interaction designs for customer-facing Order placement/tracking and staff-facing Order queue management, using the Domain Model (MenuItem, Order, OrderItem, Topping) and Conventions sections of PROJECT_MANIFEST.md."

**Coder:** "You are the Coder for Fired Up Pizza. You implement features against React 18 + TypeScript + Vite (frontend) and Express + better-sqlite3 (backend), persisting MenuItem, Order, and OrderItem records, following the Conventions and Task Inputs sections of PROJECT_MANIFEST.md."

**Reviewer:** "You are the Reviewer for Fired Up Pizza. You enforce the Review Standards in PROJECT_MANIFEST.md against every code diff — including the linear Order status flow, recompute-from-menu pricing rule, cents-internal/dollars-display convention, and TypeScript strict mode."

**Deployer:** "You are the Deployer for Fired Up Pizza. You gate releases against the Release Criteria in PROJECT_MANIFEST.md — `npm install && npm run dev` boots, Vitest passes, `tsc --noEmit` passes, ESLint clean, no `High` Reviewer findings — before any feature touching Order or MenuItem ships."

## Quality Gates

Per-stage pass criteria drawn from Review Standards and Release Criteria in PROJECT_MANIFEST.md:

- **Stage 1 (Planner) passes when:** the work package names the affected Domain Model entities (MenuItem / Order / OrderItem / Topping), references the relevant Constraints (no payments, no external auth, single-machine), and lists which Per-Feature Success Criteria the work targets.

- **Stage 2 (Architect) passes when:** the ADR commits to a Tech Stack-compliant approach (React 18 + TS, Express, SQLite via `better-sqlite3`), preserves the linear status flow (`placed → preparing → ready → delivered`, plus `cancelled`), and respects all Constraints (no real-time infra, no external services, polling acceptable). Human gate 1 approves before Designer runs.

- **Stage 3 (Designer) passes when:** the spec covers both customer-facing and staff-facing flows, references Domain Model entities by name with their fields, and respects Conventions (kebab-case files, PascalCase components, `/api/v1/<resource>` routes, prices in cents).

- **Stage 4 (Coder) passes when:** code is on a feature branch `fired-up-pizza-<feature>`, all commits are conventional-commit format, every shipped behavior maps to a bullet in the Designer spec, pricing recomputes from MenuItem + Topping at display time (no `unit_price` cached on OrderItem), TypeScript strict passes, no inline `style={}` attributes, all SQL is parameterized, and phone numbers are normalized + validated.

- **Stage 5 (Reviewer) passes when:** the review report exists at `review-reports/fired-up-pizza-review.md`, every finding is graded Low / Medium / High with the documented severity scale, no `High` findings remain unresolved, and Spec Compliance / Style / Security checks are explicitly recorded. Human gate 2 approves before Deployer runs.

- **Stage 6 (Deployer) passes when:** all Required Release Criteria pass — Vitest green, `tsc --noEmit` clean, ESLint clean, `npm install && npm run dev` boots successfully, Reviewer report has zero `High` findings, every commit on the merged branch is conventional-commit, and the Designer spec is committed to `docs/designs/`. Informational metrics (coverage delta, bundle size delta, deferred Low/Medium count) are recorded but non-blocking.

## Orchestrator Configuration

- Coordination pattern: sequential pipeline with handoffs
- Failure handling: stop pipeline at failing agent, surface error to human
- Retry policy: no automatic retries (human decides whether to re-run)
- Branch strategy: feature branch per work item (`fired-up-pizza-<feature>`), merge after Deployer gate passes

## Conventions Reference

- File naming: kebab-case for non-component files (`order-service.ts`); PascalCase for React components (`OrderCard.tsx`)
- Test files: co-located, suffix `.test.ts` / `.test.tsx`
- API routes: `/api/v1/<resource>` (e.g. `/api/v1/orders`, `/api/v1/menu-items`)
- Commits: conventional commits — `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- Branches: `<slug>-<feature>` per work item; never commit directly to `main`
- Pricing: store and compute in **cents** internally; format as dollars only at display boundaries
- TypeScript: strict mode required (no `any` without justification)
- Styling: Tailwind utility classes only — no inline `style={}` attributes
