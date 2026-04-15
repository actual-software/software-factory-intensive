# L1 · Build a Structured Development Loop

> **Goal:** Install Gas City, add your project as a rig, convert your W1 workflow card into a working `CLAUDE.md`, and sling your first real bead to an agent. By the end, the agent implements a small feature and commits it without you typing into the chat.

| | |
|---|---|
| **Day** | Day 1 |
| **Time** | 11:30 - 12:30 |
| **Type** | LAB |
| **Deliverable** | Working `CLAUDE.md` + committed feature + `DECISIONS.md` entry |

---

## What You'll Build

```
User story (from your backlog)
      ↓
bd create  →  a bead in Gas City
      ↓
gc sling dev-agent <bead-id>
      ↓
Agent reads CLAUDE.md, reads the bead, implements the feature
      ↓
Code passes quality gates (lint, tests, build)
      ↓
git log shows the commit — you didn't type a line of code
      ↓
DECISIONS.md logs what you changed in CLAUDE.md and why
```

**The Config Discipline:** When the agent produces wrong output, you update `CLAUDE.md` and re-sling the bead. You do **not** type a correction into chat. This is the single most-tested behavior of the lab.

---

## Prerequisites

- [ ] W1 complete — you have a `workflow-card.md` in your project repo
- [ ] Gas City installed: `brew install gastownhall/gascity/gascity`
- [ ] Claude Code (or your preferred AI coding agent) installed and authenticated
- [ ] Project repo cloned locally
- [ ] Project Manifest filled in at `docs/PROJECT_MANIFEST.md` (or plan to fill it in during Step 2)

---

## Gas City Capabilities Used This Lab

| Command | What it does | Used in step |
|---------|--------------|--------------|
| `gc init <dir>` | Create a new city (a workspace where agents + beads live) | Step 1 |
| `gc rig add <path>` | Register a project repo as a "rig" — a place agents can work | Step 1 |
| `gc rig list` | Show all rigs registered with the city | Step 1 |
| `gc status` | Show all agents, their state, and last activity | Step 3, 6 |
| `gc doctor` | Validate tools, auth, and pack config | Step 2 (optional) |
| `bd create` | Create a work item ("bead") that agents can pick up | Step 4 |
| `bd list` | Show beads and their status | Step 4 |
| `gc sling <agent> <bead>` | Assign a bead to an agent and start the session | Step 5 |
| `gc watch <agent>` | Attach to the tmux session and see the agent working | Step 6 |
| `gc events --follow` | Stream city-wide event log | Step 6 |
| `bd close <bead>` | Mark a bead complete with a comment | Step 9 |

You will *not* install an agent pack in this lab — the `dev-agent` is a single vanilla agent controlled entirely by `CLAUDE.md`. Agent packs arrive in L2.

---

## Reference: What Mature Looks Like

Before starting, skim two files in the reference project:

- [`reference-project/fired-up-pizza/CLAUDE.md`](../../../reference-project/fired-up-pizza/CLAUDE.md) — a mature `CLAUDE.md` written for a full 6-agent factory. Yours will be simpler (one agent, not six), but the structure carries over.
- [`reference-project/fired-up-pizza/docs/PROJECT_MANIFEST.md`](../../../reference-project/fired-up-pizza/docs/PROJECT_MANIFEST.md) — the project manifest an agent reads *before every task*.

And the skeleton you'll start from:

- [`my-factory/CLAUDE.md`](../../../my-factory/CLAUDE.md) — an intentionally bare `CLAUDE.md` template. Read it once — most of L1 is filling this in.
- [`my-factory/docs/PROJECT_MANIFEST.md`](../../../my-factory/docs/PROJECT_MANIFEST.md) — the manifest template.

---

## Step 1: Initialize Your City and Register Your Rig (10 min)

Your "city" is the workspace where all agents and beads live. Your "rig" is the project repo the agent will work in.

```bash
# Create a city. You'll use this directory every session from now on.
gc init ~/my-city
cd ~/my-city

# Register your project repo. Use the absolute path.
gc rig add ~/path/to/your-repo

# Verify it's registered.
gc rig list
```

Expected output:

```
NAME            PATH                          PACKS
your-repo       /Users/you/path/to/your-repo  (none)
```

If you cloned `software-factory-intensive` and want to use `my-factory/` as a starter workspace inside your own project repo, copy the skeleton in:

```bash
# Optional: bring the my-factory skeleton into your project
cp -r /path/to/software-factory-intensive/my-factory/* ~/path/to/your-repo/
cd ~/path/to/your-repo
git add CLAUDE.md README.md docs/ work-packages/ design/ review-reports/ release-gates/ feedback-loops/
git commit -m "chore: bootstrap factory skeleton from my-factory/"
```

The skeleton gives you the directory layout every downstream agent will expect (`work-packages/`, `docs/adr/`, `design/`, `review-reports/`, `release-gates/`, `feedback-loops/`). Creating it now means you don't scramble in L2–L4.

---

## Step 2: (Optional) Connect External Services via the Workshop Pack (10 min)

If your project uses Jira, Linear, GitHub Issues, GitLab, Sentry, DataDog, etc., install the `packs/workshop/` integrations pack now. Skipping this is fine — you can wire integrations in later.

```bash
cd ~/my-city
gc rig add ~/path/to/your-repo --include /path/to/software-factory-intensive/packs/workshop

# Copy the credential template into the repo and fill it in
cp /path/to/software-factory-intensive/packs/workshop/env.example ~/path/to/your-repo/.env
# Edit .env — only fill in the services you actually use

# Tell bd about the env and validate
gc workshop setup
gc doctor
```

Expected `gc doctor` output (truncated):

```
  ✓ check-core-tools    — gc, bd, dolt, tmux, jq, git, curl all present
  ✓ check-github        — authenticated as your-user
  ✓ check-jira          — authenticated as you@co.com (project: PROJ)
  ⚠ check-linear        — LINEAR_API_KEY not set  (ok — skipping)
```

Only `check-core-tools` is required. All other checks are informational — each one only activates if you filled in the matching env vars.

What this unlocks:

- Periodic sync orders (every 5 minutes) from your issue tracker into beads — see `packs/workshop/orders/sync-*/`
- MCP server tool access for observability (Sentry, DataDog, PostHog, Grafana) so agents can query errors and dashboards directly
- Cloud CLI validation (`aws`, `gcloud`, `az`) for future deploys

The full map of what the pack configures is in [`packs/workshop/README.md`](../../../packs/workshop/README.md).

---

## Step 3: Declare a `dev-agent` in `city.toml` (5 min)

Open `~/my-city/city.toml` and add:

```toml
[[agent]]
name = "dev-agent"
dir = "your-repo"            # must match the name shown by `gc rig list`
provider = "claude"
idle_timeout = "2h"
```

Apply the change and confirm the agent is visible:

```bash
gc restart
gc status
```

Expected:

```
NAME        STATE   LAST ACTIVITY   BEAD
dev-agent   idle    --              --
```

---

## Step 4: Write Your `CLAUDE.md` (15 min)

In **your project repo** (not the city), open `CLAUDE.md` and evolve your W1 workflow card into the structure below. If you copied in the `my-factory/CLAUDE.md` skeleton, edit it in place.

```markdown
# <Project Name> — Agent Instructions

## Project Context
- **Manifest**: `docs/PROJECT_MANIFEST.md` — read before every task.
- **Conventions**: TypeScript strict, conventional commits, feature branches.

## Role
You are a feature implementation agent. Take a user story from a bead,
implement it end-to-end, and commit with a conventional message.

## Iteration Rule
1. Read the bead's description completely. Re-read linked files.
2. Write a 3-line plan. Confirm the plan by committing it to the bead
   as a comment before writing code.
3. Implement in small slices (one test-passable unit at a time).
4. Run quality gates after every slice. If a gate fails, stop and read
   the error before touching code.
5. Commit when gates pass; move to next slice.

## Quality Gates
Every commit must satisfy:
1. **Lint:** `npm run lint` — zero errors, zero warnings
2. **Tests:** `npm test` — all green, new tests for new code
3. **Types:** `npm run type-check` (or `tsc --noEmit`) — clean
4. **Build:** `npm run build` — succeeds

## Decision Log
When you iterate on CLAUDE.md to fix an issue, add an entry to
`DECISIONS.md`. Include: date, the bead, what rule you added, why.

## Output Format
- Commits: `type(scope): description`
- PR descriptions: problem, solution, testing notes
- Comments explain WHY, not WHAT
```

Compare yours to the reference: [`reference-project/fired-up-pizza/CLAUDE.md`](../../../reference-project/fired-up-pizza/CLAUDE.md). The reference is longer because it drives six agents — yours drives one.

Commit on a branch:

```bash
cd ~/path/to/your-repo
git checkout -b claude-md-setup
git add CLAUDE.md
git commit -m "chore: add CLAUDE.md for dev-agent (L1)"
```

---

## Step 5: Pick a Small Test Story (5 min)

Choose one story from your backlog that you could manually code in 15–30 minutes. Smaller is better — your first sling is a calibration run, not a hero play.

If you don't have a backlog yet, borrow from Fired Up Pizza's tickets file:

- [`reference-project/fired-up-pizza/tickets.md`](../../../reference-project/fired-up-pizza/tickets.md) — e.g. "FUP-1: Menu display page" or "FUP-3: Shopping cart"

Write your chosen story in this format:

```markdown
# User Story: Show Order Total in Cart

**As a** customer
**I want** to see the total price in my cart
**So that** I know what I'll pay before checkout

## Acceptance Criteria
- [ ] Total updates on every quantity change
- [ ] Total formatted as currency with two decimals
- [ ] Total is 0.00 when cart is empty

## Technical Notes
- Use existing cart state in src/state/cart.ts
- Match existing currency util in src/utils/format.ts
```

---

## Step 6: Create a Bead for the Story (5 min)

```bash
cd ~/my-city
bd create "Implement: Show Order Total in Cart" \
  --description "$(cat <<'EOF'
[paste your user story here]
EOF
)"
```

This returns a bead ID like `my-city-abc123`. Confirm with `bd list`.

---

## Step 7: Sling the Bead and Watch (15 min)

```bash
gc sling dev-agent my-city-abc123
gc watch dev-agent
```

`gc sling` starts a tmux session, spins up Claude Code in the rig directory, and hands it the bead ID. `gc watch` attaches to that session so you can see tokens stream in real time. Press `Ctrl+b d` to detach (the agent keeps running).

In a second terminal, watch the event stream and status:

```bash
gc events --follow       # Everything happening city-wide
gc status                # Agent states
bd show my-city-abc123   # Bead progress
```

---

## Step 8: Review Output and Iterate (10 min)

When the agent finishes (state returns to `idle`):

```bash
cd ~/path/to/your-repo
git log -5 --oneline
git diff HEAD~1
```

Run the quality gates yourself:

```bash
npm run lint && npm test && npm run build
```

### If gates pass

Proceed to Step 9.

### If gates fail or output is wrong

**Do not type into chat. Do not fix the code manually.** Instead:

1. Identify the missing rule. "The agent used inline styles — that's not forbidden in CLAUDE.md." "The agent skipped tests — Quality Gates section doesn't require them explicitly enough."
2. Edit `CLAUDE.md` to add the missing rule in exact, testable terms.
3. Reset the branch: `git reset --hard HEAD~1`
4. Re-sling: `gc sling dev-agent my-city-abc123`
5. Log the iteration in `DECISIONS.md` (see Step 9).

**Target:** ≤3 slings to passing. If you hit 3 and still failing, flag a facilitator — your `CLAUDE.md` is probably fighting your project's existing conventions.

---

## Step 9: Write Your `DECISIONS.md` Entry (5 min)

Create or append to `DECISIONS.md` in your repo:

```markdown
# Decisions

## 2026-04-21 · my-city-abc123 · Show Order Total in Cart

### Context
First L1 sling. dev-agent with baseline CLAUDE.md.

### What Happened
- Sling 1: agent forgot to run quality gates before committing
- Sling 2: agent used inline styles in the cart component
- Sling 3: passed all gates, committed cleanly

### CLAUDE.md Changes
- Added explicit "Run `npm run lint && npm test && npm run build` before every commit" to Quality Gates.
- Added "No inline styles — use Tailwind classes or CSS modules" to Project Context.

### Lessons
- The agent treats CLAUDE.md as law, but only for rules written as imperatives. "Prefer X" is ignored. "NEVER X" is followed.
- Re-slinging after `git reset --hard` is cheap — don't be afraid to iterate.
```

Commit everything:

```bash
git add CLAUDE.md DECISIONS.md
git commit -m "docs: update agent rules after first sling (L1)"
git push -u origin claude-md-setup
```

Close the bead:

```bash
bd close my-city-abc123 --comment "Feature shipped. CLAUDE.md updated with 2 new rules."
```

---

## How the Reference Project Demonstrates This Loop

Fired Up Pizza is the reference project shipped with this repo. Look at:

- [`reference-project/fired-up-pizza/tickets.md`](../../../reference-project/fired-up-pizza/tickets.md) — the backlog that *would* be slung to agents
- [`reference-project/fired-up-pizza/CLAUDE.md`](../../../reference-project/fired-up-pizza/CLAUDE.md) — the mature instruction file that drives every agent in the 6-agent pipeline

The `CLAUDE.md` you just wrote is the Day-1 form. By C1 tomorrow, you'll have added sections for six agents — or pushed those role-specific rules into per-agent `packs/*/prompts/*.md` files, like the reference does. That's the transition from "single-agent config" to "factory config."

---

## Recommended Prompts

### In the Bead Description (Agent's First Read)

```
Implement the user story below, following every rule in CLAUDE.md.

<paste user story>

Before writing code:
1. Read CLAUDE.md completely. If any rule conflicts with this story,
   stop and say so.
2. Read the two files named in Technical Notes.
3. Post a 3-step plan as a bead comment.

After writing code:
1. Run every command in Quality Gates.
2. Commit with a conventional-commit message.
3. If you had to deviate from the plan, note it.
```

### When Updating `CLAUDE.md` Between Slings

You're not prompting the agent here — you're editing the file that prompts the agent. But verbalize the delta as a PR-sized sentence:

```
Added rule under Quality Gates: "No inline styles in React components.
Use Tailwind classes or CSS modules only." Reason: sling 2 produced
an inline-style CartTotal.tsx that violated repo convention.
```

This gives your facilitator (and your future self) the context to judge whether the rule was right.

---

## Evaluation Rubric

| Criterion | Points | Scoring |
|-----------|--------|---------|
| **`CLAUDE.md` Completeness** | 25 | All 4 sections (Role, Iteration Rule, Quality Gates, Decision Log) present and specific to your project |
| **Runs to Passing** | 30 | 1 sling = 30, 2 = 20, 3 = 10, >3 or any manual code edit = 0 |
| **`DECISIONS.md` Quality** | 25 | Documents what changed between slings, why, and lessons learned |
| **Quality Gates Pass** | 20 | Binary: all gates pass = 20, any failure = 0 |

**Total:** 100. Pod ranking sums across all 5 pod members.

---

## Exit Criteria

- [ ] `CLAUDE.md` committed to your project repo
- [ ] Feature implementation passes all quality gates
- [ ] `DECISIONS.md` has at least one L1 entry
- [ ] Bead closed in Gas City (`bd close`)
- [ ] Zero manual code edits — every iteration went through `CLAUDE.md`

**L1 blocks L2.** If you don't hit exit criteria by 12:30, get to the help desk during lunch. You cannot meaningfully add a second agent in L2 when the single-agent loop isn't working.

---

## Common Issues & Solutions

### Issue: Agent ignores `CLAUDE.md` entirely
**Solution:** Confirm `CLAUDE.md` is in the repo root, not a subdirectory. Check with `gc watch dev-agent` — the first thing the agent reads should be `CLAUDE.md`. If not, your provider config in `city.toml` may not be set to `claude`.

### Issue: Quality gates fail with the same error twice
**Solution:** Your rule is too vague. Move from principle → imperative: "Tests must pass" → "Run `npm test`. If any test fails, do not commit. Read the error, fix the cause, re-run."

### Issue: Agent takes 40+ minutes on a simple story
**Solution:** Your story is too big, or your `CLAUDE.md` is under-specified. Kill the session (`tmux kill-session -t dev-agent`), tighten the story scope to one component, tighten `CLAUDE.md`'s Iteration Rule to explicitly limit scope ("Only modify files named in Technical Notes"), re-sling.

### Issue: `gc status` shows `dev-agent` missing
**Solution:** Your `city.toml` `[[agent]]` block's `dir` field doesn't match the name in `gc rig list`. Fix the mismatch, run `gc restart`.

### Issue: You caught yourself typing into Claude chat
**Solution:** Stop immediately. That correction is invisible to your next sling. Undo the agent's current work, translate your chat correction into a `CLAUDE.md` rule, re-sling. The point of L1 is to feel how obvious this mistake is once you're watching for it.

---

## Next Steps

In **L2**, you'll:
- Install your first two agent packs (`packs/planner`, `packs/architect`)
- Split `CLAUDE.md` into per-agent behavior (still in `CLAUDE.md`) plus per-agent prompt files from the packs
- Produce your first **Work Package** and **ADR** — the two artifacts that downstream agents will consume

The single-agent loop you just built is the atomic unit of the factory. L2–L4 add more agents on top of the exact same iteration pattern.
