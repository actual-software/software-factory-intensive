# Project Overview: Fired Up Pizza

## 1. What it does

Fired Up Pizza is a web app for a small neighborhood pizza restaurant. Customers browse the menu, customize pizzas (size, crust, toppings), place an order against their phone number, and track it through "placed → preparing → ready → delivered." Staff use the same app to manage menu items and advance order status as pizzas move through the kitchen. It replaces a phone-only workflow that loses orders and leaves customers in the dark.

## 2. Goals & success criteria

- Customers can place and track an order without a phone call.
- Staff can see every live order in one view and update its status in one click.
- The whole thing runs on a single machine with `npm install && npm run dev` — no cloud setup.

## 3. Scope & constraints

- **In scope:** menu browsing, order placement, order status tracking, staff dashboard.
- **Out of scope (MVP):** online payments (pay at counter), SMS/push notifications, multi-location support, loyalty accounts.
- **Stack (already chosen):** React 18 + TypeScript + Vite on the frontend; Tailwind for styling; Node.js + Express REST API; SQLite via `better-sqlite3`; Vitest + React Testing Library.
- **Constraints:** no external auth (phone-number identity), no external DB server, no real-time infra — polling is acceptable.

## 4. Key roles & users

- **Customer** — places and tracks orders. Identified by phone number.
- **Staff** — views the live order queue, advances order status, edits menu items.

## 5. Domain context

Small neighborhood restaurant currently taking orders by phone. No prior software. The owner wants something they can run themselves on a single back-office machine, without paying a monthly platform fee and without a dedicated IT person. Any agent working on this codebase should assume the deployment environment is one laptop in the back of the shop, not a fleet.
