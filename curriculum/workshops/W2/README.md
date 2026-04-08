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

## Next Steps

In **L2**, you'll build the first two agents (Planner + Architect) using this design. Your handoff contracts will guide how you configure their AGENTS.md specs.
