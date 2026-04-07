# L1 · Build a Structured Development Loop

> **Goal:** Create your first Gas City agent configuration (AGENTS.md) that drives consistent, repeatable behavior for implementing features—no manual prompting required after initial setup.

| | |
|---|---|
| **Day** | Day 1 |
| **Time** | 11:30 - 12:30 |
| **Type** | LAB |
| **Deliverable** | Working AGENTS.md file + feature implementation |

---

## What You'll Build

```
User story in backlog
      ↓
Agent reads AGENTS.md spec
      ↓
Agent implements feature autonomously
      ↓
Code passes quality gates (lint, tests)
      ↓
Decision log records what was learned
```

**The Config Discipline:** When the agent produces wrong output, you update AGENTS.md and re-run—NOT type a correction into the chat.

---

## Prerequisites

✅ Complete W1 (AI Workflow Card)  
✅ Gas City installed and city initialized  
✅ Project repository added as a rig  
✅ Coding agent configured in city.toml

---

## Step 1: Create Your AGENTS.md Spec File

Navigate to your project repository (rig):

```bash
cd ~/path/to/your-repo
```

Create `AGENTS.md` using this template:

```markdown
# Agent Specification

## Role
You are a feature implementation agent for [PROJECT NAME]. Your job is to take user stories from the backlog and implement them with production-quality code.

## Iteration Rule
- Read the user story completely before starting
- Break implementation into logical commits
- Run tests after each significant change
- If tests fail, analyze the failure and fix before proceeding

## Quality Gates
All code must pass before considering the feature complete:
1. **Linting:** No lint errors or warnings
2. **Tests:** All existing tests pass + new tests for new functionality
3. **Type checking:** No type errors (if applicable)
4. **Build:** Project builds without errors

## Decision Log
Record significant implementation decisions in DECISIONS.md:
- What alternative approaches were considered?
- Why was this approach chosen?
- What tradeoffs were made?

## Output Format
- Commit messages follow: `type(scope): description`
- PR descriptions include: problem, solution, testing approach
- Code comments explain WHY, not WHAT
```

**Save this as `AGENTS.md` in your repository root.**

---

## Step 2: Pick a Test Story

Choose ONE feature from your project backlog. Keep it small for this first test.

**Example stories (Fired Up Pizza reference project):**
- "Show order total in cart"
- "Add 'Remove Item' button to cart"
- "Display estimated delivery time"

**For your project:**
Pick something that takes 15-30 minutes to implement manually.

**Write it clearly:**
```markdown
# User Story: [Title]

**As a** [user type]  
**I want** [goal]  
**So that** [benefit]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Notes
[Any constraints, APIs to use, styling requirements, etc.]
```

---

## Step 3: Create a Bead for the Story

In Gas City, work items are tracked as "beads". Create one for your story:

```bash
cd ~/my-city
bd create "Implement: [Your Story Title]" \
  --description "$(cat <<'EOF'
[Paste your user story here]
EOF
)"
```

This returns a bead ID like `my-city-abc123`.

---

## Step 4: Sling the Bead to Your Agent

Tell Gas City to assign this work to your agent:

```bash
gc sling dev-agent my-city-abc123
```

Where `dev-agent` is the agent name from your `city.toml`.

**What happens:**
1. Gas City starts your agent in a tmux session
2. Agent reads AGENTS.md for behavior rules
3. Agent reads the bead description (your user story)
4. Agent implements the feature

---

## Step 5: Monitor Agent Progress

Watch your agent work in real-time:

```bash
gc watch dev-agent
```

Press `Ctrl+C` to stop watching (agent keeps running).

**Check current status:**
```bash
gc status
bd show my-city-abc123
```

---

## Step 6: Review Agent Output

When the agent finishes (or if it gets stuck), check what it did:

```bash
cd ~/path/to/your-repo
git log -3 --oneline     # Recent commits
git diff HEAD~1          # Changes in last commit
```

**Run quality gates manually:**
```bash
npm run lint              # or your linting command
npm test                  # or your test command
npm run build             # or your build command
```

---

## Step 7: Iterate on AGENTS.md (If Needed)

**If quality gates fail or agent behavior was wrong:**

1. **Don't manually fix the code**
2. **Update AGENTS.md** with more specific guidance
3. **Reset the repository** to before agent ran
4. **Re-sling the bead** to try again

Example improvements to AGENTS.md:
```markdown
## Quality Gates
...
5. **Accessibility:** All interactive elements have ARIA labels
6. **Performance:** No console warnings in browser

## Implementation Guidelines
- Use TypeScript for all new files
- Follow existing file structure in src/components/
- Import utilities from src/utils/, never re-implement
```

**Goal:** <= 3 attempts to get a passing implementation

---

## Step 8: Document Your Decision Log

Create `DECISIONS.md` in your repository:

```markdown
# Implementation Decisions

## [YYYY-MM-DD] [Feature Name]

### Problem
[What was the user story? What challenge did it present?]

### Approaches Considered
1. **Option A:** [Description] - Rejected because [reason]
2. **Option B:** [Description] - Chosen because [reason]

### Implementation Details
- Used [library/pattern/approach] for [reason]
- Avoided [alternative] due to [tradeoff]

### Lessons Learned
- AGENTS.md needed refinement: [specific change made]
- Next time, would [improvement]

### Metrics
- Attempts to passing: [1-3]
- Agent runtime: [X minutes]
```

---

## Recommended Prompts

### Initial Agent Interaction (via bead description)
```
Implement the feature described below following all guidelines in AGENTS.md.

[User story with acceptance criteria]

Before starting:
1. Read AGENTS.md completely
2. Understand all quality gates
3. Plan your implementation approach

After implementation:
1. Run all quality gates
2. Record decision in DECISIONS.md
3. Commit with descriptive message
```

### If Agent Gets Stuck (via gc sling or manual prompt)
```
The previous attempt failed quality gates. Review the errors:

[Paste error output]

Analyze what went wrong, update your approach, and retry.
Ensure you're following all AGENTS.md guidelines.
```

### When Updating AGENTS.md Between Runs
```
I've updated AGENTS.md with additional guidance:
- [Specific change 1]
- [Specific change 2]

Re-read the spec and retry the implementation from scratch.
```

---

## Evaluation Rubric

| Criterion | Points | Scoring |
|-----------|--------|---------|
| **AGENTS.md Completeness** | 25 pts | All 4 sections (Role, Iteration Rule, Quality Gates, Decision Log) present and specific to your project |
| **Runs to Passing** | 30 pts | 1 run = 30pts, 2 runs = 20pts, 3 runs = 10pts, >3 or manual fix = 0pts |
| **Decision Log Quality** | 25 pts | Documents what changed between runs, why, and lessons learned |
| **Quality Gates Pass** | 20 pts | Binary: All gates pass = 20pts, any fail = 0pts |

**Total:** 100 points

**Pod Ranking:** Sum scores across all 5 members. Highest total wins.

---

## Exit Criteria

✅ AGENTS.md committed to repository  
✅ Feature implementation passes all quality gates  
✅ DECISIONS.md has >= 1 entry documenting this lab  
✅ Bead marked complete in Gas City (`bd close my-city-abc123`)

---

## Common Issues & Solutions

### Issue: Agent ignores AGENTS.md
**Solution:** Ensure AGENTS.md is in repository root. Check agent logs with `gc watch dev-agent`.

### Issue: Quality gates fail repeatedly
**Solution:** Add more specific guidelines to AGENTS.md Quality Gates section. Be explicit about tools/commands to run.

### Issue: Agent takes too long
**Solution:** Break story into smaller pieces. Aim for 15-30 min implementations.

### Issue: Can't find agent in Gas City
**Solution:** Run `gc status` to verify agent name. Ensure `dir` in city.toml matches rig name from `gc rig list`.

---

## Next Steps

After completing L1, you'll have:
- ✅ A working agent configuration pattern
- ✅ Experience with the config-driven discipline
- ✅ A baseline for building more complex agent systems

In **L2**, you'll add specialized roles (Planner + Architect) that work together via Gas City coordination.
