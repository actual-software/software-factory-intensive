# Project Manifest: Fired Up Pizza

## Overview

Fired Up Pizza is a web application for a small neighborhood pizza restaurant. Customers browse the menu, customize pizzas (size, crust, toppings), place an order against their phone number, and track it through `placed → preparing → ready → delivered`. Staff use the same application to manage menu items, watch the live order queue, and advance order status as pizzas move through the kitchen. The MVP replaces a phone-only workflow that loses orders and leaves customers in the dark, and is intentionally lean enough to run on a single machine via `npm install && npm run dev` — no cloud, no payment processor, no external auth.

## Tech Stack

| Layer    | Technology                          | Notes                                             |
|----------|-------------------------------------|---------------------------------------------------|
| Frontend | React 18 + TypeScript               | Vite build tooling                                |
| Styling  | Tailwind CSS                        | Utility-first, no component library, no inline styles |
| State    | React hooks + Context               | No external state manager                         |
| Routing  | React Router v6                     | Customer-facing + staff dashboard share routes    |
| Backend  | Node.js + Express                   | REST API                                          |
| Database | SQLite via `better-sqlite3`         | Single file, zero external DB server              |
| Testing  | Vitest + React Testing Library      | Unit + component tests                            |
| Linting  | ESLint + Prettier                   | TypeScript strict mode required                   |

## Project Structure

(proposed — update when scaffolded)

```
fired-up-pizza/
├── src/
│   ├── client/              # React app (customer + staff views)
│   │   ├── components/      # Shared UI components
│   │   ├── pages/           # Route-level views
│   │   ├── hooks/           # Custom React hooks
│   │   └── lib/             # Client-side helpers
│   ├── server/              # Express REST API
│   │   ├── routes/          # /api/v1/* handlers
│   │   ├── db/              # better-sqlite3 access + migrations
│   │   └── lib/             # Server-side helpers
│   └── shared/              # Types/schema shared client+server
├── tests/                   # Vitest specs (mirror src/ layout)
├── docs/
│   ├── plans/               # Planner output
│   ├── architecture/        # Architect ADRs
│   ├── designs/             # Designer specs
│   ├── reviews/             # Reviewer reports
│   └── releases/            # Deployer release gates
├── package.json
├── vite.config.ts
└── tsconfig.json
```

## Domain Model

Core entities and relationships:

- **MenuItem**: `id`, `name`, `description`, `base_price` (cents), `category`, `available` (boolean)
- **Topping**: `id`, `name`, `price` (cents), `available` (boolean)
- **Order**: `id`, `phone_number`, `status` (`placed | preparing | ready | delivered | cancelled`), `created_at`
- **OrderItem**: `id`, `order_id` (→ Order), `menu_item_id` (→ MenuItem), `size`, `crust`, `topping_ids[]` (→ Topping)
- **Customer**: identified by `phone_number` only — no separate Customer entity
- **Staff**: role-only — no separate Staff entity for MVP

Pricing rule: prices are **recomputed from the menu at display time** rather than cached on `OrderItem`. The schema stores only references; display logic joins through MenuItem + Topping. Trade-off accepted: historical orders reflect current menu prices, not the price at the time of order.

Status transitions: **linear only** — `placed → preparing → ready → delivered`. `cancelled` is reachable from any non-terminal state. Backtracking (e.g. `ready → preparing`) is explicitly out of scope; if staff need to undo a transition, they cancel and re-create.

## Conventions

- File naming: kebab-case for non-component files (`order-service.ts`); PascalCase for React components (`OrderCard.tsx`)
- Test files: co-located, suffix `.test.ts` / `.test.tsx`
- API routes: `/api/v1/<resource>` (e.g. `/api/v1/orders`, `/api/v1/menu-items`)
- Commits: conventional commits — `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- Branches: `<slug>-<feature>` per work item; never commit directly to `main`
- Pricing: store and compute in **cents** internally; format as dollars only at display boundaries
- TypeScript: strict mode required (no `any` without justification)
- Styling: Tailwind utility classes only — no inline `style={}` attributes

## Constraints

- No online payment processing — pay-at-counter model only
- No SMS or push notifications — order status visible only via in-app polling
- No multi-location support — single-restaurant scope
- No external auth provider — customer identity is phone number lookup only
- No external database server — SQLite single-file only
- No real-time infrastructure (websockets, SSE) — polling or manual refresh is acceptable
- No container, no cloud deployment target for MVP
- Must run with `npm install && npm run dev` — zero additional setup steps

---

## Task Inputs

(pipeline-critical — verify before running factory)

| Agent     | Receives                                                | From                                |
|-----------|---------------------------------------------------------|-------------------------------------|
| Planner   | Feature request + PROJECT_MANIFEST.md                   | Human / GitHub Issues               |
| Architect | Planner work package + Tech Stack + Constraints sections | `docs/plans/<slug>.md`             |
| Designer  | Architect ADR + Domain Model + Conventions sections     | `docs/architecture/NNNN-<slug>.md`  |
| Coder     | Designer spec + Conventions section                     | `docs/designs/<slug>-spec.md`       |
| Reviewer  | Code diff + Review Standards section                    | Feature branch `<slug>-<feature>`   |
| Deployer  | Reviewer report + Release Criteria section              | `docs/reviews/<slug>-review.md`     |

## Services to Connect

| Service        | Purpose                              | Config                                    |
|----------------|--------------------------------------|-------------------------------------------|
| GitHub         | Source control + PR flow             | Public repo, standard PR workflow         |
| GitHub Issues  | Backlog / Planner input              | Or in-repo `tickets.md` if Planner prefers|

(No CI/CD, observability, comms, or analytics services for MVP. Revisit if/when the app moves off single-machine deployment.)

## Success Criteria

### Per-Feature Success

- [ ] A customer can place an order end-to-end without making a phone call (browse → customize → submit)
- [ ] A customer can track an order through all four status stages (placed / preparing / ready / delivered) by phone-number lookup

### Factory-Level Success

- [ ] App starts on a clean clone with `npm install && npm run dev` — zero additional setup
- [ ] All Vitest + React Testing Library tests pass on a fresh checkout
- [ ] TypeScript strict mode (`tsc --noEmit`) and ESLint both pass without errors on every merged PR

---

## Review Standards

(default — customize for this project)

### Spec Compliance

- Every shipped behavior maps to a bullet in the Designer's spec — no scope creep without an updated spec
- Domain Model entities/fields/relationships in code match Section 4 of this manifest
- Status transitions in code match the documented linear flow — no backtracking paths
- Pricing logic recomputes from MenuItem + Topping at display time (no cached `unit_price` on `OrderItem`)

### Style

- TypeScript strict mode — no `any` without an inline justification comment
- No inline `style={}` — Tailwind utility classes only
- Components are functional, hooks-based — no class components
- API route handlers are thin; business logic lives in `src/server/lib/` or `src/server/db/`
- All monetary values flow as cents through code, formatted to dollars only in display layer

### Security

- Phone numbers are normalized + validated before use as identity (E.164 or documented format)
- All Express routes validate input shape before touching the DB (zod or equivalent)
- SQL access goes through parameterized statements only — no string-concatenated queries
- No customer PII (phone numbers) in client logs or error messages

### Severity Scale

- **Low**: cosmetic issues, minor inconsistencies
- **Medium**: functional gaps, missing edge cases, style violations
- **High**: data loss, security vulnerability, spec violation, broken status flow, pricing miscalculation

---

## Release Criteria

(default — customize for this project)

### Required (all must PASS)

1. [ ] All Vitest tests pass on a clean checkout
2. [ ] `tsc --noEmit` passes with strict mode enabled
3. [ ] ESLint passes with no errors
4. [ ] App boots successfully via `npm install && npm run dev`
5. [ ] Reviewer report exists and contains no `High` severity findings
6. [ ] All commits on the merged branch follow conventional-commit format
7. [ ] Designer spec for the feature is committed to `docs/designs/`

### Informational (reported but non-blocking)

- Test coverage delta vs. previous release
- Bundle size delta (Vite build output)
- Count of `Low` / `Medium` review findings deferred
