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
work-packages/      # Planner output
design/             # Designer component specs
review-reports/     # Reviewer output
release-gates/      # Deployer output
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

## Quality Standards

- All components must handle loading, empty, and error states
- All API endpoints must validate input and return structured errors
- All prices in cents (integer), display formatted as dollars
- No inline styles — Tailwind classes only
- Tests required for business logic and user interactions

## Constraints

- No external auth provider — simple phone number lookup for MVP
- No payment processing — order placement is "pay at counter"
- No real-time updates — polling or manual refresh for order status
- SQLite only — no external database server required
- Must run with `npm install && npm run dev` — zero additional setup
