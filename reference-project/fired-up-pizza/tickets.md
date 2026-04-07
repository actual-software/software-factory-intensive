# Initial Ticket Set — Fired Up Pizza

These tickets form the backlog for the Fired Up Pizza software factory. Import them as beads with `bd create` or use them as feature requests for the Planner agent.

Tickets are ordered by dependency — earlier tickets should be completed first.

---

## FUP-1: Menu display page

**Priority:** P0

Display the restaurant menu grouped by category (Pizzas, Sides, Drinks, Desserts). Each item shows name, description, price, and an image placeholder. Items marked unavailable appear grayed out.

**Acceptance Criteria:**
- Menu items load from the API and render grouped by category
- Unavailable items are visually distinct (grayed out, not hidden)
- Prices display as dollars with two decimal places (e.g., $12.99)

---

## FUP-2: Pizza customization

**Priority:** P0

When a customer selects a pizza, they can choose size (small/medium/large), crust type (thin/regular/thick), and add/remove toppings. The price updates live as options change.

**Acceptance Criteria:**
- Size selection adjusts base price (small 1x, medium 1.3x, large 1.6x)
- Crust selection is available with no price impact
- Toppings can be added/removed with per-topping pricing
- Total price updates without page reload

---

## FUP-3: Shopping cart

**Priority:** P0

Customers can add customized items to a cart, adjust quantities, remove items, and see the running total. Cart persists across page navigation.

**Acceptance Criteria:**
- Items can be added, quantity adjusted, and removed
- Cart total updates on every change
- Cart state persists during a browser session
- Empty cart shows a clear "your cart is empty" state

---

## FUP-4: Order placement

**Priority:** P1

Customers enter their name and phone number and place the order. The system confirms with an order number. No payment processing — pay at counter.

**Acceptance Criteria:**
- Name and phone are required fields with validation
- Order is saved to the database with status "placed"
- Confirmation page shows order number and estimated time
- Cart is cleared after successful placement

---

## FUP-5: Order status tracking

**Priority:** P1

Customers can look up their order by phone number and see current status (placed, preparing, ready, delivered). Staff can update order status from an admin view.

**Acceptance Criteria:**
- Customer lookup by phone number returns matching orders
- Order status displays with a visual progress indicator
- Staff admin page lists orders and allows status updates
- Status transitions follow the allowed flow (placed → preparing → ready → delivered)

---

## FUP-6: Order history page

**Priority:** P2

Customers can view their past orders by phone number. Each order shows items, total, date, and final status. This is the capstone feature used in C1.

**Acceptance Criteria:**
- Orders display in reverse chronological order
- Each order shows full item list with customizations
- Order total and status are visible
- Empty state shows "no orders found" when phone number has no history
