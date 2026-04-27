# Project Manifest: Fired Up Pizza

## Overview

Fired Up Pizza is a web application for a pizza restaurant. Customers can browse the menu, customize pizzas, place orders, and track delivery. Staff can manage menu items, view incoming orders, and update order status.

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Frontend | React 18 + TypeScript | Vite build tooling |
| Styling | Tailwind CSS | Utility-first, no component library |
| State | React hooks + Context | No external state manager |
| Routing | React Router v6 | Client-side routing |
| Backend | Node.js + Express | REST API |
| Database | SQLite (via better-sqlite3) | Single-file, no setup required |
| Testing | Vitest + React Testing Library | Unit + component tests |
| Linting | ESLint + Prettier | Config in repo root |

## Project Structure

```
src/
  components/       # Reusable UI components
  pages/            # Route-level page components
  api/              # Express API routes
  db/               # Database schema and queries
  hooks/            # Custom React hooks
  types/            # TypeScript type definitions
  utils/            # Shared utilities
public/             # Static assets
docs/               # ADRs and documentation
  adr/              # Architecture Decision Records
docs/plans/      # Planner output
docs/designs/             # Designer component specs
docs/reviews/     # Reviewer output
docs/releases/      # Deployer output
feedback-loops/     # Continuous improvement artifacts
```

## Domain Model

```
Menu
  MenuItem: { id, name, description, price, category, image, available }
  Category: { id, name, sortOrder }

Orders
  Order: { id, items[], status, total, customerName, customerPhone, createdAt }
  OrderItem: { menuItemId, quantity, customizations[] }
  OrderStatus: placed → preparing → ready → delivered | cancelled

Customizations
  Topping: { id, name, price, category: meat|veggie|cheese }
  Size: small | medium | large (price multiplier)
  Crust: thin | regular | thick
```

## Conventions

- Component files: PascalCase (`MenuItemCard.tsx`)
- Utility files: camelCase (`formatPrice.ts`)
- Test files: co-located (`MenuItemCard.test.tsx`)
- API routes: `/api/v1/<resource>` (REST, JSON)
- Commits: conventional commits (`feat:`, `fix:`, `docs:`)
- Branches: `plan/<slug>`, `feat/<slug>`, `fix/<slug>`

## Constraints

- No external auth provider — simple phone number lookup for MVP
- No payment processing — order placement is "pay at counter"
- No real-time updates — polling or manual refresh for order status
- SQLite only — no external database server required
- Must run with `npm install && npm run dev` — zero additional setup

---

## Task Inputs

What each factory agent receives as input:

| Agent | Receives | From |
|-------|----------|------|
| Planner | Feature request (bead title + description) | Ticket backlog or Jira sync |
| Architect | Work package | `docs/plans/<slug>.md` |
| Designer | Work package + ADR | `docs/plans/` + `docs/architecture/` |
| Coder | Component spec + test cases | `docs/designs/<slug>-spec.md` + work package |
| Reviewer | Code diff + spec + review standards | Feature branch + `docs/designs/` + this manifest |
| Deployer | Review report + release criteria | `docs/reviews/` + this manifest |

Each agent reads this manifest for project context. The agent's prompt defines its output format and quality gate.

## Services to Connect

| Service | Purpose | Config |
|---------|---------|--------|
| GitHub | Source control, pull requests | `GITHUB_TOKEN` with repo scope |
| npm registry | Package dependencies | Default public registry |
| SQLite | Local database (no server needed) | Built into the app via better-sqlite3 |

For MVP, no external deployment target, CI/CD, or monitoring is required. The app runs locally with `npm run dev`.

## Success Criteria

### Per-Feature Success

- All acceptance criteria from the work package are met
- Code review approved with no high-severity findings
- All tests pass (`npm test` exits 0)
- Lint clean (`npm run lint` exits 0)
- Feature branch is mergeable (no conflicts with main)

### Factory-Level Success

- Feature completed with zero ad-hoc prompts (all behavior from config)
- All 6 pipeline stages produced committed artifacts
- Each handoff between agents used the defined artifact paths (no out-of-band communication)

---

## Review Standards

Applied by the Reviewer agent when evaluating code.

### Spec Compliance

- Every prop/input from the component spec must be implemented
- Every interaction from the spec must work as described
- Edge cases (empty, error, loading) must be handled
- Data types must match the spec exactly

### Style

- No inline styles — use Tailwind CSS classes
- Components under 200 lines (split if larger)
- No `any` types in TypeScript
- Consistent naming per project conventions

### Security

- No user input rendered without sanitization
- API endpoints validate all input parameters
- No secrets or credentials in code
- SQL queries use parameterized statements (no string concatenation)

### Severity Scale

- **Low**: style nit, minor improvement opportunity
- **Medium**: missing test, incomplete error handling, accessibility gap
- **High**: security issue, data corruption risk, spec violation

---

## Release Criteria

Evaluated by the Deployer agent before a feature is marked deployment-ready.

### Required (all must PASS)

1. All acceptance criteria from the work package are met
2. Review report verdict is APPROVE (no open high-severity findings)
3. Tests pass (`npm test` exits 0)
4. Lint clean (`npm run lint` exits 0)
5. No untracked files in feature scope (`git status` clean)
6. Branch mergeable with main (no conflicts)

### Informational (reported but non-blocking)

- Test coverage percentage
- Bundle size delta
- Number of new dependencies added
