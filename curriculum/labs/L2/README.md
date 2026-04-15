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

✅ L1 complete (`CLAUDE.md` pattern established, first feature slung)  
✅ W2 complete (6-agent factory design + handoff contracts)  
✅ Gas City running with your project rig  
✅ `docs/PROJECT_MANIFEST.md` filled in with tech stack, conventions, success criteria

---

## Gas City Capabilities Used This Lab

| Command | What it does | Used in step |
|---------|--------------|--------------|
| `gc rig add <repo> --include packs/<agent>` | Register a pack with your rig — gives the named agent its role-specific prompt, overlay, and hooks | Steps 1, 5 |
| `gc restart` | Reload city.toml and pack config | Steps 3, 7 |
| `gc status` | Verify new agents appear | Steps 3, 7 |
| `bd create --depends-on` | Create a bead that blocks until a prerequisite bead closes | Step 10 |
| `gc sling planner <bead>` | Dispatch to the Planner agent | Step 8 |
| `gc sling architect <bead>` | Dispatch to the Architect agent | Step 11 |
| `actual adr-bot` | (Optional) seed tailored industry ADRs into `CLAUDE.md` before your Architect runs | Step 6 |

---

## Walkthrough: Install the Planner and Architect Packs

Unlike L1 (where `dev-agent` had no pack), this lab uses Gas City's shipped packs for Planner and Architect. Each pack contains:

```
packs/planner/
  pack.toml                  ← metadata, agent declaration, idle_timeout
  prompts/planner.md         ← the role prompt (Role, Inputs, Output Format, Quality Gate, Process)
  overlays/default/          ← .claude/settings.json + environment overrides
```

Read these files **before** installing — they're your "textbook" for what the agent will actually do:

- [`packs/planner/pack.toml`](../../../packs/planner/pack.toml) — declares the `planner` agent, `idle_timeout = "1h"`, its prompt template path
- [`packs/planner/prompts/planner.md`](../../../packs/planner/prompts/planner.md) — the agent's standing instructions: produces `work-packages/<slug>.md` in the six-section format
- [`packs/architect/pack.toml`](../../../packs/architect/pack.toml) and [`packs/architect/prompts/architect.md`](../../../packs/architect/prompts/architect.md) — same shape for Architect, producing ADRs at `docs/adr/NNNN-<slug>.md`

Install both packs in one command each:

```bash
cd ~/my-city

# From inside the software-factory-intensive clone:
gc rig add ~/path/to/your-repo --include /path/to/software-factory-intensive/packs/planner
gc rig add ~/path/to/your-repo --include /path/to/software-factory-intensive/packs/architect

gc restart
gc status   # you should see `planner` and `architect` listed
```

`gc rig add --include` is additive — running it twice with the same pack is safe. The pack's `[[agent]]` block from `pack.toml` is merged into your rig's effective `city.toml`.

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

## Step 4b: Seed Industry ADRs with `actual adr-bot` (Recommended)

Before your Architect writes any ADR, give it a curated baseline to build on. [Actual AI's `actual` CLI](https://github.com/actual-software/actual-cli) ships an `adr-bot` command that analyzes your repo, pulls relevant Architecture Decision Records, tailors them to your specific codebase via an LLM, and writes the result into `CLAUDE.md` (or `AGENTS.md`).

Why this matters for the Architect agent:

- **Stops re-deciding solved problems.** Industry patterns (e.g. "Use `serde_derive`'s `#[serde(deny_unknown_fields)]` on contract structs", "Prefer structured serialization over `serde_json::Value`") get seeded into `CLAUDE.md` automatically. Your Architect's new ADRs then *extend* this baseline instead of re-litigating every language-level decision.
- **Upgrades the quality bar for your own ADRs.** The Architect's job shrinks from "survey all options for a common pattern" to "document the project-specific decision that goes beyond the baseline."
- **Free, no account required.** The Actual API is free; the tailoring step uses your already-configured coding-agent runner (Claude Code, Anthropic API, etc.).

Install and run:

```bash
brew install actual-software/actual/actual

cd ~/path/to/your-repo
actual adr-bot --dry-run        # preview: see which ADRs will be tailored
actual adr-bot                  # write into CLAUDE.md

git add CLAUDE.md
git commit -m "chore: seed tailored industry ADRs via actual adr-bot"
```

Then update `packs/architect/prompts/architect.md` (or the Architect section of `CLAUDE.md`) to make the dependency explicit:

```markdown
## Architect Agent

### Inputs
1. The bead's feature description
2. `docs/PROJECT_MANIFEST.md` — the project's source of truth
3. **The `# Tailored ADRs` section of `CLAUDE.md`** — industry baselines seeded via `actual adr-bot`.
   When making a decision, first check whether a tailored ADR already covers it. Only write a
   new ADR under `docs/adr/` if the decision extends, overrides, or is not represented in the
   tailored set.

### Output Rules
- New ADRs reference the tailored ADR they extend, e.g. "Extends CLAUDE.md §serde-deny-unknown-fields"
- If you choose to override a tailored ADR, you MUST explain why in the Consequences section
- Do not duplicate baselines; reference them
```

Re-run `actual adr-bot` whenever you add a new area of the codebase — its output is incremental and idempotent.

---

## Step 5: Create Test Feature Request

If you connected an issue tracker in L1 using [`packs/workshop`](../../../packs/workshop/), your tickets may already be synced as beads. Check with `bd list`. You can also sync on demand:

```bash
gc workshop sync-all        # All connected trackers
bd jira sync --pull          # Jira only
bd linear sync --pull        # Linear only
bd github sync               # GitHub Issues
```

Otherwise, create a bead manually for a feature that needs planning + architecture:

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

## How the Reference Project Demonstrates L2

Spend 5 minutes scanning the Fired Up Pizza reference to see the finished shape of this lab's output:

- [`reference-project/fired-up-pizza/work-packages/`](../../../reference-project/fired-up-pizza/work-packages/) — after the Planner runs against `tickets.md`, work packages land here (e.g. `menu-display.md`). The directory is empty in the repo's default state — the factory populates it.
- [`reference-project/fired-up-pizza/docs/adr/`](../../../reference-project/fired-up-pizza/docs/adr/) — ADR output from the Architect. Each file is `NNNN-<slug>.md` with MADR structure.
- [`reference-project/fired-up-pizza/CLAUDE.md`](../../../reference-project/fired-up-pizza/CLAUDE.md) — the reference manifest defining pipeline order, directory conventions, and cross-references. Pay attention to how it phrases the handoff: "Planner → `work-packages/<slug>.md`" and "Architect → `docs/adr/NNNN-<slug>.md`" are declared in one place. This is the discipline your `CLAUDE.md` is evolving toward.
- [`packs/fired-up-pizza/`](../../../packs/fired-up-pizza/) — the composite pack bundling all 6 agents for the reference project. L2 onwards, each individual pack you install corresponds to one of its `includes = ["../planner", "../architect", ...]`.

Compare your `work-packages/loyalty-points-system.md` to what you'd expect for `reference-project/fired-up-pizza/tickets.md` ticket FUP-1. The shape should be identical: Goal, User Stories, Acceptance Criteria, Dependencies, Test Cases, Scope Boundary. If yours is missing sections, that's a pack customization gap — update `packs/planner/prompts/planner.md` to enforce the missing section as a Quality Gate, then re-sling.

---

## Working Against the Skeleton (`my-factory/`)

If you're using the shipped skeleton as your factory, the artifacts land in exactly these paths:

```
my-factory/
  work-packages/loyalty-points-system.md       ← created by Step 7
  docs/adr/0001-loyalty-points-storage.md       ← created by Step 10
```

Both directories exist as empty scaffolds in the skeleton (see `my-factory/work-packages/.gitkeep` and `my-factory/docs/adr/.gitkeep`) so Gas City's orders don't fail on missing directories when you run L3/L4.

If the Planner writes to the wrong path (e.g. `plan/loyalty-points.md` instead of `work-packages/loyalty-points-system.md`), the fix is not to move the file — it's to add a rule to `packs/planner/prompts/planner.md`:

```markdown
### Output Location
Save work packages to: `work-packages/<feature-slug>.md` — never anywhere else.
The slug is derived from the bead title in kebab-case.
```

Re-sling. Observe the difference.

---

## Next Steps

After L2, you have two specialized agents working together:
- ✅ Planner breaks down work
- ✅ Architect makes technical decisions
- ✅ Artifacts reference each other

In **L3**, you'll add Designer + Coder agents that consume these artifacts and generate actual implementation code.
