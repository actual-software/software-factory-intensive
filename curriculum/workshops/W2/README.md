# W2 · Design the 6-Agent Software Factory

> **Goal:** Understand the complete architecture of a 6-agent software factory and design how agents hand off work through the pipeline—preparing you to build it in the labs.

| | |
|---|---|
| **Day** | Day 1 |
| **Time** | 1:30 - 2:15 |
| **Type** | WORKSHOP |
| **Deliverable** | Factory wiring diagram + handoff contracts |

---

## The 6-Agent Factory Architecture

```
Feature Request
      ↓
[1. PLANNER] → Work Package
      ↓
[2. ARCHITECT] → ADR (Architectural Decision Record)
      ↓
[3. DESIGNER] → Implementation Plan
      ↓
[4. CODER] → Code + Tests
      ↓
[5. REVIEWER] → Review Results
      ↓
[6. DEVOPS] → Deployed Feature
```

---

## Agent Roles & Responsibilities

### 1. Planner Agent
**Input:** Feature request (natural language)  
**Output:** Work Package (structured user stories with acceptance criteria)  
**Responsibility Boundary:** Breaks down WHAT to build, not HOW to build it  
**Key Question:** "Is this feature clear enough that another agent could implement it?"

### 2. Architect Agent
**Input:** Work Package  
**Output:** ADR (architectural decisions with trade-off analysis)  
**Responsibility Boundary:** Makes technical decisions about HOW to build, evaluates options  
**Key Question:** "What are the long-term consequences of this approach?"

### 3. Designer Agent
**Input:** Work Package + ADR  
**Output:** Implementation Plan (file structure, interfaces, test strategy)  
**Responsibility Boundary:** Translates decisions into concrete code structure  
**Key Question:** "Can a coder implement this without making architectural decisions?"

### 4. Coder Agent
**Input:** Implementation Plan  
**Output:** Working code + tests  
**Responsibility Boundary:** Writes code exactly as designed, no architectural changes  
**Key Question:** "Does this code follow the design and pass quality gates?"

### 5. Reviewer Agent
**Input:** Code + Tests (via PR)  
**Output:** Review results (approve/request changes)  
**Responsibility Boundary:** Ensures quality, consistency, and adherence to standards  
**Key Question:** "Is this code ready for production?"

### 6. DevOps Agent
**Input:** Approved PR  
**Output:** Deployed feature + monitoring  
**Responsibility Boundary:** Deploys, monitors, documents operational aspects  
**Key Question:** "Is this feature reliably running in production?"

---

## Handoff Contracts

Each stage outputs artifacts that the next stage consumes. Clear contracts prevent confusion.

### Planner → Architect
**Contract:**
- Planner MUST provide: Work package with user stories, acceptance criteria, dependencies
- Architect EXPECTS: Clear problem statement, constraints, success criteria
- Architect MUST NOT: Change user stories or acceptance criteria

**Example Work Package:**
```markdown
# WP-2026-04-07-search-feature

## Goal
Add search capability to product catalog

## User Stories
1. As a user, I want to search products by name
   - [ ] Search box visible on catalog page
   - [ ] Results update as I type (debounced)
   - [ ] Shows "No results" if nothing matches

## Dependencies
- Existing: Product catalog API
- New: Search indexing (backend work)
```

---

### Architect → Designer
**Contract:**
- Architect MUST provide: ADR with chosen approach, trade-offs, constraints
- Designer EXPECTS: Technical direction, what CAN and CANNOT be done
- Designer MUST NOT: Reconsider architectural decisions already made

**Example ADR:**
```markdown
# ADR-0002: Client-Side Search vs Server-Side Search

## Decision
Use client-side filtering for MVP, migrate to server-side when catalog > 1000 items.

## Consequences
+ Faster for small catalogs (<1000 items)
+ Simpler to implement (no backend changes)
- Won't scale beyond 1000 items
- Must migrate later

## Constraints for Designer
- Implement client-side using existing product list data
- Add TODO comment: "Migrate to API search when catalog grows"
```

---

### Designer → Coder
**Contract:**
- Designer MUST provide: Complete file structure, typed interfaces, test plan
- Coder EXPECTS: No ambiguity about WHERE code goes or WHAT interfaces to implement
- Coder MUST NOT: Reorganize files or change interfaces

**Example Design Doc:**
```markdown
# Implementation Plan: Product Search

## File Structure
src/
  components/
    ProductSearch.tsx       # Search input component
    SearchResults.tsx       # Results display
  hooks/
    useProductSearch.ts     # Search logic
  types/
    search.ts               # TypeScript interfaces

## Interfaces
\`\`\`typescript
interface SearchProps {
  products: Product[];
  onResultClick: (product: Product) => void;
}
\`\`\`

## Test Plan
- Unit: useProductSearch hook filters correctly
- Integration: ProductSearch component renders results
- E2E: User types query, sees filtered list
```

---

## Workshop Activity: Design Your Factory

### Part 1: Map Your Project (20 min)

**With your pod, answer:**

1. **What feature will you implement during the intensive?**
   - Keep it small (implementable in ~2 hours of coding)
   - Examples: "Add export to CSV", "Implement password reset", "Add dark mode toggle"

2. **For each agent, what will it produce for YOUR feature?**
   - Planner → [Your work package]
   - Architect → [Your architectural decision]
   - Designer → [Your file structure]
   - Coder → [Your code artifact]
   - Reviewer → [Your review criteria]
   - DevOps → [Your deployment target]

3. **What existing code will your feature touch?**
   - List files/modules that will be modified
   - Identify integration points

**Deliverable:** One-page doc answering these questions for your feature.

---

### Part 2: Define Handoff Contracts (15 min)

**Pick TWO adjacent stages** (e.g., Architect → Designer) and document:

```markdown
## [Stage A] → [Stage B] Handoff Contract

### Stage A MUST provide:
- [Artifact 1]
- [Artifact 2]

### Stage B EXPECTS to receive:
- [What format?]
- [What level of detail?]

### Stage B MUST NOT:
- [What decisions should NOT be revisited?]

### Example for our feature:
[Paste example showing the contract]
```

**Deliverable:** Two handoff contracts documented.

---

## Key Principles (Discussion)

### 1. Separation of Concerns
**Planner doesn't code. Coder doesn't architect.**

Why? Prevents agents from making conflicting decisions. Each agent has a narrow, well-defined job.

### 2. Config Over Prompting
**Wrong:** "Hey Coder, actually put that file in a different directory."  
**Right:** Update Designer's AGENTS.md to specify the correct directory, re-run Designer.

Why? Ad-hoc changes break repeatability. The factory must run the same way every time.

### 3. Artifacts as Communication
**Agents don't "remember" conversations. They read files.**

Work packages, ADRs, and design docs are the communication layer. If it's not in a file, it doesn't exist.

---

## Recommended Prompts

### When Designing Your Factory
```
I'm building a software factory for [project description].

The feature I want to automate is: [feature name]

Help me map out:
1. What each of the 6 agents (Planner, Architect, Designer, Coder, Reviewer, DevOps) will produce for this feature
2. What existing code/systems this feature will integrate with
3. Any unique constraints or requirements for my project

Be specific about artifacts and handoffs.
```

### When Defining Handoff Contracts
```
For the [Agent A] → [Agent B] handoff in my software factory:

Agent A produces: [artifact type]
Agent B needs: [information required]

Help me define:
1. What MUST be in Agent A's output
2. What Agent B can EXPECT to receive
3. What Agent B should NOT try to change or reconsider

Provide an example contract for my feature: [feature name]
```

---

## Exit Criteria

✅ Factory design doc created with roles mapped to your feature  
✅ Two handoff contracts documented  
✅ Pod discussion captured one insight about separation of concerns  

---

## Walkthrough: Map Your Design onto the Shipped Packs

You're not inventing agents from scratch — Gas City ships a pack per agent, and your job in W2 is to understand the shape each pack provides so that your design *conforms* to that shape.

Open each of these in your editor as a short reading exercise. These are the files you'll customize in L2–L4; recognize the structure now so they feel familiar when you install them.

| Agent | Pack | Prompt file (the "workflow card" for the agent) |
|-------|------|--------------------------------------------------|
| Planner | [`packs/planner/`](../../../packs/planner/) | [`packs/planner/prompts/planner.md`](../../../packs/planner/prompts/planner.md) |
| Architect | [`packs/architect/`](../../../packs/architect/) | [`packs/architect/prompts/architect.md`](../../../packs/architect/prompts/architect.md) |
| Designer | [`packs/designer/`](../../../packs/designer/) | [`packs/designer/prompts/designer.md`](../../../packs/designer/prompts/designer.md) |
| Coder | [`packs/coder/`](../../../packs/coder/) | [`packs/coder/prompts/coder.md`](../../../packs/coder/prompts/coder.md) |
| Reviewer | [`packs/reviewer/`](../../../packs/reviewer/) | [`packs/reviewer/prompts/reviewer.md`](../../../packs/reviewer/prompts/reviewer.md) |
| Deployer | [`packs/deployer/`](../../../packs/deployer/) | [`packs/deployer/prompts/deployer.md`](../../../packs/deployer/prompts/deployer.md) |

Every prompt file shares a consistent shape — **Role**, **Inputs**, **Output Format**, **Quality Gate**, **Process**, **Config Discipline**. When you design your factory below, use these five headings as the axis for each agent.

### Your pod's design deliverable → pack customization

For each of the 6 agents, your pod's W2 deliverable maps to a specific file you'll edit in an upcoming session:

| W2 deliverable | Becomes | Installed in |
|----------------|---------|--------------|
| "Planner produces `[your work package format]`" | Edits to `packs/planner/prompts/planner.md` (Output Format section) | L2 |
| "Architect produces `[your ADR format]`" | Edits to `packs/architect/prompts/architect.md` (Output Format section) | L2 |
| "Designer produces `[your implementation plan format]`" | Edits to `packs/designer/prompts/designer.md` | L3 |
| "Coder writes to `[your src layout]`" | Edits to `packs/coder/prompts/coder.md` | L3 |
| "Reviewer checks `[your review standards]`" | Edits to `packs/reviewer/prompts/reviewer.md` | L4 |
| "Deployer gates on `[your release criteria]`" | Edits to `packs/deployer/prompts/deployer.md` | L4 |
| Handoff contract Planner → Architect | The `## Inputs` and `## Output Format` sections must match across both prompt files | L2 |

**Output your design as a table**, not as prose. Prose will be hard to translate into prompt-file edits on Monday.

---

## Walkthrough: Use the Skeleton Template to Scaffold Your Project

`my-factory/` is the skeleton every participant starts from. Its directory layout matches the Output Location of every pack:

```
my-factory/
  docs/
    PROJECT_MANIFEST.md        ← the source of truth every agent reads first
    adr/                       ← Architect writes here (ADR-NNNN-slug.md)
  work-packages/               ← Planner writes here
  design/                      ← Designer writes here
  review-reports/              ← Reviewer writes here
  release-gates/               ← Deployer writes here
  feedback-loops/              ← W4 feedback rules
  CLAUDE.md                    ← Global agent instructions
```

During W2, two of these files matter most:

1. **`my-factory/docs/PROJECT_MANIFEST.md`** — your design's single source of truth. Every agent reads this before doing anything. Your W2 design decisions about domain model, conventions, success criteria, and review standards *all* land here. If you haven't started filling it in, do so now — paste in the Part 1 Map-Your-Project deliverable at minimum.

2. **`my-factory/CLAUDE.md`** — the global agent instructions. Start lightweight (it mirrors Fired Up Pizza's `CLAUDE.md`) and let L1–L4 fill it in.

If you haven't copied the skeleton into your project repo yet, do so now so L2 starts clean:

```bash
cp -r /path/to/software-factory-intensive/my-factory/* ~/path/to/your-repo/
```

---

## Walkthrough: Read Fired Up Pizza as a Finished Reference

Fired Up Pizza is the reference project — a complete, working example of a 6-agent factory's *shape*. Spend 5 minutes scanning:

- [`reference-project/fired-up-pizza/CLAUDE.md`](../../../reference-project/fired-up-pizza/CLAUDE.md) — the finished Day-1 `CLAUDE.md`. Note the conventions: "Prices in cents internally, formatted as dollars for display."
- [`reference-project/fired-up-pizza/docs/PROJECT_MANIFEST.md`](../../../reference-project/fired-up-pizza/docs/PROJECT_MANIFEST.md) — compare length and specificity to the `my-factory/docs/PROJECT_MANIFEST.md` template you've been filling in.
- [`reference-project/fired-up-pizza/tickets.md`](../../../reference-project/fired-up-pizza/tickets.md) — the backlog that feeds the factory. Note how each ticket is written: single-sentence goal, explicit acceptance criteria, no implementation detail.
- [`packs/fired-up-pizza/pack.toml`](../../../packs/fired-up-pizza/pack.toml) — the *composite* pack that bundles all 6 agent packs with a single `gc rig add --include packs/fired-up-pizza` command.

Ask yourself: if I replaced `docs/PROJECT_MANIFEST.md` in Fired Up Pizza with mine, would the agent prompts still make sense? If not, your manifest is under-specified — that's what W2's Part 1 corrects.

---

## Architect Agent: The Actual AI ADR System

Your Architect agent writes ADRs (Architecture Decision Records). You have two ways to source ADR content:

1. **Write each ADR from scratch** — the Architect proposes three options, evaluates trade-offs, picks one. This is what L2 walks you through.
2. **Use Actual AI's ADR system** (`actual adr-bot`) — a CLI that analyzes your repo and *tailors* best-practice ADRs to your codebase, writing them into `CLAUDE.md` / `AGENTS.md` automatically. Your Architect then references those ADRs when making local decisions instead of rediscovering industry patterns.

Install it (optional but strongly recommended for real projects):

```bash
brew install actual-software/actual/actual

# From your project repo
cd ~/path/to/your-repo
actual adr-bot --dry-run      # Preview what it would write
actual adr-bot                 # Write tailored ADRs into CLAUDE.md
```

What this adds to your W2 design:

- **Handoff contract Planner → Architect** gains a prior step: the Architect reads the curated ADR set first, and only writes a new ADR when the decision isn't covered by an existing one.
- **Quality bar for ADRs** gets higher: a decision to *deviate* from a tailored industry ADR is a more interesting artifact than a decision made in a vacuum.
- **Review criteria (Reviewer agent, W4 inputs)** now has `actual`-sourced ADRs as an additional compliance axis: "Does this code violate ADR-0007 (serde-rename-all)?"

Note this in your W2 design: *"Architect reads `CLAUDE.md` ADR section first; writes new ADRs to `docs/adr/NNNN-<slug>.md` only for decisions not covered."*

If you're working against `reference-project/fired-up-pizza/`, `actual adr-bot` would populate its `CLAUDE.md` with React/TypeScript ADRs that the Architect then extends with pizza-specific ones (pricing model, menu-categorization rule, etc.).

---

## Next Steps

In **L2**, you'll build the first two agents (Planner + Architect) using this design. Your handoff contracts will guide how you configure their prompt files. Your `docs/PROJECT_MANIFEST.md` becomes what they both read first.

**Bring to L2:**
- [ ] A filled-in `docs/PROJECT_MANIFEST.md`
- [ ] The two handoff contracts from Part 2 (written as a table, not prose)
- [ ] A one-sentence note of which ADRs you'll seed via `actual adr-bot` vs. write by hand
