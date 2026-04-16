# My AI Workflow Card — Fired Up Pizza

Written by the project owner before L1. This is the "W1 artifact" that gets converted into `CLAUDE.md` (dev-agent instructions) during L1, and later split across per-agent pack prompts in L2–L4.

---

## 1. Prompt Template

Every prompt I paste into Claude Code for this project includes, in order:

- **Target**: a file path under `src/` or a ticket ID (`FUP-3`, etc.). No "the cart thing."
- **Acceptance criteria**: pasted verbatim from the ticket. If I'm inventing the AC on the fly, I write them down first and paste the exact text.
- **Stack constraints**: "React 18 + TypeScript strict, Tailwind CSS utility classes, no inline styles, no `any` types." These never change.
- **Reference files**: two similar existing files the agent should read first for pattern-matching (e.g., for a new page component I'd reference `src/pages/MenuPage.tsx` and `src/pages/OrderStatusPage.tsx`).
- **Testing hint**: "Vitest + React Testing Library. Co-located `<Name>.test.tsx` file."

## 2. Context Reset Rule

I start a fresh Claude Code session when any of these triggers:

- The conversation has 10+ back-and-forths. Context has drifted.
- The agent contradicts something from earlier in the same session. Context is polluted.
- I'm switching from a customer-facing feature to a staff-facing feature (or vice versa). The domain model in scope is different.
- The agent proposes something I'd reject (new dependency, new architecture pattern, schema change). Better to throw away the session and restart with that constraint encoded up front.

I do **not** reset between small slices of the same feature — resetting too aggressively loses useful context.

## 3. Iteration Loop

Every feature follows this loop. If I skip a step I have to say why in the commit body.

1. **Plan first.** The agent reads the spec and the two reference files, then writes a 3-line plan as a bead comment before any code.
2. **I confirm or redirect** the plan. If the plan invents new patterns or touches files outside scope, I reject and clarify.
3. **Agent writes code in one-slice increments.** A slice is one component, one hook, one route, or one test. Never all three at once.
4. **I run the gates after every slice**: `npm run lint && npm run type-check && npm test`. All three must exit 0.
5. **If a gate fails**, I update the spec or `CLAUDE.md` with the missing constraint, `git reset --hard HEAD`, and re-sling. I do not type "oh and also please X" into chat.
6. **If a gate passes**, the agent commits with a conventional message (`feat(cart): show order total`) and moves to the next slice.
7. **When all slices land**, the agent opens a PR. I review; if I find issues that would repeat, I push them into `CLAUDE.md` rather than leaving a PR comment.

## 4. Decision Checkpoint

Decisions I keep for myself (the agent may propose; I decide):

- Database schema changes (we only have `orders`, `menu_items`, `toppings` — adding a column is a decision).
- New package or dependency additions. npm registry is rich; bar for pulling something in is high.
- API contract changes (URL shape, request/response shape). Any change here potentially breaks the frontend-backend contract.
- Architecture patterns I haven't used elsewhere in the codebase (new state-management approach, new layout pattern, new routing scheme).
- Anything that touches money formatting or order total math.

Decisions the agent owns:

- Function-level implementation details within a file.
- Test case design (which cases to write, how to structure fixtures).
- Error-message wording for user-facing error states (as long as it matches the existing voice — cheerful, specific, non-technical).
- File organization *within* a component directory (if it's adding a sub-component, that's the agent's call).
- Choosing between equivalent idiomatic approaches in React or TypeScript.
