# L2 · Deploy Planner + Architect Agents

> **Goal:** Set up specialized Planner and Architect agents in Gas City that work together to break down features and make architectural decisions—producing structured work packages and ADRs (Architecture Decision Records).

| | |
|---|---|
| **Day** | Day 1 |
| **Time** | 2:15 - 3:30 |
| **Type** | LAB |
| **Deliverable** | Working Planner + Architect agents + sample artifacts |

---

## What You'll Build

```
Feature request arrives
      ↓
Planner Agent analyzes requirements
      ↓
Produces: Work Package (goals, stories, acceptance criteria)
      ↓
Architect Agent reviews work package
      ↓
Produces: ADR (architectural decision with trade-offs)
      ↓
Both artifacts committed to repo with cross-references
```

---

## Prerequisites

✅ L1 complete (AGENTS.md pattern established)  
✅ W2 complete (6-agent factory design)  
✅ Gas City running with your project rig  

---

## Step 1: Add Planner Agent to city.toml

Edit `~/my-city/city.toml` and add a Planner agent:

```toml
[[agent]]
name = "planner"
dir = "your-repo-name"
provider = "claude"
idle_timeout = "2h"
role = "planner"           # Optional metadata
```

Restart Gas City to pick up the new agent:

```bash
gc restart
gc status  # Verify planner agent appears
```

---

## Step 2: Create Planner AGENTS.md

In your repository, create or update `AGENTS.md` to add Planner-specific guidance:

```markdown
# Agent Specifications

## Planner Agent

### Role
You are a product planning agent. You break down feature requests into structured work packages that other agents can execute.

### Responsibilities
1. Analyze feature requests for completeness
2. Break features into logical user stories
3. Define clear acceptance criteria for each story
4. Identify dependencies and ordering constraints
5. Estimate complexity (S/M/L/XL)

### Work Package Template
Every work package you create must follow this structure:

\`\`\`markdown
# Work Package: [Feature Name]

**ID:** WP-[YYYY-MM-DD]-[short-id]  
**Status:** Draft  
**Created:** [Date]

## Goal
[One sentence: what does this feature achieve?]

## User Stories

### Story 1: [Title]
**As a** [user type]  
**I want** [capability]  
**So that** [benefit]

**Acceptance Criteria:**
- [ ] AC 1
- [ ] AC 2
- [ ] AC 3

**Complexity:** [S/M/L/XL]

### Story 2: [Title]
...

## Dependencies
- **Blocker:** [What must exist before this can start?]
- **Parallel:** [What can be built at the same time?]
- **Downstream:** [What will depend on this?]

## Architectural Considerations
[Flag any decisions that need Architect review]

## Estimated Timeline
[Based on complexity, how long for full implementation?]
\`\`\`

### Output Location
Save work packages to: `work-packages/[feature-name].md`

### Quality Standards
- All user stories must have measurable acceptance criteria
- No vague language ("improve", "better", "enhance")
- Dependencies must reference specific components or stories
- Complexity estimates justified by scope
```

---

## Step 3: Add Architect Agent to city.toml

```toml
[[agent]]
name = "architect"
dir = "your-repo-name"
provider = "claude"
idle_timeout = "2h"
role = "architect"
```

Restart Gas City:

```bash
gc restart
gc status  # Verify architect agent appears
```

---

## Step 4: Add Architect Guidance to AGENTS.md

Update `AGENTS.md` with Architect specs:

```markdown
## Architect Agent

### Role
You are a software architecture agent. You review work packages and make architectural decisions, documenting them as ADRs (Architecture Decision Records).

### Responsibilities
1. Review work packages for architectural implications
2. Evaluate multiple implementation approaches
3. Document decisions with trade-off analysis
4. Consider: performance, maintainability, cost, complexity
5. Reference work packages explicitly

### ADR Template (MADR Format)
Use this structure for all architectural decisions:

\`\`\`markdown
# ADR-[NUMBER]: [Title]

**Status:** Proposed | Accepted | Deprecated | Superseded  
**Date:** [YYYY-MM-DD]  
**Work Package:** [Reference WP ID]

## Context
[What is the problem? What constraints exist? What are we trying to achieve?]

## Decision Drivers
- [Key factor 1]
- [Key factor 2]
- [Key factor 3]

## Considered Options
1. **Option A:** [Description]
2. **Option B:** [Description]
3. **Option C:** [Description]

## Decision
Chosen: **Option [X]**

### Rationale
[Why this option? What makes it better than alternatives?]

## Consequences

### Positive
- [Benefit 1]
- [Benefit 2]

### Negative
- [Trade-off 1]
- [Trade-off 2]

### Neutral
- [Impact that's neither clearly good nor bad]

## Validation
[How will we know this decision was correct? What metrics or signals?]

## References
- Work Package: [WP-ID]
- Related ADRs: [If any]
- External docs: [Links if relevant]
\`\`\`

### Output Location
Save ADRs to: `docs/adr/[NUMBER]-[short-title].md`

Start numbering at 0001.

### Quality Standards
- All four MADR sections required
- At least 3 options considered
- Trade-offs explicitly called out
- Work package referenced by ID
```

---

## Step 5: Create Test Feature Request

Create a bead for a feature that needs planning + architecture:

```bash
cd ~/my-city
bd create "Feature: Loyalty Points System" \
  --description "$(cat <<'EOF'
# Feature Request: Loyalty Points System

## Overview
Add a loyalty points system to Fired Up Pizza where customers earn points on purchases and can redeem them for discounts.

## Requirements
- Customers earn 1 point per $1 spent
- Points can be redeemed at checkout (100 points = $5 off)
- Points balance visible on order confirmation page
- Admin dashboard shows total points issued/redeemed

## Constraints
- Must integrate with existing order system
- Points balance must be accurate (no double-counting)
- Performance: adding points shouldn't slow checkout

## Open Questions
- Where to store points? User table? Separate ledger?
- How to handle refunds?
- Expiration policy?
EOF
)"
```

Note the bead ID returned (e.g., `my-city-xyz789`).

---

## Step 6: Sling to Planner Agent

```bash
gc sling planner my-city-xyz789
```

**Monitor progress:**
```bash
gc watch planner
```

The Planner should create: `work-packages/loyalty-points-system.md`

---

## Step 7: Review Planner Output

```bash
cd ~/path/to/your-repo
cat work-packages/loyalty-points-system.md
```

**Check for:**
- [ ] Clear goal statement
- [ ] 3-5 user stories with acceptance criteria
- [ ] Dependencies identified
- [ ] Architectural considerations flagged

**If output is incomplete:**
1. Update AGENTS.md Planner section with more specific guidance
2. Delete the work package file
3. Re-sling the bead: `gc sling planner my-city-xyz789`

---

## Step 8: Create Architecture Request Bead

Now ask the Architect to review the work package:

```bash
bd create "Architecture Review: Loyalty Points Storage" \
  --description "$(cat <<'EOF'
Review the work package at work-packages/loyalty-points-system.md

Make an architectural decision about:
- How to store loyalty points (user table? separate service? ledger?)
- Trade-offs of each approach
- Impact on performance, data consistency, and future features

Produce an ADR documenting your decision.
EOF
)" \
  --depends-on my-city-xyz789    # Blocks on planner completing first
```

Note the new bead ID (e.g., `my-city-arch123`).

---

## Step 9: Sling to Architect Agent

```bash
gc sling architect my-city-arch123
```

**Monitor:**
```bash
gc watch architect
```

The Architect should create: `docs/adr/0001-loyalty-points-storage.md`

---

## Step 10: Verify Cross-References

Check that both artifacts reference each other:

**In work package:**
```markdown
## Architectural Decisions
See ADR-0001: Loyalty Points Storage Strategy
```

**In ADR:**
```markdown
**Work Package:** WP-2026-04-07-loyalty-points
```

**If cross-references missing:**
Update AGENTS.md to require explicit references, then re-run.

---

## Step 11: Commit Both Artifacts

```bash
git add work-packages/loyalty-points-system.md
git add docs/adr/0001-loyalty-points-storage.md
git commit -m "feat(planning): add loyalty points work package and ADR"
git push origin main
```

Mark beads complete:

```bash
bd close my-city-xyz789 --comment "Work package completed"
bd close my-city-arch123 --comment "ADR completed"
```

---

## Recommended Prompts

### For Planner Agent (via bead description)
```
Analyze this feature request and create a work package following the template in AGENTS.md.

[Feature request details]

Requirements:
1. Break into 3-5 user stories
2. Each story needs measurable acceptance criteria
3. Identify all dependencies
4. Flag architectural decisions needed
5. Estimate complexity for each story

Output: work-packages/[feature-name].md
```

### For Architect Agent (via bead description)
```
Review the work package at: [path to work package]

Create an ADR addressing: [specific architectural question]

Requirements:
1. Evaluate at least 3 implementation options
2. Document trade-offs explicitly
3. Reference work package by ID
4. Follow MADR template in AGENTS.md

Output: docs/adr/[next-number]-[short-title].md
```

### If Agents Miss Requirements
```
The [Planner/Architect] output is missing [specific requirement].

Review AGENTS.md section for [role] and ensure you're following all template requirements.

Regenerate the artifact with all required sections.
```

---

## Evaluation Rubric

| Criterion | Points | Scoring |
|-----------|--------|---------|
| **Work Package Completeness** | 30 pts | All sections present (goal, stories with ACs, dependencies, architectural flags) |
| **ADR Quality** | 30 pts | All MADR sections, 3+ options evaluated, trade-offs explicit |
| **Cross-Reference Integrity** | 20 pts | Both artifacts reference each other correctly |
| **Config Discipline** | 20 pts | All iterations via AGENTS.md updates, no ad-hoc prompting |

**Total:** 100 points

---

## Exit Criteria

✅ Both artifacts committed to repository  
✅ Work package has 3+ user stories with clear ACs  
✅ ADR has 3+ options with trade-off analysis  
✅ Cross-references between artifacts valid  
✅ Both beads marked closed in Gas City  

---

## Common Issues & Solutions

### Issue: Planner produces vague acceptance criteria
**Solution:** Add to AGENTS.md: "Acceptance criteria must be testable. Bad: 'works well'. Good: 'loads in <200ms', 'validates email format'."

### Issue: Architect only considers one option
**Solution:** Add to AGENTS.md: "You MUST evaluate at least 3 distinct approaches. If only 2 are viable, explain why a third was eliminated."

### Issue: No cross-references between artifacts
**Solution:** Add explicit requirements to both agent specs: "Reference the [work package/ADR] by its full ID in the [Architectural Considerations/Work Package] section."

### Issue: Agents hallucinate project details
**Solution:** Add to AGENTS.md: "Only use information from: the feature request, existing codebase, and this AGENTS.md file. Never assume features or infrastructure that aren't documented."

---

## Next Steps

After L2, you have two specialized agents working together:
- ✅ Planner breaks down work
- ✅ Architect makes technical decisions
- ✅ Artifacts reference each other

In **L3**, you'll add Designer + Coder agents that consume these artifacts and generate actual implementation code.
