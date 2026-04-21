# Project Manifest: Fired Up Pizza

## Overview

**Fired Up Pizza** is an online pizza ordering application where customers can build custom pizzas, select a pickup or delivery time, and place orders — all within a single-page experience. No payment processing is required; all transactions are handled on-site at pickup/delivery.

---

## Feature Use Cases

### UC-1: Browse Menu

- **As a** customer
- **I want to** see available pizza options when I land on the site
- **So that** I can quickly decide what to order

**Acceptance Criteria:**
- Display featured pizzas and a "Build Your Own" option
- Show base prices for each size
- Menu loads without page navigation

### UC-2: Select Pizza Size

- **As a** customer
- **I want to** choose a pizza size (Small, Medium, Large, XL)
- **So that** I can order the right amount of food

**Acceptance Criteria:**
- Four size options: Small (10"), Medium (12"), Large (14"), XL (16")
- Price updates dynamically when size is selected
- Size selection is required before adding to cart

### UC-3: Choose Toppings

- **As a** customer
- **I want to** pick toppings for my pizza from a categorized list
- **So that** I can customize my order

**Acceptance Criteria:**
- Toppings grouped by category (Meats, Veggies, Cheeses, Sauces)
- Each topping shows its add-on price
- Running total updates as toppings are added/removed
- Support for "extra" and "light" topping modifiers
- Maximum of 10 toppings per pizza

### UC-4: Schedule Pickup or Delivery Time

- **As a** customer
- **I want to** select a pickup or delivery time slot
- **So that** my order is ready when I arrive or expect delivery

**Acceptance Criteria:**
- Toggle between Pickup and Delivery
- Delivery requires an address input
- Time slots shown in 15-minute increments
- Earliest available slot is 30 minutes from now
- Slots are available during business hours only (11 AM – 10 PM)

### UC-5: Manage Cart

- **As a** customer
- **I want to** review, edit, or remove items in my cart
- **So that** I can finalize my order before placing it

**Acceptance Criteria:**
- View itemized list with size, toppings, and price per pizza
- Edit any pizza (returns to customization view with selections preserved)
- Remove individual items
- Display order subtotal

### UC-6: Place Order (No Payment)

- **As a** customer
- **I want to** submit my order with my name and phone number
- **So that** the kitchen can prepare it and contact me if needed

**Acceptance Criteria:**
- Collect customer name and phone number
- No credit card or payment form — transaction settles on-site
- Display order confirmation with summary and estimated ready time
- Order is persisted to the database

### UC-7: Order Confirmation

- **As a** customer
- **I want to** see a confirmation screen after placing my order
- **So that** I know my order was received

**Acceptance Criteria:**
- Show order number, itemized summary, and scheduled time
- Provide option to "Place Another Order" (resets the flow)
- No page reload — confirmation renders in-app

---

## UX Constraints

| Constraint | Detail |
|---|---|
| **Single-Page Application (SPA)** | The entire ordering flow — menu browsing, customization, cart, and checkout — must occur without full page reloads. All navigation is handled client-side. |
| **Linear Flow, Non-Linear Access** | The primary flow is Menu → Customize → Cart → Checkout → Confirmation, but users can jump back to any step from the cart. |
| **Mobile-First Responsive** | Layout must work on screens from 375px wide and up. Topping selection must be touch-friendly. |
| **No Authentication Required** | Customers do not create accounts or log in. Name and phone are collected at checkout only. |
| **Accessibility** | WCAG 2.1 AA compliance. All interactive elements must be keyboard-navigable and screen-reader accessible. |

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
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  menu_items  │     │   toppings   │     │    orders    │
├──────────────┤     ├──────────────┤     ├──────────────┤
│ id           │     │ id           │     │ id           │
│ name         │     │ name         │     │ customer_name│
│ description  │     │ category     │     │ phone        │
│ base_price   │     │ price        │     │ order_type   │
│ image_url    │     │ available    │     │ address      │
│ available    │     └──────────────┘     │ scheduled_at │
└──────────────┘                          │ status       │
                                          │ total        │
      ┌──────────────┐                    │ created_at   │
      │ order_items  │                    └──────────────┘
      ├──────────────┤
      │ id           │
      │ order_id (FK)│
      │ size         │
      │ base_price   │
      │ item_total   │
      └──────────────┘
              │
      ┌───────────────────┐
      │ order_item_toppings│
      ├───────────────────┤
      │ id                │
      │ order_item_id (FK)│
      │ topping_id (FK)   │
      │ modifier          │
      └───────────────────┘
```

---

## Out of Scope

- User accounts / authentication
- Payment processing
- Order tracking / real-time status updates
- Admin dashboard for kitchen staff
- Loyalty programs or promo codes
- Multi-location support
