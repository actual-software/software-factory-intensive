# L2 · Deploy Planner + Architect Agents

> **What you'll build:** Two specialized AI agents managed by Gas City — a Planner that breaks feature requests into structured work packages, and an Architect that reviews those packages and produces Architecture Decision Records (ADRs). By the end of this lab, you'll sling a feature request through both agents and commit the artifacts they produce.

| | |
|---|---|
| **Estimated duration** | ~75 minutes |
| **Type** | LAB |
| **Deliverable** | Working Planner + Architect agents, one work package, one ADR, cross-referenced and committed |

---

## Session workspace note

* **Pack locations (shipped):** `../../../packs/planner/` and `../../../packs/architect/`. Prompt templates are `packs/<agent>/prompts/<agent>.md.tmpl` (the `.tmpl` suffix is the Gas City template extension).
* **Gas City workspace:** `../../../my-factory/` — this is where `city.toml` lives. Earlier drafts of this README used `~/my-city/`; treat any remaining `~/my-city` reference as pointing at `my-factory/`.
* **Your deliverables this session:** `notes.md` + any customised pack copies go in `../../../activities/labs/L2/`. The work package + ADR themselves are produced by the agents into your project rig, not this folder.
* **Wiring the packs:** at the end of the session, add the following to `includes` in `../../../my-factory/city.toml`:
  ```toml
  includes = ["../packs/planner", "../packs/architect"]
  ```
  or use `../activities/labs/L2/packs/<agent>` if you're running customised copies. See [`activities/labs/L2/README.md`](../../../activities/labs/L2/README.md) for the full pattern.

If a pack edit breaks your factory, swap back to the shipped `../packs/<name>` path in `city.toml` and `gc service restart` to continue.

---

## Architecture Diagram

```
                    ┌───────────────────────────┐
                    │     Feature Request        │
                    │  (bead in Gas City)         │
                    └─────────────┬─────────────┘
                                  │
                                  ▼
                    ┌───────────────────────────┐
                    │      PLANNER AGENT         │
                    │                            │
                    │  Reads:                     │
                    │    • bead description       │
                    │    • docs/PROJECT_MANIFEST  │
                    │    • packs/planner/prompts  │
                    │                            │
                    │  Produces:                  │
                    │    work-packages/<slug>.md  │───► Goal, Stories, ACs,
                    │                            │     Dependencies, Tests,
                    └─────────────┬─────────────┘     Scope Boundary
                                  │
                    ┌─────────────▼─────────────┐
                    │     ARCHITECT AGENT         │
                    │                            │
                    │  Reads:                     │
                    │    • work package           │
                    │    • docs/PROJECT_MANIFEST  │
                    │    • existing ADRs          │
                    │    • CLAUDE.md (tailored)   │
                    │                            │
                    │  Produces:                  │
                    │    docs/adr/NNNN-<slug>.md  │───► Context, Options,
                    │                            │     Decision, Consequences,
                    └───────────────────────────┘     References
```

---

## Prerequisites

Before starting this lab, verify each of these:

| Prerequisite | How to verify | If it's missing |
|-------------|---------------|-----------------|
| L1 complete | `ls ~/path/to/your-repo/CLAUDE.md` → file exists | Go back and complete L1. This lab cannot work without it. |
| W2 complete | You have a factory design doc with 6 agent roles mapped to your project | Skim the [W2 README](../../workshops/W2/) and sketch the roles — 10 min max |
| Gas City running | `gc status` → shows at least `dev-agent` from L1 | From `my-factory/`: `gc register .` then `gc rig add ../../path/to/your-repo` |
| Project Manifest | `cat ~/path/to/your-repo/docs/PROJECT_MANIFEST.md` → filled in | Copy from [`curriculum/PROJECT_MANIFEST_TEMPLATE.md`](../../PROJECT_MANIFEST_TEMPLATE.md) and fill in tech stack, conventions, domain model |
| Skeleton scaffold | `ls ~/path/to/your-repo/work-packages/` → directory exists | `# (the participant's repo already lives under a `my-factory/` workspace — skeleton lives there)` |

---

## The Use Case: Loyalty Points for Fired Up Pizza

Throughout this lab, we use a single running example: **adding a loyalty points system to Fired Up Pizza** (or your own project's equivalent feature). This feature is complex enough to require both planning *and* an architectural decision, but small enough to complete in 75 minutes.

If you're working against your own project, substitute your own feature — but make sure it has at least one open technical question the Architect needs to resolve (e.g., "where to store this data?", "which API pattern to use?", "build vs. buy for this component?").

---

## Part 0: Read the Shipped Packs (~5 min)

Before installing anything, read what you're about to install. Each pack is a folder with three things: a `pack.toml` (metadata), a prompt file (the agent's instructions), and an overlay directory (environment overrides).

### Step 1: Open the Planner Pack

Open this file in your editor and read it end-to-end — it's 65 lines:

[`packs/planner/prompts/planner.md.tmpl`](../../../packs/planner/prompts/planner.md.tmpl)

You should see six sections:

```
# Planner Agent

## Role              ← "You receive feature requests and break them into
                        structured work packages..."

## Inputs            ← bead description + docs/PROJECT_MANIFEST.md

## Output Format     ← work-packages/<feature-slug>.md with 6 sections:
                        Goal, User Stories, Acceptance Criteria,
                        Dependencies, Test Cases, Scope Boundary

## Quality Gate      ← 4 rules: every story has an AC, 2+ test cases,
                        explicit scope boundary, no ambiguous terms

## Process           ← 6 steps: read bead → read manifest → produce file
                        → commit on branch → update bead → mark ready

## Config Discipline ← "the fix is updating this file — not ad-hoc
                        re-prompting"
```

**What's happening here:** This prompt file is the Planner's entire personality. When you `gc sling planner <bead>`, Gas City starts a Claude session, loads this prompt as the system message, and hands the bead's description as the user message. Everything the Planner does comes from this file and `docs/PROJECT_MANIFEST.md`. Nothing else.

### Step 2: Open the Planner Pack Metadata

[`packs/planner/pack.toml`](../../../packs/planner/pack.toml)

```toml
[pack]
name = "planner"
schema = 1
description = "Planner agent — breaks feature requests into structured work packages"

[[agent]]
name = "planner"
scope = "rig"
prompt_template = "prompts/planner.md"
overlay_dir = "overlays/default"
nudge = "Check your hook for new feature requests to plan."
idle_timeout = "1h"
max_active_sessions = 1
```

**What's happening here:** The `[[agent]]` block is what gets merged into your city when you run `gc rig add --include`. `prompt_template` points to the prompt file you just read. `idle_timeout = "1h"` means the agent's tmux session shuts down after 1 hour of inactivity. `max_active_sessions = 1` means one bead at a time.

### Step 3: Open the Architect Pack

[`packs/architect/prompts/architect.md.tmpl`](../../../packs/architect/prompts/architect.md.tmpl)

Same six-section structure as the Planner, but different role:

```
## Role              ← "You receive work packages and produce ADRs..."

## Inputs            ← work-packages/<slug>.md + PROJECT_MANIFEST
                        + existing ADRs for consistency

## Output Format     ← docs/adr/NNNN-<decision-slug>.md using MADR:
                        Status, Context, Options Considered, Decision,
                        Consequences, References

## Quality Gate      ← 4 rules: all MADR sections present, 2+ options
                        with trade-offs, references work package by path,
                        consequences include at least one risk

## Process           ← 7 steps: read WP → read manifest → review existing
                        ADRs → produce ADR → cross-reference the WP →
                        commit → mark ready for Designer
```

Notice the key difference from the Planner: Step 5 says "Add a cross-reference to the work package (append ADR path to it)." This is the **handoff contract** — the Architect doesn't just produce its own artifact, it also back-links to the Planner's artifact. You designed this contract in W2.

### Step 4: Open the Architect Pack Metadata

[`packs/architect/pack.toml`](../../../packs/architect/pack.toml)

```toml
[pack]
name = "architect"
schema = 1
description = "Architect agent — produces ADRs and technical decisions from work packages"

[[agent]]
name = "architect"
scope = "rig"
prompt_template = "prompts/architect.md"
overlay_dir = "overlays/default"
nudge = "Check your hook for work packages needing architecture decisions."
idle_timeout = "1h"
max_active_sessions = 1
```

Same shape as the Planner's `pack.toml`. The only differences are `name`, `description`, `prompt_template`, and `nudge`. All agent packs follow this pattern — you'll see it again in L3 (Designer, Coder) and L4 (Reviewer, Deployer).

You're done reading. Now install.

---

## Part 1: Install the Planner Agent (~10 min)

### Step 1: Add the Planner Pack to Your Rig

```bash
cd my-factory
gc rig add ~/path/to/your-repo \
  --include /path/to/software-factory-intensive/packs/planner
```

You should see output like:

```
rig "your-repo" updated — added pack "planner"
```

**What's happening here:** `gc rig add --include` tells Gas City: "for this rig, also load the agent definition and prompt from the specified pack directory." The `[[agent]]` block from `packs/planner/pack.toml` is merged into your city's effective configuration. The prompt file at `packs/planner/prompts/planner.md.tmpl` becomes the system prompt for any session started by this agent.

### Step 2: Restart Gas City and Verify

```bash
gc restart
gc status
```

You should see:

```
NAME        STATE   LAST ACTIVITY   BEAD
dev-agent   idle    12m ago         --
planner     idle    --              --
```

If `planner` doesn't appear, check that the `--include` path was correct (absolute path, not relative). Run `gc rig list` to see what packs are registered.

### Step 3: Customize the Planner Prompt for Your Project

The shipped prompt is generic. You need to tailor two things for your project:

**a) Open `packs/planner/prompts/planner.md.tmpl` in your editor** (or copy it into your repo if you prefer local overrides).

**b) Update the Output Format section** with your project's naming convention. For example, if your project is Fired Up Pizza:

Find this line:
```markdown
Create a work package at `work-packages/<feature-slug>.md` with this structure:
```

It's already correct for the `my-factory/` skeleton. But if your project uses a different directory (e.g., `docs/plans/`), change it here. **The Planner will write to whatever path this line says.** If the path is wrong, the Architect won't find the artifact.

**c) Add a project-specific constraint** to the Quality Gate section. Append one rule that references your project's domain. For Fired Up Pizza:

```markdown
## Quality Gate

A work package is complete when:
1. Every user story has at least one acceptance criterion
2. At least two test cases are defined
3. Scope boundary is explicit
4. No ambiguous terms remain (quantify everything)
5. All prices must be in cents (not dollars) per project convention
```

For your project, replace rule 5 with something from your `docs/PROJECT_MANIFEST.md` conventions section.

### Step 4: Commit Your Customization

```bash
cd ~/path/to/your-repo
git checkout -b l2-planner-architect
git add -A
git commit -m "chore(planner): customize planner prompt for project conventions"
```

**Why commit now?** The diff between the shipped prompt and your customized version is the evidence of config discipline. If the Planner's output is wrong later, this diff tells you what you changed and what you might need to change next.

---

## Part 2: Install the Architect Agent (~10 min)

### Step 1: (Recommended) Seed Tailored Industry ADRs

Before the Architect writes any ADR, give it a curated baseline. [Actual AI's `actual` CLI](https://github.com/actual-software/actual-cli) analyzes your repo, fetches relevant Architecture Decision Records from a curated library, tailors them to your codebase via an LLM, and writes the result into `CLAUDE.md`.

```bash
brew install actual-software/actual/actual
```

Verify the install:

```bash
actual --version
```

You should see:

```
actual 0.x.x
```

Now preview what it would write:

```bash
cd ~/path/to/your-repo
actual adr-bot --dry-run
```

You should see output like:

```
Analyzing repository...
Found 12 relevant ADRs for your codebase
Tailoring to your project's TypeScript + React + SQLite stack...

Would write 8 tailored ADRs to CLAUDE.md:
  - Use conventional commits for all commit messages
  - Prefer explicit TypeScript types over inference at module boundaries
  - Use parameterized queries for all database access
  ...

Dry run complete. Run `actual adr-bot` to write.
```

If it looks reasonable, run it for real:

```bash
actual adr-bot
```

You should see:

```
Writing 8 tailored ADRs to CLAUDE.md...
Done. Review the changes with `git diff CLAUDE.md`.
```

Commit:

```bash
git add CLAUDE.md
git commit -m "chore: seed tailored industry ADRs via actual adr-bot"
```

**What's happening here:** The Actual API is free, no account needed. It looked at your repo's language, framework, dependencies, and file patterns, then fetched ADRs that match. Each one was rewritten to reference your project's specific conventions. Now when the Architect runs, it will read `CLAUDE.md` first and see these baselines. It only needs to write a *new* ADR when the decision isn't already covered.

**Skipping this step is fine.** Your Architect will just write every ADR from scratch. But seeding baselines means higher-quality first-run output.

### Step 2: Add the Architect Pack to Your Rig

```bash
cd my-factory
gc rig add ~/path/to/your-repo \
  --include /path/to/software-factory-intensive/packs/architect
```

You should see:

```
rig "your-repo" updated — added pack "architect"
```

### Step 3: Restart and Verify

```bash
gc restart
gc status
```

You should see:

```
NAME        STATE   LAST ACTIVITY   BEAD
dev-agent   idle    25m ago         --
planner     idle    --              --
architect   idle    --              --
```

Three agents. The first two stages of your factory pipeline are installed.

### Step 4: Customize the Architect Prompt

Open `packs/architect/prompts/architect.md.tmpl` and make two changes:

**a) Add `CLAUDE.md` to the Inputs section** (so the Architect reads tailored ADRs):

Find:

```markdown
## Inputs

- Work package from `work-packages/<feature-slug>.md`
- Project manifest (`docs/PROJECT_MANIFEST.md`)
- Existing ADRs in `docs/adr/` for consistency
```

Replace with:

```markdown
## Inputs

- Work package from `work-packages/<feature-slug>.md`
- Project manifest (`docs/PROJECT_MANIFEST.md`)
- Existing ADRs in `docs/adr/` for consistency
- Tailored ADR baselines in `CLAUDE.md` (if present) — check whether the
  decision you're about to make is already covered. Only write a new ADR
  if the decision extends, overrides, or is absent from the baselines.
```

**b) Add a project-specific constraint** to the Quality Gate. For Fired Up Pizza:

```markdown
## Quality Gate

An ADR is complete when:
1. All four MADR sections are present (Context, Options, Decision, Consequences)
2. At least two options were considered with trade-offs
3. The decision references the work package by path
4. Consequences include at least one risk
5. If this decision affects pricing, amounts must be in cents (per project convention)
```

### Step 5: Commit Your Customization

```bash
cd ~/path/to/your-repo
git add -A
git commit -m "chore(architect): customize architect prompt with tailored-ADR input"
```

---

## Part 3: Create and Run the Planner (~20 min)

Now the agents are installed. Time to give the Planner real work.

### Step 1: Write the Feature Request

You need a feature request that's complex enough to need both a Planner and an Architect. Here's the Loyalty Points example for Fired Up Pizza — **adapt this to your own project or use it verbatim if you're working against the reference project:**

```markdown
# Feature Request: Loyalty Points System

## Overview
Add a loyalty points system to Fired Up Pizza where customers earn
points on purchases and can redeem them for discounts.

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
```

Save this somewhere handy (clipboard, scratch file) — you'll paste it into the bead description next.

### Step 2: Create the Planner Bead

```bash
cd my-factory
bd create "Feature: Loyalty Points System" \
  --description "$(cat <<'EOF'
# Feature Request: Loyalty Points System

## Overview
Add a loyalty points system to Fired Up Pizza where customers earn
points on purchases and can redeem them for discounts.

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

You should see:

```
Created bead: my-factory-a1b2c3
```

Note this bead ID — you'll use it for the next several steps. Verify it exists:

```bash
bd list
```

You should see:

```
ID              TITLE                           STATUS   AGENT    CREATED
my-factory-a1b2c3  Feature: Loyalty Points System  open     --       just now
```

**What's happening here:** A bead is a work item in Gas City. It has a title, a markdown description, a status, and an optional dependency chain. The description is the first thing the agent reads when you sling the bead to it. The quality of this description directly determines the quality of the agent's output — just like a Jira ticket determines the quality of a human developer's output.

### Step 3: Sling the Bead to the Planner

```bash
gc sling planner my-factory-a1b2c3
```

You should see:

```
Slinging my-factory-a1b2c3 → planner
Session started: planner-a1b2c3 (tmux)
```

**What's happening here:** Gas City starts a tmux session, launches Claude Code inside your repo directory, loads `packs/planner/prompts/planner.md.tmpl` as the system prompt, and hands the bead's description as the task. The Planner agent is now working autonomously.

### Step 4: Watch the Planner Work

```bash
gc watch planner
```

You'll see the Claude Code session streaming in real-time. The Planner should:

1. Read `docs/PROJECT_MANIFEST.md` (you'll see it open the file)
2. Read the bead description (the feature request)
3. Start writing `work-packages/loyalty-points-system.md`
4. Commit the file on a feature branch

Press `Ctrl+b d` to detach from tmux (the agent keeps running). You can also monitor from another terminal:

```bash
gc events --follow    # Stream all city events
gc status             # Check agent state
bd show my-factory-a1b2c3  # Check bead progress
```

Wait until the Planner finishes (state returns to `idle` in `gc status`). This typically takes 2–5 minutes.

### Step 5: Review the Work Package

```bash
cd ~/path/to/your-repo
cat work-packages/loyalty-points-system.md
```

You should see a file with this structure (content will vary):

```markdown
# Work Package: Loyalty Points System

## Goal
Allow customers to earn points on purchases and redeem them for discounts,
increasing repeat business and customer retention.

## User Stories

### Story 1: Earn Points on Purchase
As a customer, I want to automatically earn 1 point per dollar spent,
so that my loyalty is rewarded.

Acceptance Criteria:
- [ ] Points are added to the customer's balance after order placement
- [ ] Points calculation uses order total in cents (1 point per 100 cents)
- [ ] Points are not awarded for cancelled or refunded orders

### Story 2: View Points Balance
As a customer, I want to see my points balance on the order confirmation
page, so that I know how many points I have.
...

## Dependencies
- Existing order system (src/api/orders.ts)
- Customer authentication (src/auth/)

## Test Cases
- Given a $12.99 order, when placed, then 12 points are added
- Given 100 points balance, when redeemed at checkout, then $5 discount applied
...

## Scope Boundary
- IN: Points earning, redemption at checkout, balance display
- OUT: Points expiration, admin dashboard (separate feature), transfer between accounts
```

### Step 6: Check the Work Package Against the Quality Gate

Open `packs/planner/prompts/planner.md.tmpl` and read the Quality Gate section. Check each rule:

| Quality Gate Rule | Pass? | Evidence |
|-------------------|-------|----------|
| Every user story has at least one AC | ✅ or ❌ | Count ACs per story |
| At least two test cases defined | ✅ or ❌ | Count test cases |
| Scope boundary is explicit | ✅ or ❌ | IN and OUT sections present? |
| No ambiguous terms | ✅ or ❌ | Search for "improve", "better", "enhance", "nice" |

**If any rule fails:**

1. **Do NOT edit the work package file directly.** That's a manual fix — it breaks config discipline.
2. Instead, open `packs/planner/prompts/planner.md.tmpl` and add a more specific rule. For example, if test cases are missing:

```markdown
## Quality Gate
...
5. Test cases must include at least one happy-path case AND one error case.
   Example error case: "Given an order of $0.00, when placed, then zero points
   are awarded (not an error)."
```

3. Delete the work package and re-sling:

```bash
rm work-packages/loyalty-points-system.md
gc sling planner my-factory-a1b2c3
gc watch planner
```

4. Review the new output. Repeat until all quality gate rules pass.

**Target: ≤2 slings.** If you're on sling #3, ask a facilitator — your prompt is probably fighting your project's existing conventions.

### Step 7: Mark the Planner Bead as Done

Once the work package passes all quality gate rules:

```bash
bd close my-factory-a1b2c3 --comment "Work package completed: work-packages/loyalty-points-system.md"
```

You should see:

```
Closed bead: my-factory-a1b2c3
```

---

## Part 4: Create and Run the Architect (~20 min)

The Planner's output is the Architect's input. Now the Architect reads the work package and produces an ADR for the open technical question: *where to store loyalty points?*

### Step 1: Create the Architect Bead with a Dependency

```bash
cd my-factory
bd create "Architecture Review: Loyalty Points Storage" \
  --description "$(cat <<'EOF'
Review the work package at work-packages/loyalty-points-system.md

Make an architectural decision about:
- How to store loyalty points (add column to users table? separate
  points_ledger table? external service?)
- Trade-offs of each approach for performance, data consistency,
  and future features
- Impact on the existing order placement flow

Read docs/PROJECT_MANIFEST.md for tech stack constraints.
Read CLAUDE.md for any tailored ADR baselines that may already
cover this decision pattern.

Produce an ADR at docs/adr/0001-loyalty-points-storage.md
using the MADR template in your prompt.
EOF
)" \
  --depends-on my-factory-a1b2c3
```

You should see:

```
Created bead: my-factory-d4e5f6
```

**What's happening here:** The `--depends-on my-factory-a1b2c3` flag tells Gas City: "don't let anyone sling this bead until `my-factory-a1b2c3` is closed." Since you just closed the Planner bead, this dependency is already satisfied. In the capstone (C1), you'll use dependencies to create automatic sequential pipelines.

Verify:

```bash
bd show my-factory-d4e5f6
```

You should see status `open` and the dependency marked as satisfied.

### Step 2: Sling to the Architect

```bash
gc sling architect my-factory-d4e5f6
```

You should see:

```
Slinging my-factory-d4e5f6 → architect
Session started: architect-d4e5f6 (tmux)
```

### Step 3: Watch the Architect Work

```bash
gc watch architect
```

The Architect should:

1. Read `docs/PROJECT_MANIFEST.md`
2. Read `CLAUDE.md` (checking for tailored ADR baselines)
3. Read `work-packages/loyalty-points-system.md`
4. Read any existing files in `docs/adr/` (there are none yet)
5. Start writing `docs/adr/0001-loyalty-points-storage.md`
6. Append a cross-reference to the work package
7. Commit on the feature branch

Wait until the Architect finishes (2–5 minutes).

### Step 4: Review the ADR

```bash
cat docs/adr/0001-loyalty-points-storage.md
```

You should see a file with this structure:

```markdown
# ADR-0001: Loyalty Points Storage Strategy

## Status
Proposed

## Context
The loyalty points system (see work-packages/loyalty-points-system.md)
requires persistent storage for customer point balances. The existing
tech stack uses SQLite via better-sqlite3. Key constraints:
- Points must be accurate (no double-counting)
- Adding points must not slow the checkout flow
- Must integrate with the existing orders table

## Options Considered

1. **Add points_balance column to users table**
   - Pros: Simple, single query to check balance
   - Cons: No audit trail, concurrent updates risk double-counting

2. **Separate points_ledger table (event sourcing)**
   - Pros: Full audit trail, balance derived from sum of events,
     naturally handles refunds (negative entries)
   - Cons: Balance query requires aggregation, more complex

3. **External points microservice**
   - Pros: Decoupled, independently scalable
   - Cons: Massive over-engineering for a single-store pizza app,
     adds network latency to checkout

## Decision
We chose **Option 2: Separate points_ledger table** because it provides
an audit trail (critical for financial data), naturally handles refunds
via negative entries, and the aggregation cost is negligible for the
expected volume (<10K orders/month).

## Consequences
- Positive: Full transaction history for debugging and reporting
- Positive: Refund handling is a ledger entry, not a balance mutation
- Negative: Admin dashboard queries will need GROUP BY aggregation
- Risk: If volume grows past 100K orders/month, consider materialized
  views or caching the balance

## References
- work-packages/loyalty-points-system.md
```

### Step 5: Check the ADR Against the Quality Gate

Open `packs/architect/prompts/architect.md.tmpl` and check each Quality Gate rule:

| Quality Gate Rule | Pass? | Evidence |
|-------------------|-------|----------|
| All four MADR sections present (Context, Options, Decision, Consequences) | ✅ or ❌ | Count sections |
| At least two options with trade-offs | ✅ or ❌ | Count options, check each has pros/cons |
| References work package by path | ✅ or ❌ | Search for `work-packages/` in the file |
| Consequences include at least one risk | ✅ or ❌ | Look for "Risk:" line |

**If any rule fails:**

1. Open `packs/architect/prompts/architect.md.tmpl` and add a more specific rule. For example, if the Architect only considered one option:

```markdown
## Quality Gate
...
5. You MUST evaluate at least 3 distinct approaches. If fewer than 3 are
   viable, explain why the rejected approaches were eliminated.
   "Only one way to do it" is never true — list the naive approach and
   explain why it was rejected.
```

2. Delete the ADR and re-sling:

```bash
rm docs/adr/0001-loyalty-points-storage.md
gc sling architect my-factory-d4e5f6
gc watch architect
```

3. Review the new output. Repeat until all rules pass.

### Step 6: Verify Cross-References

The Architect's Process (step 5 in the prompt) says: "Add a cross-reference to the work package."

Check the work package:

```bash
grep -i "adr\|architect" work-packages/loyalty-points-system.md
```

You should see a line like:

```
## Architectural Decisions
- ADR-0001: Loyalty Points Storage Strategy (docs/adr/0001-loyalty-points-storage.md)
```

Check the ADR:

```bash
grep -i "work-package\|work_package" docs/adr/0001-loyalty-points-storage.md
```

You should see:

```
- work-packages/loyalty-points-system.md
```

**If cross-references are missing:** this is a prompt gap. Add to both pack prompts:

In `packs/planner/prompts/planner.md.tmpl`, add to the Output Format:

```markdown
## Architectural Decisions
[Leave blank — the Architect agent will fill this in after producing ADRs]
```

In `packs/architect/prompts/architect.md.tmpl`, add to the Process section:

```markdown
5. After writing the ADR, open the work package file and append the ADR
   path under the "## Architectural Decisions" heading. If the heading
   doesn't exist, create it at the end of the file.
```

Re-sling the Architect. Check again.

### Step 7: Close the Architect Bead

```bash
bd close my-factory-d4e5f6 --comment "ADR completed: docs/adr/0001-loyalty-points-storage.md"
```

---

## Part 5: Commit, Review, and Document (~10 min)

### Step 1: Review the Full Artifact Set

```bash
cd ~/path/to/your-repo
git log --oneline -5
```

You should see commits from both agents:

```
a1b2c3d feat(architect): add ADR-0001 loyalty points storage
e4f5g6h feat(planner): add loyalty points work package
i7j8k9l chore(architect): customize architect prompt with tailored-ADR input
m0n1o2p chore: seed tailored industry ADRs via actual adr-bot
q3r4s5t chore(planner): customize planner prompt for project conventions
```

### Step 2: Verify Both Artifacts Exist

```bash
ls -la work-packages/loyalty-points-system.md
ls -la docs/adr/0001-loyalty-points-storage.md
```

Both files should exist and have non-zero size.

### Step 3: Push to Remote

```bash
git push -u origin l2-planner-architect
```

### Step 4: Update DECISIONS.md

Append an L2 entry to your `DECISIONS.md`:

```markdown
## 2026-04-21 · L2 · Planner + Architect

### What Happened
- Installed planner and architect packs
- Seeded tailored ADRs via `actual adr-bot` (8 baselines written)
- Planner produced work-packages/loyalty-points-system.md in 1 sling
- Architect produced docs/adr/0001-loyalty-points-storage.md in 1 sling
- Cross-references verified in both directions

### Config Changes Made
- Added project-specific Quality Gate rule #5 to planner prompt (prices in cents)
- Added CLAUDE.md as an Architect input for tailored-ADR baselines
- [List any other prompt changes you made during iteration]

### Lessons Learned
- The Architect's ADR quality was higher when tailored baselines were present —
  it spent its reasoning on the project-specific question (storage strategy)
  instead of re-deriving general patterns
- Cross-references don't happen automatically — the prompt must explicitly say
  "open the work package and append the ADR path"
```

Commit:

```bash
git add DECISIONS.md
git commit -m "docs: add L2 decision log entry"
git push
```

---

## Test Scenarios

Try these variations to stress-test your Planner and Architect:

### Scenario 1: Vague Feature Request

Sling a bead with a deliberately vague description:

```bash
bd create "Feature: Make the app better" \
  --description "The app should be improved. Make it nicer."
```

Sling to the Planner. **Expected:** The Planner should either refuse (if your Quality Gate says "no ambiguous terms") or produce a very weak work package. This tests whether your Quality Gate catches vagueness.

### Scenario 2: Feature with No Architectural Question

```bash
bd create "Feature: Change button color to blue" \
  --description "Change the 'Add to Cart' button from green to blue. File: src/components/MenuCard.tsx, line 42."
```

Sling to the Planner, then the Architect. **Expected:** The Architect should recognize there's no meaningful architectural decision here and produce a trivial ADR ("no decision needed — cosmetic change"). If your Architect writes a 3-option ADR for a button color, add a decision threshold to the prompt: "Only write an ADR if the decision affects more than one file or has long-term consequences."

### Scenario 3: Feature That Conflicts with a Tailored ADR

If you seeded tailored ADRs, create a feature that deliberately pushes against one of them. For example, if a tailored ADR says "use parameterized queries for all database access," create a feature that might tempt raw SQL:

```bash
bd create "Feature: Custom Report Builder" \
  --description "Allow admins to write custom SQL queries against the database to generate reports."
```

**Expected:** The Architect should flag the conflict with the tailored ADR and either propose a safe alternative (parameterized report templates) or write an override ADR explaining why raw SQL is acceptable for admin-only reports.

---

## Your Final File Structure

After completing L2, your project repo should contain:

```
your-repo/
├── CLAUDE.md                                    # Updated with tailored ADRs (if you ran adr-bot)
├── DECISIONS.md                                 # Now has L1 + L2 entries
├── docs/
│   ├── PROJECT_MANIFEST.md                      # Filled in before workshop
│   └── adr/
│       └── 0001-loyalty-points-storage.md       # ← Architect produced this
├── work-packages/
│   └── loyalty-points-system.md                 # ← Planner produced this
├── design/.gitkeep                              # Empty — Designer fills this in L3
├── review-reports/.gitkeep                      # Empty — Reviewer fills this in L4
├── release-gates/.gitkeep                       # Empty — Deployer fills this in L4
├── feedback-loops/.gitkeep                      # Empty — W4 fills this in
└── src/ ...                                     # Your existing code (untouched by L2)
```

And your city:

```
my-factory/
├── city.toml                                      # Now includes planner + architect packs
└── beads/
    ├── my-factory-a1b2c3 (closed)                 # Planner bead
    └── my-factory-d4e5f6 (closed)                 # Architect bead
```

---

## Command Cheat Sheet

Every command you ran during this lab, in order:

```bash
# PART 0 — Read the packs (no commands — just read the files)

# PART 1 — Install Planner
gc rig add ~/path/to/your-repo --include /path/to/packs/planner
gc restart
gc status
# (edit packs/planner/prompts/planner.md.tmpl — add project-specific Quality Gate rule)
git checkout -b l2-planner-architect
git add -A && git commit -m "chore(planner): customize planner prompt"

# PART 2 — Install Architect
brew install actual-software/actual/actual       # one-time install
actual adr-bot --dry-run                         # preview tailored ADRs
actual adr-bot                                   # write to CLAUDE.md
git add CLAUDE.md && git commit -m "chore: seed tailored industry ADRs"
gc rig add ~/path/to/your-repo --include /path/to/packs/architect
gc restart
gc status
# (edit packs/architect/prompts/architect.md.tmpl — add CLAUDE.md as input)
git add -A && git commit -m "chore(architect): customize architect prompt"

# PART 3 — Run the Planner
bd create "Feature: Loyalty Points System" --description "$(cat <<'EOF'
...feature request...
EOF
)"
gc sling planner my-factory-a1b2c3
gc watch planner                                 # Ctrl+b d to detach
cat work-packages/loyalty-points-system.md       # review output
# (if quality gate fails: edit prompt, rm work package, re-sling)
bd close my-factory-a1b2c3 --comment "Work package completed"

# PART 4 — Run the Architect
bd create "Architecture Review: Loyalty Points Storage" \
  --description "..." --depends-on my-factory-a1b2c3
gc sling architect my-factory-d4e5f6
gc watch architect
cat docs/adr/0001-loyalty-points-storage.md      # review output
grep -i "adr" work-packages/loyalty-points-system.md   # check cross-ref
grep -i "work-package" docs/adr/0001-loyalty-points-storage.md
# (if quality gate fails: edit prompt, rm ADR, re-sling)
bd close my-factory-d4e5f6 --comment "ADR completed"

# PART 5 — Commit and document
git push -u origin l2-planner-architect
# (edit DECISIONS.md — add L2 entry)
git add DECISIONS.md && git commit -m "docs: add L2 decision log entry"
git push
```

---

## Quick Reference: What You Built

| Component | File / Location | What It Does |
|-----------|-----------------|--------------|
| Planner pack | `packs/planner/` | Defines the Planner agent: prompt, overlay, metadata |
| Planner prompt | `packs/planner/prompts/planner.md.tmpl` | System prompt for the Planner — Role, Inputs, Output Format, Quality Gate, Process |
| Architect pack | `packs/architect/` | Defines the Architect agent: prompt, overlay, metadata |
| Architect prompt | `packs/architect/prompts/architect.md.tmpl` | System prompt for the Architect — same six-section structure |
| Tailored ADRs | `CLAUDE.md` (appended by `actual adr-bot`) | Industry-standard ADRs tailored to your codebase — the Architect's baseline |
| Work package | `work-packages/loyalty-points-system.md` | Planner's output: Goal, Stories, ACs, Dependencies, Tests, Scope |
| ADR | `docs/adr/0001-loyalty-points-storage.md` | Architect's output: Context, Options, Decision, Consequences, References |
| Cross-reference (WP → ADR) | Appended to work package by Architect | "See ADR-0001" |
| Cross-reference (ADR → WP) | In ADR's References section | `work-packages/loyalty-points-system.md` |
| Planner bead | `bd show my-factory-a1b2c3` | The work item that triggered the Planner |
| Architect bead | `bd show my-factory-d4e5f6` | The work item that triggered the Architect, with dependency on Planner bead |

---

## Quality Bar

When you review your own output, check:

- **Work Package Completeness** — All 6 sections present (Goal, Stories, ACs, Dependencies, Tests, Scope). Stories have measurable ACs.
- **ADR Quality** — All 4 MADR sections present. 2+ options with explicit trade-offs. Decision rationale is specific, not generic.
- **Cross-Reference Integrity** — Work package references the ADR by path. ADR references the work package by path. Both are valid file paths.
- **Config Discipline** — Every iteration was a prompt-file diff + re-sling. Zero ad-hoc chat corrections. DECISIONS.md documents each change.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `gc rig add --include` says "pack not found" | Use the absolute path to the pack directory, not relative. Verify with `ls /path/to/packs/planner/pack.toml`. |
| `gc status` doesn't show `planner` after restart | The `--include` may have failed silently. Run `gc rig list` and check the PACKS column. Re-run `gc rig add --include` with the correct path. |
| Planner writes to wrong directory (e.g., `plan/` instead of `work-packages/`) | Open `packs/planner/prompts/planner.md.tmpl` → Output Format section. Make the path explicit and add "never anywhere else." Re-sling. |
| Architect writes ADR without reading the work package | The bead description didn't include the work package path. Edit the bead: `bd edit my-factory-d4e5f6` and add the path explicitly. Re-sling. |
| Architect produces a 1-option ADR | Add to Quality Gate: "You MUST evaluate at least 3 options. List the naive approach and explain why it was rejected." Re-sling. |
| Cross-references are missing | Add explicit instructions to both prompts (see Part 4, Step 6). Re-sling the Architect only — it's responsible for back-linking. |
| `actual adr-bot` hangs or errors | Check that your Claude Code runner is authenticated: `claude auth login`. Or switch runner: `actual config set runner anthropic-api`. |
| `actual adr-bot` produces irrelevant ADRs | Scope it: `actual adr-bot --dry-run` to preview, then re-run with language/framework filters if available. Or just delete irrelevant sections from `CLAUDE.md`. |
| Planner hallucinates project features that don't exist | Add to planner prompt: "Only reference files, APIs, and features documented in `docs/PROJECT_MANIFEST.md` or visible in the repo. Never assume infrastructure that isn't committed." |
| Bead `--depends-on` blocks but the dependency is already closed | Run `bd show <bead-id>` to check dependency status. If it shows "satisfied," the bead is ready to sling. If still "blocked," verify you closed the prerequisite bead. |
| Agent produces output but doesn't commit | Check `git status` in the repo. The agent may have written files but failed to commit. Add to the prompt's Process section: "Always `git add` and `git commit` your output before marking the bead ready." |

---

## Exit Criteria

Before leaving this lab, verify all of these:

- [ ] `gc status` shows both `planner` and `architect` agents
- [ ] `work-packages/loyalty-points-system.md` exists with all 6 sections
- [ ] `docs/adr/0001-loyalty-points-storage.md` exists with all 4 MADR sections
- [ ] The work package references the ADR by path
- [ ] The ADR references the work package by path
- [ ] Both beads are closed (`bd list` shows status `closed`)
- [ ] `DECISIONS.md` has an L2 entry
- [ ] All changes pushed to remote

**L2 blocks L3.** Don't move on without both artifacts committed — L3's Designer agent reads the work package and ADR as its primary inputs. Without them, you'll be flying blind.

---

## Next Steps

In **L3**, you'll:
- Install the Designer and Builder (Coder) packs (`packs/designer`, `packs/builder`)
- The Designer reads your work package + ADR and produces a component spec at `design/<slug>-spec.md`
- The Coder reads the spec and implements actual code under `src/`
- Quality gates include `npm run build`, `npm test`, `npm run lint` — real compilation, real tests
- You'll have a 4-agent pipeline: Planner → Architect → Designer → Coder

The pattern is identical to what you just did — read pack, install pack, customize prompt, create bead, sling, review, iterate config, commit. You've now done it twice (L1 + L2). L3 adds two more agents on the same loop.
