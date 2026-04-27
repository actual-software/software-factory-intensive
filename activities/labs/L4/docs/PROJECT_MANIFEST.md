# Project Manifest: My App

## Overview

**My App** is an ...

---

## Feature Use Cases

### UC-1: Browse Menu

- **As a** customer
- **I want to** see ... options when I land on the site
- **So that** I can quickly decide ...

**Acceptance Criteria:**
- Display ... option
- Show ... for each product
- Menu loads without page navigation

---

## UX Constraints

| Constraint | Detail |
|---|---|
| **Single-Page Application (SPA)** | The entire ordering flow — menu browsing, customization, cart, and checkout — must occur without full page reloads. All navigation is handled client-side. |

---

## Tech Constraints

| Constraint | Detail |
|---|---|
| **Framework** | Next.js (App Router) with React Server Components where applicable. Client components for interactive ordering flow. |
| **Database** | PostgreSQL for persistent storage of menu items, toppings, orders, and time slots. |
| **ORM** | Drizzle ORM or Prisma for type-safe database access. |
| **Styling** | Tailwind CSS. No additional CSS frameworks. |
| **API Layer** | Next.js Server Actions or Route Handlers for order submission and menu data. |
| **State Management** | React context or Zustand for client-side cart state. No Redux. |
| **Deployment Target** | Vercel (or any Node.js-compatible platform). |
| **No Payment Integration** | No Stripe, Square, or any payment gateway. Orders are pay-on-site only. |
| **Time Zone** | All time slots are displayed and stored in the shop's local time zone. |
| **Data Validation** | Zod schemas for validating order payloads on both client and server. |

---

## Data Model (High-Level)

```
```

---

## Out of Scope

- User accounts / authentication
