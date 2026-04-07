# L3 · Deploy Designer + Coder Agents

> **Goal:** Add Designer and Coder agents that translate architectural decisions into working code—consuming work packages and ADRs to generate implementation artifacts.

| | |
|---|---|
| **Day** | Day 1 |
| **Time** | 3:45 - 5:00 |
| **Type** | LAB |
| **Deliverable** | Working Designer + Coder agents + implemented feature |

---

## What You'll Build

```
Work Package + ADR (from L2)
      ↓
Designer Agent creates implementation plan
      ↓
Produces: Design doc (file structure, interfaces, test plan)
      ↓
Coder Agent implements the design
      ↓
Produces: Working code + tests
      ↓
Feature ready for review
```

---

## Prerequisites

✅ L2 complete (Planner + Architect agents working)  
✅ Work package + ADR artifacts exist in repo  
✅ Gas City running  

---

## Step 1: Add Designer Agent to city.toml

```toml
[[agent]]
name = "designer"
dir = "your-repo-name"
provider = "claude"
idle_timeout = "2h"
role = "designer"
```

Restart Gas City:

```bash
gc restart
gc status
```

---

## Step 2: Add Designer Guidance to AGENTS.md

```markdown
## Designer Agent

### Role
You translate work packages and ADRs into detailed implementation plans that Coder agents can execute.

### Responsibilities
1. Read work package and referenced ADR
2. Design file structure and module organization
3. Define interfaces and data models
4. Plan test coverage strategy
5. Identify reusable components

### Implementation Plan Template

\`\`\`markdown
# Implementation Plan: [Feature Name]

**Work Package:** [WP-ID]  
**ADR:** [ADR-ID]  
**Date:** [YYYY-MM-DD]

## File Structure
\`\`\`
src/
  features/loyalty-points/
    types.ts          # Data models
    api.ts            # API calls
    hooks.ts          # React hooks
    LoyaltyBadge.tsx  # UI component
  __tests__/
    loyalty-points.test.ts
\`\`\`

## Interfaces & Types
\`\`\`typescript
interface LoyaltyPoints {
  userId: string;
  balance: number;
  earned: number;
  redeemed: number;
  lastUpdated: Date;
}
\`\`\`

## Component Specifications

### LoyaltyBadge Component
**Purpose:** Display user's points balance
**Props:**
- `userId: string`
- `showDetails?: boolean`

**Behavior:**
- Fetches points on mount
- Updates on order completion event
- Shows loading state while fetching

## Test Coverage Plan
- Unit tests: API functions, hooks
- Integration tests: Component with mocked API
- E2E test: Full points earn + redeem flow

## Dependencies
- Existing: order system API, user authentication
- New: loyalty-points API endpoint (backend)

## Implementation Order
1. Define types
2. Implement API layer with mocks
3. Build UI components
4. Add tests
5. Integration with order flow
\`\`\`

### Output Location
Save plans to: `design-docs/[feature-name].md`

### Quality Standards
- File structure matches project conventions
- All interfaces typed explicitly
- Test plan covers happy path + error cases
- Dependencies on existing code identified
```

---

## Step 3: Add Coder Agent to city.toml

```toml
[[agent]]
name = "coder"
dir = "your-repo-name"
provider = "claude"
idle_timeout = "3h"
role = "coder"
```

Restart:

```bash
gc restart
gc status
```

---

## Step 4: Add Coder Guidance to AGENTS.md

```markdown
## Coder Agent

### Role
You implement features based on implementation plans, following all coding standards and quality gates.

### Responsibilities
1. Read implementation plan completely
2. Follow file structure exactly as designed
3. Implement all interfaces and components
4. Write tests matching test plan
5. Ensure code passes all quality gates

### Implementation Standards
- **TypeScript:** All new code uses TypeScript with strict mode
- **Testing:** Jest for unit tests, React Testing Library for components
- **Linting:** Follows ESLint config in repository
- **Formatting:** Prettier with project settings
- **Commits:** One commit per logical unit (types, then API, then component, then tests)

### Quality Gates (Must Pass)
1. **Build:** `npm run build` succeeds
2. **Lint:** `npm run lint` reports zero errors
3. **Types:** `npm run type-check` passes
4. **Tests:** `npm test` all pass, coverage >= 80%
5. **Format:** `npm run format:check` passes

### Implementation Process
1. Create branch: `feature/[feature-name]`
2. Implement in order from design doc
3. Run quality gates after each logical step
4. If gate fails, fix before proceeding
5. Final commit: update documentation if needed

### Commit Message Format
```
type(scope): description

- Detail 1
- Detail 2

Refs: WP-[ID], ADR-[ID]
```

Types: feat, fix, refactor, test, docs
```

---

## Step 5: Create Design Request Bead

Using the loyalty points work package from L2:

```bash
cd ~/my-city
bd create "Design: Loyalty Points Implementation" \
  --description "$(cat <<'EOF'
Create an implementation plan for the loyalty points feature.

Inputs:
- Work Package: work-packages/loyalty-points-system.md
- ADR: docs/adr/0001-loyalty-points-storage.md

Requirements:
1. Define file structure matching project conventions
2. Specify all TypeScript interfaces
3. Plan test coverage strategy
4. Identify integration points with existing code

Output: design-docs/loyalty-points-implementation.md
EOF
)" \
  --depends-on [planner-bead-id] \
  --depends-on [architect-bead-id]
```

Note bead ID (e.g., `my-city-design456`).

---

## Step 6: Sling to Designer

```bash
gc sling designer my-city-design456
gc watch designer
```

Review output:

```bash
cat ~/path/to/repo/design-docs/loyalty-points-implementation.md
```

**Verify:**
- [ ] File structure clear
- [ ] All interfaces defined
- [ ] Test plan comprehensive
- [ ] References work package + ADR

---

## Step 7: Create Implementation Bead

```bash
bd create "Implement: Loyalty Points Feature" \
  --description "$(cat <<'EOF'
Implement the loyalty points feature following the design plan.

Inputs:
- Design Doc: design-docs/loyalty-points-implementation.md
- Work Package: work-packages/loyalty-points-system.md
- ADR: docs/adr/0001-loyalty-points-storage.md

Requirements:
1. Follow file structure exactly
2. Implement all specified interfaces
3. Write tests per test plan
4. Pass all quality gates before marking complete

Create feature branch and implement incrementally.
EOF
)" \
  --depends-on my-city-design456
```

Note bead ID (e.g., `my-city-impl789`).

---

## Step 8: Sling to Coder

```bash
gc sling coder my-city-impl789
gc watch coder
```

This will take longer. The Coder agent will:
1. Create feature branch
2. Implement code incrementally
3. Write tests
4. Run quality gates
5. Commit when complete

---

## Step 9: Review Implementation

```bash
cd ~/path/to/repo
git log feature/loyalty-points --oneline  # See commits
git diff main...feature/loyalty-points    # See all changes
```

**Run quality gates manually:**

```bash
npm run build
npm run lint
npm run type-check
npm test
```

**All must pass for exit criteria.**

---

## Step 10: Create PR

```bash
gh pr create \
  --title "feat: Add loyalty points system" \
  --body "$(cat <<'EOF'
## Overview
Implements loyalty points feature per work package WP-2026-04-07-loyalty-points.

## References
- Work Package: work-packages/loyalty-points-system.md
- ADR: docs/adr/0001-loyalty-points-storage.md  
- Design: design-docs/loyalty-points-implementation.md

## Implementation
- Added LoyaltyPoints types and interfaces
- Implemented points API layer
- Built UI components for points display
- Added comprehensive test coverage (85%)

## Testing
All quality gates pass:
- ✅ Build succeeds
- ✅ Lint clean
- ✅ Types pass
- ✅ Tests pass (85% coverage)
- ✅ Format check passes

## Screenshots
[If applicable]
EOF
)"
```

Mark bead complete:

```bash
bd close my-city-impl789 --comment "Implementation complete, PR created"
```

---

## Recommended Prompts

### For Designer Agent
```
Create an implementation plan for [feature name].

Read these artifacts:
1. [Work package path]
2. [ADR path]

Your plan must include:
1. Complete file structure
2. All TypeScript interfaces
3. Component specifications with props
4. Comprehensive test plan
5. Implementation order

Follow the template in AGENTS.md exactly.
```

### For Coder Agent
```
Implement [feature name] following the design plan.

Design Doc: [path]

Create a feature branch and implement incrementally:
1. Types and interfaces
2. API layer
3. UI components
4. Tests

Run quality gates after each step. Only commit when gates pass.
```

---

## Evaluation Rubric

| Criterion | Points | Scoring |
|-----------|--------|---------|
| **Design Doc Completeness** | 25 pts | File structure, interfaces, test plan, implementation order all present |
| **Code Quality** | 30 pts | Follows design, passes all gates, clean commits |
| **Test Coverage** | 25 pts | >= 80% coverage, tests match plan |
| **Config Discipline** | 20 pts | Iterations via AGENTS.md, no manual code fixes |

**Total:** 100 points

---

## Exit Criteria

✅ Design doc committed  
✅ Implementation complete on feature branch  
✅ All quality gates pass  
✅ Test coverage >= 80%  
✅ PR created  
✅ All beads closed  

---

## Common Issues & Solutions

### Issue: Designer produces vague specifications
**Solution:** Add to AGENTS.md: "All interfaces must include JSDoc comments. Component specs must list all props with types."

### Issue: Coder skips tests
**Solution:** Add to AGENTS.md: "Tests are REQUIRED. Gate check: run `npm test -- --coverage` and verify >= 80% before final commit."

### Issue: Code doesn't match design
**Solution:** Add to AGENTS.md Coder section: "Follow design doc file structure exactly. Any deviation must be documented with rationale."

### Issue: Quality gates fail repeatedly
**Solution:** Strengthen gate requirements in AGENTS.md. Add specific commands to run and pass thresholds.

---

## Next Steps

After L3, your factory can:
- ✅ Plan features (Planner)
- ✅ Make architectural decisions (Architect)
- ✅ Design implementations (Designer)
- ✅ Write code and tests (Coder)

In **L4**, you'll add Reviewer + DevOps agents to complete the pipeline with quality assurance and deployment automation.
