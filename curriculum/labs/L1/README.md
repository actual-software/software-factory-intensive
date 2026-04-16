# L1 · Build a Structured Development Loop

> **Goal:** Install Gas City, add your project as a rig, convert your W1 workflow card into a working `CLAUDE.md`, and sling your first real bead to an agent. By the end, the agent implements a small feature and commits it without you typing into the chat.

| | |
|---|---|
| **Estimated duration** | ~60 minutes |
| **Type** | LAB |
| **Deliverable** | Working `CLAUDE.md` (or `AGENTS.md`) + committed feature + `DECISIONS.md` entry |

---

## Architecture Diagram

```
                    ┌───────────────────────────┐
                    │      User Story             │
                    │  (from your backlog)        │
                    └─────────────┬─────────────┘
                                  │
                                  ▼
                    ┌───────────────────────────┐
                    │          bd create          │
                    │  (a bead in Gas City)       │
                    └─────────────┬─────────────┘
                                  │
                                  ▼
                    ┌───────────────────────────┐
                    │    gc sling dev-agent       │
                    │       <bead-id>             │
                    └─────────────┬─────────────┘
                                  │
                                  ▼
                    ┌───────────────────────────┐
                    │       DEV-AGENT             │
                    │                             │
                    │  Reads:                     │
                    │    • bead description       │
                    │    • CLAUDE.md              │
                    │    • docs/PROJECT_MANIFEST  │
                    │                             │
                    │  Produces:                  │
                    │    • implementation in src/ │
                    │    • tests                  │
                    │    • a conventional commit  │
                    └─────────────┬─────────────┘
                                  │
                                  ▼
                    ┌───────────────────────────┐
                    │      Quality Gates          │
                    │  (lint, type-check, test,   │
                    │        build)               │
                    └─────────────┬─────────────┘
                                  │
                            pass  │  fail
                                  │
                     ┌────────────┴────────────┐
                     ▼                         ▼
         ┌──────────────────┐       ┌──────────────────────┐
         │  git log shows    │       │  Edit CLAUDE.md,      │
         │  the commit —     │       │  git reset --hard,    │
         │  you didn't type  │       │  re-sling the bead    │
         │  a line of code   │       │  (the loop is config, │
         └─────────┬────────┘       │   NOT chat)            │
                   │                 └───────────┬──────────┘
                   ▼                             │
         ┌──────────────────┐                    │
         │  DECISIONS.md     │◄───────────────────┘
         │  logs what        │
         │  changed and why  │
         └──────────────────┘
```

**The Config Discipline:** When the agent produces wrong output, you update `CLAUDE.md` and re-sling the bead. You do **not** type a correction into chat. This is the single most-tested behavior of the lab — every iteration is a file diff, not a conversation.

---

## Prerequisites

Before starting this lab, verify each of these:

| Prerequisite | How to verify | How to fix |
|-------------|---------------|-----------|
| W1 complete | `ls ~/path/to/your-repo/workflow-card.md` → file exists | Go back and complete W1. L1 evolves your workflow card into agent instructions — without it, you're starting from scratch. |
| Gas City installed | `gc --version` → prints a version | `brew install gastownhall/gascity/gascity` |
| Claude Code installed | `claude --version` → prints a version | Install Claude Code from https://claude.ai/download and run `claude auth login`. Other providers (`codex`, `cursor`, `gemini`) also work — the `provider` field in `city.toml` selects one. |
| Project repo cloned | `cd ~/path/to/your-repo && git status` → clean or known state | `git clone <your-repo-url> ~/path/to/your-repo` |
| Project manifest | `cat ~/path/to/your-repo/docs/PROJECT_MANIFEST.md` → filled in | Copy from [`curriculum/PROJECT_MANIFEST_TEMPLATE.md`](../../PROJECT_MANIFEST_TEMPLATE.md) and fill in tech stack, conventions, domain model. You can defer this to Step 2 of this lab. |
| A small backlog item | A user story you could implement by hand in 15–30 minutes | If you don't have one, borrow from [`reference-project/fired-up-pizza/tickets.md`](../../../reference-project/fired-up-pizza/tickets.md) — we'll use FUP-3-style "Show Order Total in Cart" as the running example. |

---

## Running Example: Show Order Total in Cart

Throughout this lab, we use a single small feature as the running example: **"Show Order Total in Cart."** It's deliberately tiny — one component, a handful of files, no architectural questions — because your first sling is a calibration run, not a hero play. You're proving the loop works end-to-end, not building the killer feature.

If you're working against your own project, substitute something comparably small. The criteria: you could implement it by hand in under 30 minutes, it touches fewer than five files, and it doesn't require any architectural decision the agent couldn't reasonably make alone.

If you're working against Fired Up Pizza (the reference project), this maps closely to FUP-3 (Shopping cart) scoped down to "just the running total." Full FUP-3 would take longer than L1 budgets.

---

## Gas City Capabilities Used This Lab

| Command | What it does | Used in step |
|---------|--------------|--------------|
| `gc init <dir>` | Create a new city (a workspace where agents + beads live) | Step 1 |
| `gc rig add <path>` | Register a project repo as a "rig" — a place agents can work | Step 1 |
| `gc rig list` | Show all rigs registered with the city | Step 1 |
| `gc status` | Show all agents, their state, and last activity | Step 3, 7 |
| `gc doctor` | Validate tools, auth, and pack config | Step 2 (optional) |
| `gc restart` | Re-read `city.toml` and restart agents | Step 3 |
| `bd create` | Create a work item ("bead") that agents can pick up | Step 6 |
| `bd list` | Show beads and their status | Step 6 |
| `bd show <bead>` | Show a single bead's full description and status | Step 7 |
| `gc sling <agent> <bead>` | Assign a bead to an agent and start the session | Step 7 |
| `gc watch <agent>` | Attach to the tmux session and see the agent working | Step 7 |
| `gc events --follow` | Stream city-wide event log | Step 7 |
| `bd close <bead>` | Mark a bead complete with a comment | Step 9 |

You will *not* install an agent pack in this lab — the `dev-agent` is a single vanilla agent controlled entirely by `CLAUDE.md`. Agent packs arrive in L2.

---

## Reference: What Mature Looks Like

Before starting, skim the reference project:

- [`reference-project/fired-up-pizza/docs/PROJECT_MANIFEST.md`](../../../reference-project/fired-up-pizza/docs/PROJECT_MANIFEST.md) — the project manifest an agent reads *before every task*.

And the skeleton you'll start from:

- [`my-factory/PROJECT_MANIFEST.md`](../../../my-factory/PROJECT_MANIFEST.md) — the manifest template you'll fill in for your project.
- [`reference-project/fired-up-pizza/CLAUDE.md`](../../../reference-project/fired-up-pizza/CLAUDE.md) — a completed reference `CLAUDE.md`. Copy the structure, fill in your project's specifics, and save your version as `activities/labs/L1/CLAUDE.md` (or `AGENTS.md` for non-Claude assistants).

---

## Step 1: Initialize Your City and Register Your Rig (~10 min)

Your "city" is the workspace where all agents and beads live. Your "rig" is the project repo the agent will work in. A city can host many rigs; a rig is always a git repo.

### Step 1.1: Register Your Workspace

The repo already contains a ready-to-use workspace at `my-factory/`. You *register* that directory with the Gas City supervisor rather than running `gc init` from scratch — `gc init` would overwrite the pre-configured `city.toml`.

```bash
# From the repo root
cd my-factory
gc register .
```

Expected output (truncated):

```
Registered city 'my-factory' (/Users/you/.../software-factory-intensive/my-factory)
Installed launchd service: /Users/you/Library/LaunchAgents/com.gascity.supervisor.plist
  Adopting sessions...
  Starting agents...
```

**What's happening here:** `gc register` tells the long-running Gas City supervisor that this directory is a city it should manage. The shipped `my-factory/city.toml` is used as-is (no pack includes yet — those come in L2). The supervisor keeps agents alive between terminal sessions. You can inspect and edit `my-factory/city.toml` directly.

> **Earlier-draft note:** old versions of this README said to `gc init ~/my-city`. The curriculum now ships a pre-configured workspace at `my-factory/` — mentally replace any lingering `~/my-city` reference with `my-factory/`.

### Step 1.2: Register Your Project Repo as a Rig

```bash
# Register your project repo. Paths are resolved relative to my-factory/.
cd my-factory
gc rig add ../../path/to/your-repo
```

Expected output:

```
Re-initializing rig 'your-repo'...
  Detected git repo at /Users/you/path/to/your-repo
  Prefix: yr
  Initialized beads database
  Generated routes.jsonl for cross-rig routing
Rig re-initialized.
```

**What's happening here:** The rig registration does three things: it records the rig's path in `city.toml`, it initializes a per-rig beads database so work items in this rig have stable IDs, and it generates routing metadata so agents in one rig can refer to artifacts in another. The two-letter `Prefix` (`yr` here) is how bead IDs are namespaced — you'll see bead IDs like `my-factory-abc123` shortly.

### Step 1.3: Verify the Rig Is Registered

```bash
# Verify it's registered.
gc rig list
```

Expected output:

```
Rigs in /Users/you/my-city:
  my-city (HQ):
    Prefix: mc
    Beads:  initialized
  your-repo:
    Path:   /Users/you/path/to/your-repo
    Prefix: yr
    Beads:  initialized
```

**What's happening here:** Every city has an HQ rig (the city itself) plus any rigs you've added. `my-city (HQ)` is the meta-rig where cross-rig orchestration beads can live; `your-repo` is the code rig where the agent will actually work. The `dir` field you're about to add to `city.toml` in Step 3 must match the name `your-repo` exactly — copy it from this output, don't retype it.

### Step 1.4 (Optional): Create the Agent-Output Directories in Your Rig

L2 through L4 expect a predictable directory layout inside your project rig for factory-generated artifacts. Create them now so the Planner doesn't fail on a missing `work-packages/` the first time you sling it.

```bash
cd ../../path/to/your-repo
mkdir -p work-packages docs/adr design review-reports release-gates feedback-loops
touch work-packages/.gitkeep docs/adr/.gitkeep design/.gitkeep \
      review-reports/.gitkeep release-gates/.gitkeep feedback-loops/.gitkeep
git add work-packages docs design review-reports release-gates feedback-loops
git commit -m "chore: bootstrap factory output directories"
```

**What's happening here:** Each agent writes to one of these directories. Creating them now (with `.gitkeep` sentinels) means you don't scramble in L2–L4. None are used in L1 itself.

Your `CLAUDE.md` goes at your project repo's root — you'll draft it in Step 4. Keep a copy at `activities/labs/L1/CLAUDE.md` too so the session has a self-contained deliverable record.

---

## Step 2: (Optional) Connect External Services via the Workshop Pack (~10 min)

If your project uses Jira, Linear, GitHub Issues, GitLab, Sentry, DataDog, etc., install the `packs/workshop/` integrations pack now. Skipping this is fine — you can wire integrations in later. The first sling will work without any of them.

### Step 2.1: Attach the Workshop Pack to the Rig

```bash
cd my-factory
gc rig add ~/path/to/your-repo --include /path/to/software-factory-intensive/packs/workshop
```

**What's happening here:** `--include` tells Gas City to merge this pack's configuration into the rig's effective config. The workshop pack brings service-integration scaffolding — it does not add agents (those come from `packs/planner`, `packs/architect`, etc. starting in L2).

### Step 2.2: Copy the Credential Template

```bash
# Copy the credential template into the repo and fill it in
cp /path/to/software-factory-intensive/packs/workshop/env.example ~/path/to/your-repo/.env
# Edit .env — only fill in the services you actually use
```

**What's happening here:** `.env` is gitignored. Each integration (Jira, Linear, Sentry, etc.) activates only if its env vars are present. Leaving vars blank means that integration is silently skipped — no error, no warning.

### Step 2.3: Validate the Setup

```bash
# Validate the setup
gc doctor
```

Expected `gc doctor` output (truncated):

```
  ✓ city-structure — city.toml present
  ✓ city-config — city.toml loaded
  ✓ config-valid — agents, rigs, and services valid
  ✓ config-refs — all config references valid
  ✓ tmux-binary — found /opt/homebrew/bin/tmux
  ✓ git-binary — found /usr/bin/git
  ✓ jq-binary — found /usr/bin/jq
  ✓ rig:your-repo:path — path "/Users/you/path/to/your-repo" exists
  ✓ rig:your-repo:git — git repository
  ✓ rig:your-repo:beads — store accessible
  ✓ bd:check-bd — bd available
  ✓ dolt:check-dolt — dolt available
```

**What's happening here:** `gc doctor` walks every check in every pack and reports pass/fail. Only the core tool checks are required. Warnings for optional integrations (Jira, Linear, etc.) are expected — each activates only if you filled in the matching env vars. If core tool checks fail, fix those first; optional checks you can leave broken if you're not using that integration.

What the pack unlocks once configured:

- Periodic sync orders (every 5 minutes) from your issue tracker into beads — see `packs/workshop/orders/sync-*/`
- MCP server tool access for observability (Sentry, DataDog, PostHog, Grafana) so agents can query errors and dashboards directly
- Cloud CLI validation (`aws`, `gcloud`, `az`) for future deploys

The full map of what the pack configures is in [`packs/workshop/README.md`](../../../packs/workshop/README.md).

---

## Step 3: Declare a `dev-agent` in `city.toml` (~5 min)

The `dev-agent` is a single vanilla Claude agent that reads `CLAUDE.md` and nothing else. No pack, no prompt file, no overlay — it's the minimum viable agent, which is exactly what L1 needs.

### Step 3.1: Edit `city.toml`

Open `my-factory/city.toml` and add:

```toml
[[agent]]
name = "dev-agent"
dir = "your-repo"            # must match the name shown by `gc rig list`
provider = "claude"          # other providers (e.g. "codex", "cursor", "gemini") are also supported
idle_timeout = "2h"
```

**What's happening here:** `name` is what you'll type after `gc sling`. `dir` tells the agent which rig's working directory to open — this must exactly match the rig name in `gc rig list` or the agent won't start. `provider` picks the LLM backend. `idle_timeout` kills the tmux session after 2 hours of no bead activity, freeing resources. There's no `prompt_template` field because this agent uses `CLAUDE.md` in the rig root as its prompt (that's the default for `provider = "claude"`).

### Step 3.2: Apply the Change

```bash
gc restart
gc status
```

Expected output (truncated):

```
my-city  /Users/you/my-city
  Controller: supervisor (PID <pid>)
  Suspended:  no
Agents:
  mayor                   running
  your-repo/dev-agent     running
  claude                  pool (min=0, max=unlimited)
  your-repo/claude        pool (min=0, max=unlimited)
2/2 agents running
Rigs:
  your-repo  /Users/you/path/to/your-repo
```

**What's happening here:** `gc restart` tells the supervisor to re-read `city.toml` and bring agents into their declared state. `gc status` shows the current state. `dev-agent` should show `running` under Agents. If it doesn't, re-check the `dir` field in your `[[agent]]` block against the name shown by `gc rig list` — 90% of "my agent didn't come up" problems are a typo in `dir`.

### Step 3.3: Sanity-Check the Agent Can Open the Rig

`gc status` says `running` but hasn't yet proved the agent can actually start a Claude session. You'll know it can when the first `gc sling` in Step 7 succeeds. If anything is wrong with auth or provider config, that's when you'll see it — not now.

### Step 3.4: Understand What Each Field Does

The `[[agent]]` block is minimal on purpose. Each field has a specific job:

| Field | Purpose | Common values |
|-------|---------|---------------|
| `name` | How you refer to the agent (`gc sling <name> ...`) | `dev-agent`, `planner`, `reviewer` |
| `dir` | Which rig's working directory the agent opens | The rig name from `gc rig list` |
| `provider` | Which LLM backend powers the agent | `claude`, `codex`, `cursor`, `gemini` |
| `idle_timeout` | How long a tmux session persists without activity before shutdown | `30m`, `1h`, `2h`, `4h` |

Fields you'll add in later labs:

| Field | Introduced in | Purpose |
|-------|---------------|---------|
| `prompt_template` | L2 | Path to a pack's prompt file (replaces the rig's `CLAUDE.md` for that agent) |
| `overlay_dir` | L2 | Directory of environment overrides merged into the agent's context |
| `nudge` | L2 | A short reminder posted into the session at idle — "check for new work" |
| `max_active_sessions` | L2 | How many beads this agent can work on simultaneously (almost always `1`) |
| `scope` | L2 | `rig` or `city` — where the agent lives |

For L1, you don't need any of those. The four fields you have are enough.

---

## Step 4: Write Your `CLAUDE.md` (~15 min)

This is the step that matters most. `CLAUDE.md` is the agent's entire personality — everything it knows about your project's conventions, iteration style, and quality bar lives here. Every edit you make between slings is an edit to this file.

### Step 4.1: Copy the Skeleton

In **your project repo** (not the city), open `CLAUDE.md`. If you copied in the `my-factory/CLAUDE.md` skeleton in Step 1.4, edit it in place. Otherwise, create a new file at the repo root with the skeleton below.

(If you're using a non-Claude AI assistant — Codex CLI, Cursor, Gemini — name the file `AGENTS.md` instead. The structure is identical; most assistants look for either name.)

```markdown
# <Project Name> — Agent Instructions

## Project Context
- **Manifest**: `docs/PROJECT_MANIFEST.md` — read before every task.
- **Conventions**: <fill in — e.g. TypeScript strict, conventional commits, feature branches>

## Role
<one paragraph — what this agent is>

## Iteration Rule
<numbered list — your W1 Iteration Loop adapted for a single agent>

## Quality Gates
<numbered list — the commands that decide a commit is safe>

## Decision Log
<one paragraph — where you log rule changes>

## Output Format
<bullets — what commits, PRs, comments look like>
```

**What's happening here:** This skeleton mirrors the four sections of your W1 workflow card (Prompt Template, Context Reset Rule, Iteration Loop, Decision Checkpoint), but adapted for a standalone agent. The agent reads this file on every session — every rule here is enforced every time. Sections not present here (like a Role) are added because an agent needs the framing a human gets implicitly from team context.

### Step 4.2: Fill In the Role Section

```markdown
## Role
You are a feature implementation agent. Take a user story from a bead,
implement it end-to-end, and commit with a conventional message.
```

**What's happening here:** The Role is the agent's job description. Keep it narrow — "feature implementation" not "software engineer." A narrow role means the agent has fewer opportunities to creatively reinterpret what you asked for. In L2, each specialized agent will have an even narrower Role ("break feature requests into structured work packages").

### Step 4.3: Fill In the Iteration Rule Section

This is your W1 Iteration Loop, with one crucial change: it's now written *for the agent*, not for you.

```markdown
## Iteration Rule
1. Read the bead's description completely. Re-read linked files.
2. Write a 3-line plan. Confirm the plan by committing it to the bead
   as a comment before writing code.
3. Implement in small slices (one test-passable unit at a time).
4. Run quality gates after every slice. If a gate fails, stop and read
   the error before touching code.
5. Commit when gates pass; move to next slice.
```

**What's happening here:** Every step is an imperative ("Read", "Write", "Implement", "Run"). The agent follows imperatives reliably; it treats "prefer" or "consider" as advisory and skips them. Step 2 (the 3-line plan committed to the bead) is the single highest-leverage rule in the file — it forces the agent to externalize its reasoning before writing code, which catches 80% of misunderstandings before they become commits.

### Step 4.4: Fill In the Quality Gates Section

These are the commands the agent must run before every commit. Lift them verbatim from your project's CI config or package.json scripts — whatever your team already runs.

```markdown
## Quality Gates
Every commit must satisfy:
1. **Lint:** `npm run lint` — zero errors, zero warnings
2. **Tests:** `npm test` — all green, new tests for new code
3. **Types:** `npm run type-check` (or `tsc --noEmit`) — clean
4. **Build:** `npm run build` — succeeds
```

**What's happening here:** Quality Gates are the agent's exit criteria. They must be binary (pass/fail), deterministic (same result every run), and automatable (one shell command). "Code looks clean" is not a quality gate — `npm run lint` is. If your project uses different commands (pytest, go test, cargo build, make test), substitute them here. The agent will literally run these commands, parse their exit codes, and decide whether to commit.

### Step 4.5: Fill In the Decision Log Section

```markdown
## Decision Log
When you iterate on CLAUDE.md to fix an issue, add an entry to
`DECISIONS.md`. Include: date, the bead, what rule you added, why.
```

**What's happening here:** The agent doesn't usually edit `CLAUDE.md` itself — you do, between slings. But naming `DECISIONS.md` here means the agent reads that file too, and sees what rule changes you've made and why. Over time, that context helps the agent understand your project's grain.

### Step 4.6: Fill In the Output Format Section

```markdown
## Output Format
- Commits: `type(scope): description`
- PR descriptions: problem, solution, testing notes
- Comments explain WHY, not WHAT
```

**What's happening here:** Conventional commits are specified as `type(scope): description` so every commit is machine-parseable and easy to scan with `git log --oneline`. PR descriptions have a fixed structure so reviewers don't have to hunt. Code comments that explain WHY (not WHAT) are the only ones that survive a refactor — comments that restate the code are noise.

### Step 4.7: Commit on a Branch

```bash
cd ~/path/to/your-repo
git checkout -b claude-md-setup
git add CLAUDE.md
git commit -m "chore: add CLAUDE.md for dev-agent (L1)"
```

**What's happening here:** Committing `CLAUDE.md` on a branch (not main) means your first sling runs against a known agent configuration — one you can roll back if it turns out to be wrong. Treating the agent config as a PR-worthy artifact is the same discipline you applied to `workflow-card.md` in W1.

---

## Inline Insight: Why `CLAUDE.md` Is the Only Thing You Edit

There are many places you could theoretically "correct" an agent: the bead description, a chat message, the Iteration Rule, the Quality Gate, a pack prompt file. Only one of those places persists.

- **Chat corrections** die with the session. Your next `gc sling` starts fresh and has never heard of your correction.
- **Bead description edits** persist, but only for that one bead. The next bead starts over.
- **`CLAUDE.md` edits** persist across every future session, every bead, every agent (for now — in L2 they become pack-specific, but the discipline is the same).

So the rule is: *if you find yourself about to type a correction, it probably belongs in `CLAUDE.md`.* That's the config-discipline mindset in one sentence.

The only exception is per-bead context — "implement this specific feature, not some other feature." That belongs in the bead description, which we'll write in Step 6.

---

## Step 5: Pick a Small Test Story (~5 min)

Choose one story from your backlog that you could manually code in 15–30 minutes. Smaller is better — your first sling is a calibration run, not a hero play. You want the feedback loop short so you can iterate on `CLAUDE.md` multiple times before running out of time.

If you don't have a backlog yet, borrow from Fired Up Pizza's tickets file:

- [`reference-project/fired-up-pizza/tickets.md`](../../../reference-project/fired-up-pizza/tickets.md) — e.g. "FUP-1: Menu display page" or "FUP-3: Shopping cart"

For the running example, we scope FUP-3 down to just the running total:

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

**What's happening here:** The story has three acceptance criteria and two named existing files. The ACs are testable (every one can become a unit test). The Technical Notes name existing patterns the agent should match, which prevents it from inventing a new currency utility or a new state store. Vague stories produce vague code — every bullet here is deliberately narrow.

---

## Inline Insight: Why the First Slice Fails Most Often

When participants do this lab, the most common outcome on Sling 1 is: *the agent writes code that passes lint and build, but misses one acceptance criterion.* Usually the one about the empty state, or the one about currency formatting edge cases.

This is not an agent failure. It's a `CLAUDE.md` failure. Your Iteration Rule probably says "read the bead description completely" but doesn't say "enumerate each acceptance criterion as a test case before writing code." The agent reads the AC, files it mentally under "the big picture," and forgets it when coding the happy path.

The fix is almost always to tighten step 1 of the Iteration Rule: "Read the bead's description completely. **List each acceptance criterion as a line in your plan. Write a test for each AC before writing implementation code.**" That one addition typically moves first-sling success from 30% to 70%.

You'll discover this yourself in Step 8. Don't front-run the fix — see the failure first, then fix the config.

---

## Step 6: Create a Bead for the Story (~5 min)

A bead is a work item in Gas City. It has a title, a markdown description, a status, and an optional dependency chain. The description is the first thing the agent reads when you sling the bead to it.

### Step 6.1: Create the Bead

```bash
cd my-factory
bd create "Implement: Show Order Total in Cart" \
  --description "$(cat <<'EOF'
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
EOF
)"
```

This returns a bead ID like `my-factory-abc123`. **Note the ID** — you'll use it for the next several steps.

### Step 6.2: Verify the Bead

```bash
bd list
```

You should see:

```
ID              TITLE                                 STATUS   AGENT    CREATED
my-factory-abc123  Implement: Show Order Total in Cart   open     --       just now
```

**What's happening here:** The `HEREDOC` syntax (`<<'EOF'`) lets you pass a multi-line markdown description without escaping newlines or quotes. The quoted `'EOF'` disables shell variable expansion inside the description, so `$VAR` stays literal. `STATUS` is `open`; `AGENT` is empty because we haven't slung it yet.

### Step 6.3: Anatomy of a Bead Description

The description you just passed has five subtle properties worth naming:

- **Title line.** Starts with `# User Story:` so the agent knows what *kind* of artifact this is (not a bug report, not an ADR).
- **As-a / I want / So that.** A standard user story frame. The agent uses "So that" to infer what "good" looks like when two implementations both satisfy the literal ACs.
- **Checkbox ACs.** Markdown checkboxes (`- [ ]`) are a signal to the agent that each line should become a test case. Dashed bullets alone don't carry that signal.
- **Technical Notes naming existing files.** This is the highest-leverage field. "Use `src/state/cart.ts`" steers the agent away from inventing parallel state. Without this, the agent defaults to "add what makes sense" which often means a new file that duplicates existing code.
- **No implementation prescription.** You describe what the feature does, not how to build it. That's the agent's job. If you find yourself writing pseudocode in the description, you're not delegating — you're typing code with extra steps.

---

## Step 7: Sling the Bead and Watch (~15 min)

"Slinging" dispatches a bead to an agent and starts the session. This is the moment the agent starts actually working.

### Step 7.1: Sling

```bash
gc sling dev-agent my-factory-abc123
```

Expected output:

```
Slinging my-factory-abc123 → dev-agent
Session started: dev-agent-abc123 (tmux)
```

**What's happening here:** Gas City starts a tmux session, launches Claude Code inside your rig's working directory, loads `CLAUDE.md` as the system prompt, and hands the bead's description as the task. The agent is now autonomous — it will read, plan, implement, run quality gates, and commit without any further input from you.

### Step 7.2: Watch the Agent Work

```bash
gc watch dev-agent
```

**What's happening here:** `gc watch` attaches to the tmux session so you can see tokens stream in real time. You should see the agent read `CLAUDE.md`, then `docs/PROJECT_MANIFEST.md`, then the bead description, then begin writing a plan. Press `Ctrl+b d` to detach from tmux — the agent keeps running in the background. **Do not type into the watch window.** Anything you type goes into the agent's chat context and violates config discipline.

### Step 7.3: Monitor From Another Terminal

In a second terminal, watch the event stream and status:

```bash
gc events --follow       # Everything happening city-wide
gc status                # Agent states
bd show my-factory-abc123   # Bead progress
```

**What's happening here:** `gc events --follow` is a city-wide event log — every file the agent reads, every command it runs, every tool call. `gc status` polls the agent state (`running` → `idle` when done). `bd show` shows the bead's description plus any comments the agent has posted (including, if your Iteration Rule works, the 3-line plan).

### Step 7.4: Wait for Completion

Wait until the agent finishes (state returns to `idle` in `gc status`). For the running example, this typically takes 3–8 minutes depending on project size and quality-gate time.

### Step 7.5: What You Should See in the Event Stream

A healthy first sling produces a characteristic sequence of events. In another terminal running `gc events --follow`, you should see roughly this arc:

1. **Session spawn** — the tmux session starts, the agent initializes.
2. **File reads** — `CLAUDE.md`, `docs/PROJECT_MANIFEST.md`, any files named in the bead's Technical Notes.
3. **Bead comment** — the 3-line plan (if your Iteration Rule made it), posted to the bead.
4. **Edit events** — new or modified files under `src/` (or wherever your project code lives).
5. **Tool calls** — `npm run lint`, `npm test`, `npm run build` (or your project's equivalents).
6. **Commit event** — `git commit` with a conventional-commit message.
7. **Session idle** — the agent exits its task loop and waits.

If the sequence skips steps 2, 3, or 5, you've found a gap in `CLAUDE.md`. Most common: step 5 (quality gates) is skipped because the Iteration Rule doesn't explicitly require it. You'll find yourself fixing that gap in Step 8.

---

## Step 8: Review Output and Iterate (~10 min)

When the agent finishes, you review its work and decide whether to ship or re-sling.

### Step 8.1: Inspect the Commit

```bash
cd ~/path/to/your-repo
git log -5 --oneline
git diff HEAD~1
```

**What's happening here:** `git log -5 --oneline` shows the last five commits — you're looking for the one the agent just made. `git diff HEAD~1` shows everything that changed. Skim the diff before running tests — sometimes the problem is obvious (wrong file, missing imports, inline styles) and you can skip to the re-sling without burning time on the gates.

### Step 8.2: Run the Quality Gates

Run your project's quality gates. These are whatever your project already uses to decide code is committable — lint, type check, tests, build, or some subset. Your `CLAUDE.md` names them explicitly in the Quality Gates section; run exactly those commands, in the same order.

**What's happening here:** You're verifying the agent actually ran the gates it claims to have run. A passing agent will have already run them; a lying or broken agent might have committed without running them. Running them yourself is cheap insurance.

### Step 8.3: If Gates Pass

Proceed to Step 9.

### Step 8.4: If Gates Fail or Output Is Wrong

**Do not type into chat. Do not fix the code manually.** Instead:

1. **Identify the missing rule.** Be specific: "The agent used inline styles — that's not forbidden in `CLAUDE.md`." "The agent skipped tests — the Quality Gates section doesn't require them explicitly enough." "The agent forgot the empty-cart AC — the Iteration Rule doesn't enumerate ACs as tests."
2. **Edit `CLAUDE.md`** to add the missing rule in exact, testable terms. Imperatives only: "NEVER X" or "Before Y, do Z."
3. **Reset the branch:** `git reset --hard HEAD~1`
4. **Re-sling:** `gc sling dev-agent my-factory-abc123`
5. **Log the iteration** in `DECISIONS.md` (see Step 9).

**What's happening here:** Each re-sling runs against a *new* `CLAUDE.md`, which means it's a new, cleaner agent configuration. `git reset --hard HEAD~1` wipes the agent's previous attempt so the re-slung agent starts from the same state it started from the first time. If you don't reset, the second sling has to figure out what to do with the first sling's half-finished work, which confuses it.

**Target:** ≤3 slings to passing. If you hit 3 and still failing, your `CLAUDE.md` is probably fighting your project's existing conventions — pause, re-read the conflicting rule alongside an example of the convention in your repo, and rewrite.

---

## Step 9: Write Your `DECISIONS.md` Entry (~5 min)

`DECISIONS.md` is the log of what you changed in `CLAUDE.md` and why. Future you (and future teammates) will thank present you for writing this.

### Step 9.1: Create or Append to `DECISIONS.md`

```markdown
# Decisions

## 2026-04-21 · my-factory-abc123 · Show Order Total in Cart

### Context
First L1 sling. dev-agent with baseline CLAUDE.md.

### What Happened
- Sling 1: agent forgot to run quality gates before committing
- Sling 2: agent used inline styles in the cart component
- Sling 3: passed all gates, committed cleanly

### CLAUDE.md Changes
- Added explicit "Run all Quality Gates before every commit. If any fails, stop." to Iteration Rule step 4.
- Added "No inline styles — use Tailwind classes or CSS modules" to Project Context.

### Lessons
- The agent treats CLAUDE.md as law, but only for rules written as imperatives. "Prefer X" is ignored. "NEVER X" is followed.
- Re-slinging after `git reset --hard` is cheap — don't be afraid to iterate.
```

**What's happening here:** The structure is deliberate: Context (what was the situation), What Happened (sling-by-sling trace), CLAUDE.md Changes (the exact diff), Lessons (what you learned about your project and the agent). The Lessons section is the most valuable part — it's what survives beyond the specific bead and informs every future agent config.

### Step 9.2: Commit Everything

```bash
git add CLAUDE.md DECISIONS.md
git commit -m "docs: update agent rules after first sling (L1)"
git push -u origin claude-md-setup
```

### Step 9.3: Close the Bead

```bash
bd close my-factory-abc123 --comment "Feature shipped. CLAUDE.md updated with 2 new rules."
```

**What's happening here:** Closing the bead with a descriptive comment leaves a breadcrumb. When you (or an orchestrator agent in the capstone) later look at bead history, the comment tells you what actually shipped, not just that something did.

---

## How the Reference Project Demonstrates This Loop

Fired Up Pizza is the reference project shipped with this repo. Look at:

- [`reference-project/fired-up-pizza/tickets.md`](../../../reference-project/fired-up-pizza/tickets.md) — the backlog that *would* be slung to agents
- [`reference-project/fired-up-pizza/docs/PROJECT_MANIFEST.md`](../../../reference-project/fired-up-pizza/docs/PROJECT_MANIFEST.md) — the manifest the agents read before every task

The agent instructions file you just wrote is the starter form. By C1, you'll have added sections for six agents — or pushed those role-specific rules into per-agent `packs/*/prompts/*.md` files, like the reference does. That's the transition from "single-agent config" to "factory config."

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

This gives your future self the context to judge whether the rule was right.

---

## Inline Insight: How an Agent Actually Reads `CLAUDE.md`

Understanding how the agent parses `CLAUDE.md` helps you write rules that actually fire. Here's roughly what happens:

1. **Session start.** When `gc sling` fires, Gas City launches Claude Code with the rig directory as the working directory. Claude Code looks for `CLAUDE.md` in the working directory and loads its full contents as part of the system prompt.
2. **Section parsing.** The model doesn't have a special `CLAUDE.md` parser — it just treats the file as plain text. Section headings help it retrieve relevant chunks when reasoning, but there's no "Role section" data structure under the hood. It's all continuous text to the model.
3. **Rule weighting.** Imperatives ("NEVER", "ALWAYS", "MUST", "Run this command") weigh heavier than hedges ("try to", "consider", "prefer"). Structured lists weigh heavier than prose. Named commands weigh heavier than described outcomes.
4. **Instruction decay.** In long sessions, earlier parts of the system prompt receive less attention per token than recent conversation. This is why the 3-line plan step matters: externalizing the plan into a bead comment makes it part of the *recent* conversation again when the agent is coding.
5. **Conflict resolution.** When two rules contradict, the more specific one wins. "All commits must pass tests" + "Fix build errors before testing" → the agent will fix build errors before running tests, because that sequencing rule is more specific.

Practical implications:

- **Put the most important rules near the top.** The skeleton puts Project Context before Role before Iteration Rule because each section depends on knowing the ones above it.
- **Name commands verbatim.** "Run tests" is weaker than "Run `npm test`". The second one gives the agent a directly executable instruction.
- **Use structured lists for sequences.** A numbered Iteration Rule is followed step-by-step; a paragraph describing the process is sometimes followed, sometimes skipped.
- **Re-state critical rules in the relevant section.** If "never edit main" is a Project Context rule *and* the first step of the Iteration Rule, the agent is twice as likely to remember it.

---

## Exit Criteria

- [ ] `CLAUDE.md` (or `AGENTS.md`) committed to your project repo with all 4 sections (Role, Iteration Rule, Quality Gates, Decision Log) present and specific to your project
- [ ] Feature implementation passes all quality gates
- [ ] `DECISIONS.md` has at least one L1 entry documenting what changed between slings, why, and lessons learned
- [ ] Bead closed in Gas City (`bd close`)
- [ ] Zero manual code edits — every iteration went through the agent instructions file

**L1 blocks L2.** Don't move on without meeting exit criteria — you cannot meaningfully add a second agent in L2 when the single-agent loop isn't working.

---

## Quality Bar

When you review your own work at the end of the lab, check each of these:

- **`CLAUDE.md` Specificity** — Every rule names a concrete thing (command, path, filename). No generic phrases like "good code" or "clean output." Run a grep for words like "prefer", "try", "consider", "maybe" — each one is a candidate for rewriting as an imperative.
- **Iteration Rule Completeness** — The rule covers the happy path (implement, commit) and the failure path (what to do when a quality gate fails). A rule that only covers success is a rule that's never tested.
- **Quality Gates Executability** — Each gate is a single shell command with a zero / non-zero exit code. If the agent has to interpret output subjectively, it's not a gate — it's a suggestion.
- **Decision Log Integrity** — Every rule you added mid-lab has a matching `DECISIONS.md` entry with date, bead ID, rule, and reason. The log is the audit trail of your config evolution.
- **Config Discipline** — Zero manual code edits. Every correction was a `CLAUDE.md` diff + re-sling. If you cheated once, go back, revert the manual edit, add the rule, re-sling. The habit is what matters.

---

## Test Scenarios

Once you've completed the base lab, try these variations to stress-test your `CLAUDE.md`:

### Scenario 1: A Deliberately Vague Story

Create a bead with a weakly-specified story:

```bash
bd create "Feature: Improve the cart UX" \
  --description "Make the cart page feel nicer and more professional."
```

Sling to `dev-agent`. **Expected behavior:** The agent either refuses (if your Iteration Rule says "if acceptance criteria are missing, post a comment and stop") or produces something arbitrary. This tests whether your rules force specificity out of the bead before coding starts. If the agent plowed ahead, add to the Iteration Rule: "Before writing any code, confirm the bead has at least two concrete acceptance criteria. If not, post a comment listing what's missing and stop."

### Scenario 2: A Story That Crosses Convention Lines

Create a bead that tempts convention violations:

```bash
bd create "Feature: Inline-style cart total for quick prototype" \
  --description "Add the cart total to src/components/Cart.tsx using inline styles for speed. We'll refactor later."
```

Sling to `dev-agent`. **Expected behavior:** The agent ignores the "use inline styles" hint in the bead and uses your project's actual styling convention (Tailwind, CSS modules, etc.), because your `CLAUDE.md` Project Context forbids inline styles. This tests whether `CLAUDE.md` rules override per-bead instructions. If the agent complied with the bead, strengthen your Project Context rule to explicitly outrank bead-level overrides.

### Scenario 3: Consecutive Small Stories (Pipeline Durability)

Create three small beads in sequence, sling each, close each. You're testing that the `CLAUDE.md` you converged to for the first story still works for unrelated stories. **Expected behavior:** All three ship within target (≤3 slings each) without requiring `CLAUDE.md` edits specific to each. If you had to add a new rule per bead, your rules are too narrow — generalize them.

---

## Common Issues & Solutions

### Issue 1: Agent ignores `CLAUDE.md` entirely
**Solution:** Confirm `CLAUDE.md` is in the repo root, not a subdirectory. Check with `gc watch dev-agent` — the first thing the agent reads should be `CLAUDE.md`. If not, your provider config in `city.toml` may not be set to `claude`, or the agent may be running in the wrong `dir`.

### Issue 2: Quality gates fail with the same error twice
**Solution:** Your rule is too vague. Move from principle → imperative: "Tests must pass" → "Run `npm test`. If any test fails, do not commit. Read the error, fix the cause, re-run." The agent follows imperatives; it treats suggestions as optional.

### Issue 3: Agent takes 40+ minutes on a simple story
**Solution:** Your story is too big, or your `CLAUDE.md` is under-specified. Kill the session (`tmux kill-session -t dev-agent`), tighten the story scope to one component, tighten `CLAUDE.md`'s Iteration Rule to explicitly limit scope ("Only modify files named in Technical Notes"), re-sling.

### Issue 4: `gc status` shows `dev-agent` missing
**Solution:** Your `city.toml` `[[agent]]` block's `dir` field doesn't match the name in `gc rig list`. Fix the mismatch, run `gc restart`. Typos here account for more "missing agent" reports than any other cause.

### Issue 5: You caught yourself typing into Claude chat
**Solution:** Stop immediately. That correction is invisible to your next sling. Undo the agent's current work, translate your chat correction into a `CLAUDE.md` rule, re-sling. The point of L1 is to feel how obvious this mistake is once you're watching for it.

### Issue 6: Agent commits code that fails tests it didn't run
**Solution:** Add an explicit "After implementing, run every command in Quality Gates in order, before committing. If any command fails, do not commit — fix and re-run" step to the Iteration Rule. Some agents optimize for shipping quickly and skip the gates unless forced.

### Issue 7: Agent changes files outside the feature scope
**Solution:** Add a scope-lock rule to `CLAUDE.md`: "Only modify files listed in the bead's Technical Notes plus tests for those files. NEVER modify configuration files, CI, or unrelated modules without explicit instruction." The agent defaults to expansive scope unless told otherwise.

### Issue 8: Agent invents APIs, libraries, or files that don't exist
**Solution:** Add to Project Context: "Only reference files, functions, and dependencies that currently exist in the repo. Before using an import, verify the target file contains that export. Never assume a utility exists — search for it first." Claude defaults to "helpful completion" over "literal truth" unless reined in.

### Issue 9: `gc sling` returns "agent not found"
**Solution:** The agent name in the command doesn't match `name = "..."` in `city.toml`. Copy-paste from `gc status`, don't retype. Also check you're running `gc sling` against the same city the agent is declared in — if you ran `gc init` twice in different directories, you may have two cities.

### Issue 10: Tmux session won't close after sling ends
**Solution:** `tmux kill-session -t dev-agent` force-kills it. Or `gc session stop dev-agent` does it through the supervisor. If sessions leak every time, check `idle_timeout` in your `[[agent]]` block — setting it to something smaller than 2h (e.g., `30m`) bounds the damage.

### Issue 11: Agent posts a plan but doesn't follow it
**Solution:** The Iteration Rule needs a self-check step: "After posting the plan, implement each step in order. Before moving to the next step, verify the previous step's output passes its tests." Plans without enforcement are decoration.

### Issue 12: `gc events --follow` shows nothing
**Solution:** Events are only emitted during active sessions. If no agent is running, the stream is silent — not broken. Sling a bead, then watch events. If events still don't appear, check `my-factory/events.jsonl` directly with `tail -f`.

---

## Command Cheat Sheet

Every command you ran, in order:

```bash
# SETUP (Step 1)
cd my-factory
gc register .
gc rig add ../../path/to/your-repo
gc rig list
# (Bootstrap your rig's output directories — see Step 1.4)

# OPTIONAL INTEGRATIONS (Step 2)
# Edit my-factory/city.toml and add "../packs/workshop" to includes
cp ../packs/workshop/env.example ../../path/to/your-repo/.env
gc service restart
gc doctor

# AGENT DECLARATION (Step 3)
# Edit my-factory/city.toml
gc restart
gc status

# WRITE CLAUDE.MD (Step 4)
# Edit ~/path/to/your-repo/CLAUDE.md
git checkout -b claude-md-setup
git add CLAUDE.md
git commit -m "chore: add CLAUDE.md for dev-agent (L1)"

# CREATE BEAD (Step 6)
bd create "Implement: Show Order Total in Cart" --description "$(cat <<EOF
... your story ...
EOF
)"
bd list

# SLING + WATCH (Step 7)
gc sling dev-agent my-factory-abc123
gc watch dev-agent
# In parallel terminals:
gc events --follow
gc status
bd show my-factory-abc123

# VERIFY (Step 8)
git log -5 --oneline
git diff HEAD~1
# Run your project's quality gates (lint, tests, type check, build)

# ITERATE on CLAUDE.md if gates fail (no code edits!)
# Edit CLAUDE.md
git reset --hard HEAD~1
gc sling dev-agent my-factory-abc123

# CLOSE (Step 9)
git add CLAUDE.md DECISIONS.md
git commit -m "docs: update agent rules after first sling (L1)"
git push -u origin claude-md-setup
bd close my-factory-abc123 --comment "Feature shipped. CLAUDE.md updated."
```

---

## Quick Reference: What You Built

| Component | Location | What It Does |
|-----------|----------|--------------|
| City | `my-factory/` | The workspace where agents and beads live. Registered via `gc register`. |
| `city.toml` | `my-factory/city.toml` | The city's configuration file. Agent declarations live here. |
| Supervisor | Background launchd service | Keeps agents alive between terminal sessions |
| Rig | Registered via `gc rig add` | Your project repo, registered with the city. One city can have many rigs. |
| `dev-agent` | `[[agent]]` block in `my-factory/city.toml` | A single Claude-backed agent, controlled by `CLAUDE.md` |
| `CLAUDE.md` | `your-repo/CLAUDE.md` | The *only* place agent behavior is defined. Edit this, never the chat. |
| `AGENTS.md` | `your-repo/AGENTS.md` (alternative name) | Identical to `CLAUDE.md` in structure. Use this name for Codex, Cursor, Gemini. |
| `docs/PROJECT_MANIFEST.md` | `your-repo/docs/PROJECT_MANIFEST.md` | Tech stack, conventions, domain model. Read by every agent before every task. |
| `DECISIONS.md` | `your-repo/DECISIONS.md` | Running log of what you changed in `CLAUDE.md` and why |
| Bead | Created via `bd create` | A unit of work an agent can pick up and close. Has title, description, status. |
| Bead database | `my-factory/.../beads/` | Per-rig storage for all beads. Managed by `bd`. |
| Sling | `gc sling dev-agent <bead>` | Dispatches a bead to an agent, starts a tmux session |
| Tmux session | `dev-agent-<bead-prefix>` | Where the agent actually runs. Attach with `gc watch` or `tmux attach -t ...`. |
| Quality gates | Defined in `CLAUDE.md` Quality Gates section | Binary pass/fail per run; the agent's exit criteria |
| Event stream | `gc events --follow` | Real-time city-wide log of agent activity |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `gc status` doesn't list `dev-agent` | Your `[[agent]]` block's `dir` field doesn't match the name shown by `gc rig list`. Align them, `gc restart`. |
| `gc sling` returns "agent not found" | Agent name in the command doesn't match `name = "..."` in `city.toml`. Copy-paste, don't retype. |
| `gc sling` returns "bead not found" | Bead ID typo, or you're running `gc sling` against the wrong city. Run `bd list` to confirm the ID. |
| Agent runs but never reads `CLAUDE.md` | File is in a subdirectory, not the repo root. `ls ~/path/to/your-repo/CLAUDE.md` must succeed. |
| Agent makes the same mistake after re-sling | Your rule is a suggestion ("Prefer X"), not an imperative ("NEVER do Y"). Rewrite as imperative. |
| Quality gates pass but feature is wrong | Acceptance criteria were too loose. Strengthen the ACs in the bead description, not the prompt. |
| `gc doctor` warns about missing `LINEAR_API_KEY` etc. | Expected — only core tool checks are required. Other checks only fire if you fill in env vars for that service. |
| You caught yourself typing into chat | Stop, undo the agent's work, translate your chat correction into a `CLAUDE.md` rule, re-sling. This *is* the lesson. |
| Agent takes 40+ minutes on a simple story | Story too big or rules too loose. Kill the tmux session, tighten scope in `CLAUDE.md` and in the bead, re-sling. |
| Tmux session won't close | `tmux kill-session -t dev-agent` or `gc session stop dev-agent`. |
| `gc restart` hangs | Check the supervisor process: `ps aux \| grep gascity`. If stuck, `launchctl unload ~/Library/LaunchAgents/com.gascity.supervisor.plist` then `gc register my-factory` again. |
| Agent commits to main instead of a feature branch | Add to CLAUDE.md: "Before making any code changes, ensure you are on a feature branch. If on main, run `git checkout -b <bead-slug>` first." |
| Agent's commit message isn't conventional-commits | Output Format in CLAUDE.md needs an example. Add: "Commit format: `feat(scope): short description`. Example: `feat(cart): show order total in cart view`." |
| `bd show` returns nothing | Bead ID is wrong or from a different rig. `bd list` to see all beads in the current rig. |
| Agent asks a question and pauses | Your Iteration Rule doesn't tell it what to do when stuck. Add: "If you cannot proceed, post a bead comment describing the blocker and exit. Do not ask the user interactively." |
| `.env` variables not picked up | Gas City loads `.env` at session start, not at sling. Run `gc restart` after editing `.env`. |

---

## After the Sling: A Retrospective Checklist

Before starting L2, walk through this retrospective on your L1 run. It takes 5 minutes and surfaces the gaps you'll want to close before adding more agents.

1. **How many slings did it take?** If 1, you probably got lucky — your story was simple and your `CLAUDE.md` was reasonable. If 2–3, you hit the intended learning curve. If 4+, one of your rules is fighting one of your project conventions — identify which.
2. **What was the first rule you added mid-lab?** This is the rule your workflow card missed in W1. File it in `DECISIONS.md` with a clear "why W1 missed this" explanation — that's the exact gap you want to close in future workflow card revisions.
3. **Did you ever type into the chat?** If yes, even once, re-run Scenario 2 from Test Scenarios. The muscle memory for config-over-chat is the single most important habit the curriculum builds.
4. **Did the agent commit to a feature branch?** `git branch --show-current` should show `claude-md-setup` or similar, not `main`. If it's on `main`, add a branch-discipline rule to `CLAUDE.md` before L2 — you don't want six agents pushing to main in L4.
5. **Did the agent follow the Output Format?** Check `git log --oneline -3`. Every commit should match `type(scope): description`. If any don't, your Output Format needs a concrete example (not just the pattern).

Bring your answers to L2 — the gaps you identify now will become per-agent rules in `packs/planner/prompts/planner.md` and beyond.

---

## Next Steps

In **L2**, you'll:
- Install your first two agent packs (`packs/planner`, `packs/architect`)
- Split agent behavior into per-agent prompt files — each with its own Role, Inputs, Output Format, Quality Gate, and Process
- Produce your first **Work Package** and **ADR** — the two artifacts that downstream agents will consume

The single-agent loop you just built is the atomic unit of the factory. L2–L4 add more agents on top of the exact same iteration pattern: create bead → sling → watch → review → edit config → re-sling. If that loop feels solid now, the rest of the curriculum is "do it again, with more agents."
