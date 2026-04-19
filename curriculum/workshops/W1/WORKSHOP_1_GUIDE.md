# W1 · Run the 6-Agent Software Factory

> **Goal:** Install the factory-activity-agent tooling, stand up the Fired-Up Pizza reference factory on your machine, and watch a single feature bead walk through all six agents — `needs-plan` → `needs-architecture` → `needs-design` → `ready-to-build` → `needs-review` → `ready-to-ship` → closed — without a human typing a prompt at any stage.

| | |
|---|---|
| **Estimated duration** | ~60 minutes |
| **Type** | Workshop |
| **Deliverable** | A running Fired-Up Pizza factory on your machine, with at least one bead visibly re-labelled by each of the six agents and inspectable via the dashboard |

---

## Session workspace note

* **factory-activity-agent source:** [skills/factory-activity-agent/](../../../skills/factory-activity-agent/) — [SKILL.md](../../../skills/factory-activity-agent/SKILL.md) is the canonical entry point; [scripts/](../../../skills/factory-activity-agent/scripts/) hold the thin Bash wrappers ([install.sh](../../../skills/factory-activity-agent/scripts/install.sh), [status.sh](../../../skills/factory-activity-agent/scripts/status.sh), [doctor.sh](../../../skills/factory-activity-agent/scripts/doctor.sh), [delete.sh](../../../skills/factory-activity-agent/scripts/delete.sh), [diagnose.sh](../../../skills/factory-activity-agent/scripts/diagnose.sh)) that front the Python runner at [scripts/factory_activity_agent.py](../../../skills/factory-activity-agent/scripts/factory_activity_agent.py).
* **Reference project (the "rig" the factory works on):** [reference-project/fired-up-pizza/](../../../reference-project/fired-up-pizza/) — a small React + TypeScript + SQLite pizza-restaurant app with `docs/PROJECT_MANIFEST.md`, `tickets.md` (initial backlog), and `package.json` already in place.
* **Project rig (the "rig" the factory works on):** `~/Projects/factory/workshop_w1/w1-project/` — the workspace for the Fired-Up Pizza project. This is where code and deliverables are stored.
* **Factory workspace (created during this session):** `~/Projects/factory/workshop_w1/w1-gc-factory/` — the Gas City `city.toml` + workspace that runs the agents. Every `gc` command below is run from that directory unless otherwise noted.
* **Fired-Up Pizza pack (what is installed into your factory):** [packs/fired-up-pizza/](../../../packs/fired-up-pizza/) — a composite pack bundling the six agents together.
* **Canonical reference:** before you install anything, read [LABELED_BEADS.md](../../../LABELED_BEADS.md) — it is the authoritative doc for the six labels that drive the factory's handoffs. Every "why did the agent wake now?" question this session surfaces is answered there. Keep it open in a tab.

---

## What You'll See Run

```
     tickets.md (FUP-1 … FUP-6)
         │
         ▼  bd create --label needs-plan
┌──────────────────────────────────────────────────────────┐
│  Planner        (consumes needs-plan)                    │
│    decomposes → sets needs-architecture / needs-design / │
│                 ready-to-build on children               │
└─────────────┬──────────────────────────────┬─────────────┘
              │                              │
              ▼ needs-architecture           ▼ needs-design
   ┌──────────────────────┐        ┌────────────────────┐
   │  Architect           │        │  Designer          │
   │  writes ADR;         │        │  writes spec;      │
   │  flips → needs-plan  │        │  flips →           │
   │         or           │        │  ready-to-build    │
   │  ready-to-build      │        │                    │
   └──────────┬───────────┘        └─────────┬──────────┘
              │                              │
              └──────────┬───────────────────┘
                         ▼  ready-to-build
              ┌─────────────────────────┐
              │  Coder                  │
              │  implements; commits;   │
              │  flips → needs-review   │
              └──────────┬──────────────┘
                         ▼  needs-review
              ┌─────────────────────────┐
              │  Reviewer               │
              │  verdict: pass →        │
              │    ready-to-ship        │
              │  verdict: changes →     │
              │    ready-to-build       │
              └──────────┬──────────────┘
                         ▼  ready-to-ship
              ┌─────────────────────────┐
              │  Deployer               │
              │  tags; rollback plan;   │
              │  closes bead            │
              └─────────────────────────┘
```

Every transition is a **label flip on the same bead**. No `gc sling` is run by hand after the initial `needs-plan` label.

---

## Part 1: Read the Labeled-Beads Protocol (~5 min)

Every question W1 raises — *"why did the Architect wake?" "why did the bead move to `ready-to-build`?" "what does the Coder look at to know it's up?"* — is answered in [`software-factory/LABELED_BEADS.md`](../../../LABELED_BEADS.md). Read it before installing anything.

1. The **six canonical labels** table (`needs-architecture`, `needs-plan`, `needs-design`, `ready-to-build`, `needs-review`, `ready-to-ship`).
2. The **example lifecycle** walkthrough — the single worked example of a bead walking the factory.
3. The note on **skipping stages** — a pure-backend bead can skip `needs-design`; a hotfix can skip Planner. The labels, not the pipeline DAG, determine the path.

You do not need to memorize these labels, but you should understand what they are and how they are used. Everything you see this session is an instance of that protocol.

> **Inline Insight: Bead labels are not the only coordination method possible.** Labels on beads are one coordination method, but there are other coordination patterns you'll learn about in W3. That said, they make it very clear which agent is working on which bead, and which bead is ready for which agent.

---

## Part 2: Install the `factory-activity-agent` Skill (~10 min)

The **factory-activity-agent** is the tooling you'll use across every W/L session for setup, teardown, status, and diagnosis. Install it once now; every session after this assumes it is on your path.

### Step 1: Symlink the skill into your coding agent's skills directory

The factory-activity-agent lives in the repo at `skills/factory-activity-agent/`. Symlink it into your coding agent's skills directory so the slash command is available anywhere:

```bash
## Claude Code
cd ~/Projects/actual-software/software-factory-intensive
# Option 1: Symlink into user-level skills (available in all projects)
ln -s "$(pwd)/skills/factory-activity-agent" ~/.claude/skills/factory-activity-agent

# Option 2: Symlink into project-level skills (this project only)
mkdir -p .claude/skills
ln -s "$(pwd)/skills/factory-activity-agent" .claude/skills/factory-activity-agent

# Option 3: Copy into user-level skills
cp -r skills/factory-activity-agent ~/.claude/skills/factory-activity-agent

## Codex
cd ~/Projects/actual-software/software-factory-intensive
ln -sfn "$(pwd)/skills/factory-activity-agent" ~/.codex/skills/factory-activity-agent
```

### Step 2: Verify the skill is installed

Restart your coding agent and run `/factory-activity-agent list` in its session to verify the skill is installed. You should see a table of activities (`W1`-`W4`, `L1`-`L4`, `C1`, `B1`) with their install status. Every row will say `no` — nothing is installed yet. If the slash command isn't recognized, the symlink didn't resolve; re-check the path (see [Common Issues & Solutions](#common-issues--solutions)).

### Step 3: Learn the seven commands you'll use throughout the curriculum

The factory-activity-agent is a wrapper over `gc` + Python scaffolding. You only need four commands for W1, and you'll re-use these across most sessions in the curriculum.

#### `/factory-activity-agent install <activity> [--dry-run]` — stand up a factory for a curriculum activity

The wrapper validates the activity name, pre-flight-checks `gc` and `python3`, then delegates to `scripts/factory_activity_agent.py install <activity>`. Always run a `--dry-run` first if you're unsure what it's about to do — the dry-run prints every command without executing.

#### `/factory-activity-agent delete <activity> [--dry-run]` — delete a factory for a curriculum activity

This command deletes the factory for the given activity. This is helpful if you want to start fresh or if you want to delete a factory that is causing issues.

#### `/factory-activity-agent status <activity> [--dry-run]` — survey factory and agent health

The wrapper runs `bash skills/factory-activity-agent/scripts/status.sh` from the SFI repo root. It prints the `gc` version, a table of curriculum activities and whether each has a factory directory under `~/Projects/factory/`, the output of `gc cities`, then `gc status --city …` for each installed factory so you can see agents, rigs, and service health. This is read-only. `<activity>` tells the agent which factory you care about when interpreting output; the script summarizes every installed factory.

#### `/factory-activity-agent doctor <activity> [--dry-run]` — run Gas City diagnostics (with auto-fix)

The wrapper runs `bash skills/factory-activity-agent/scripts/doctor.sh`. That invokes `gc doctor --fix --city` on each installed factory directory (or on one path if given), checking dependencies, configuration, and authentication and applying fixes where `gc` can. Use this when installs fail mysteriously, agents won’t start, or `gc doctor` reports problems.

#### `/factory-activity-agent sling <activity> [--dry-run]` — route work to a factory agent

This maps to `gc sling` for the activity’s rig (e.g. `w1-project/architect`). You run it from that activity’s project or factory directory (or pass the city path) and provide the agent role and a prompt string—`gc` creates or routes a bead so that agent executes the task. Examples in the skill use `planner`, `architect`, `builder`, and `reviewer`.

#### `/factory-activity-agent dashboard <activity> [--dry-run]` — start the gc web dashboard

This starts `gc dashboard serve --city` for that activity’s factory directory (for example `~/Projects/factory/workshop_w1/w1-project/`). The dashboard listens on `http://localhost:8080` for monitoring agents and sessions. Only one dashboard can bind that port at a time; stop any other instance first.

#### `/factory-activity-agent list <activity> [--dry-run]` — list activities and install status

The wrapper runs `status.sh --list`, which prints the same activity table as `status` (which codes are installed and where the factory dirs live) but skips the detailed per-factory `gc status` sections—useful for a quick “what’s on disk.” You can invoke it as `/factory-activity-agent list` without an activity; `<activity>` is optional context for the agent. This is read-only.

### Step 4: Commit the commands to muscle memory

You will run each of these commands in many activities moving forward. Try exploring the commands with the `--dry-run` flag to see what they will do without actually executing them.

```bash
/factory-activity-agent install W1 --dry-run
/factory-activity-agent delete W1 --dry-run
/factory-activity-agent status W1 --dry-run
/factory-activity-agent doctor W1 --dry-run
/factory-activity-agent sling W1 --dry-run
/factory-activity-agent dashboard W1 --dry-run
/factory-activity-agent list W1 --dry-run
```

---

## Part 2: Install the Fired-Up Pizza Factory (~15 min)

### Step 1: Install the Fired-Up Pizza factory

> **Agent Guide:** Before running a command, explain what it does and what the expected output will be. This is a great opportunity to explain the command and what it does.

With the commands above, you can now install the Fired-Up Pizza factory.
```bash
# In your agent session, run:
/factory-activity-agent install W1
```

This will install all of the required components to run the Fired-Up Pizza factory.

### Step 2: Move into the project workspace directory

```bash
cd ~/Projects/factory/workshop_w1/w1-project
```

This is the project workspace directory. In Gas City, there is a one-to-one mapping between the project workspace and the "rig" the factory works on. Note that the factory itself is installed in a separate directory, the *factory workspace*, at `~/Projects/factory/workshop_w1/w1-gc-factory/`.

### Step 3: Verify the factory is installed

You can now verify the factory is installed by running:
```bash
# In your agent session, run:
/factory-activity-agent status W1
```

As long as you see agnets listed and the rig configured correctly, you can proceed to the next step. You may also run the doctor command to check for potentially missing or broken dependencies:

```bash
# In your agent session, run:
/factory-activity-agent doctor W1
```

---

## Part 3: Walk a Feature Bead Through the Factory (~15 min)

### Step 1: Assign a task to the Planner agent

You are going to "sling" a bead to the Planner agent. Slinging a bead is another way of saying "assign a task to an agent".

```bash
# In your agent session, run:
/factory-activity-agent sling w1-project/planner "Create SPA nextjs for Fired Up Pizza an online pizza ordering application where customers can build custom pizzas, select a pickup or delivery time, and place orders — all within a single-page experience. No payment processing is required; all transactions are handled on-site at pickup/delivery."
```

This will assign the bead to the Planner agent and start the session. The Planner will wake and begin processing the task.

### Step 2: Watch the bead move through the factory

First look at the beads in the factory:

```bash
# See which agent is currently working + what bead they're on
cd ~/Projects/factory/workshop_w1/w1-project
bd list --all

bd show <id>
```

Next, start the city so the agents can start working:

```bash
gc start
```

Then, watch the bead move through the factory:

```bash
# Optional: peek at the agent's live tmux session
gc session peek <rig>/<agent>     # e.g. w1-project/planner
```

Or, you can observe the agents and beads in-action via the dashboard:

```bash
/factory-activity-agent dashboard W1
```

Concretely, here is what you'll see. Label values are what to expect *on the bead*; the bullet underneath is the agent action each label transition describes.

1. **Start** — bead has `needs-plan`. Planner wakes, reads the bead + `docs/PROJECT_MANIFEST.md` + existing beads, and either (a) decomposes it into child beads each labelled for the next stage, or (b) sets `needs-architecture` if it decides new rules are required first. FUP-1 is simple enough that Planner usually decomposes directly.
2. **Post-Plan** — children appear with `needs-design` (UI parts), `needs-architecture` (backend parts), or `ready-to-build` (backend parts). The Designer, Architect, and Builder agents all wake and run in parallel.
3. **Builder picks up work** — the Builder agent picks up the work and begins implementing it. Once complete, beads are flipped to `needs-review`.
4. **Reviewer verdict** — the Reviewer agent reviews the output and either approves it (flips to `ready-to-ship`) or sends it back with notes (flips back to `ready-to-build`).
5. **Deployer picks up work** — the Deployer agent picks up the work and begins deploying it. Once complete, beads are closed.

**Slinging beads was the only human action, and in future sessions you will not be typing prompts at all.** The only human action was one `/factory-activity-agent sling` at Step 1. In future workshops and labs, you will see how a software factory ingests tasks and requirements without a human-in-the-loop.

### Step 3: Inspect the completed work

Once the bead is closed, you can inspect the completed work in the `~/Projects/factory/workshop_w1/w1-project/` directory. The contents of the bead (from `bd show <id>`) should point to the completed work in the rig.

---

## Part 4: Observability — How to Watch a Factory Run (~10 min)

You kept the dashboard open during Part 3; now use the last few minutes to internalize the three observability surfaces you can reach for across every remaining session outside of the `/factory-activity-agent` commands.

### Surface 1 — the web dashboard (`gc dashboard serve`)

Best for: realtime overview, grouped bead queue, which agent is working right now.

Keep `http://localhost:8080` open whenever a factory is running.

### Surface 2 — the beads CLI

Best for: precise per-bead state and history.

```bash
bd list                           # all beads
bd list --label needs-review       # filter by label
bd ready --label needs-plan        # what the Planner's order gate is matching on
bd show <id>                       # every note written by every agent on this bead
bd label list <id>                 # current labels on a single bead
bd label list-all                  # label vocabulary currently in use
```

These are the commands the agents themselves use; seeing the same output gives you the agents' view of the world.

### Surface 3 — gc sessions + events

Best for: drilling into what an agent is doing in a live session.

```bash
gc status                          # all agents, one-line per
gc session list                    # every live session with its state
gc session peek <rig>/<agent>      # snapshot of the agent's tmux session
gc events --follow                 # stream label transitions + session lifecycle
```

`gc events --follow` is the most useful flag of the three — it's the verbose log of every label flip and agent wake. If the factory stalls, this is where you look first.

---

> **Inline Insight: Why Participants Don't Write Code This Session**
>
> A reasonable thing to want on your first hands-on is to type *something* — to feel productive. W1 deliberately denies that. The whole point is that **the factory types for you**: you place a ticket, the agents take it from there. If you find yourself wanting to "just open `src/menu/MenuPage.tsx` and tweak that one line," notice the feeling — it's the exact habit the workshop exists to unbuild. The place for your customization is the agent packs in L2–L4, not the source code in `src/`. W1 is where you see that the customization location has moved.

---

## Common Issues & Solutions

### Issue 1: `/factory-activity-agent list` isn't recognized by Claude Code

<details>
<summary>Solution</summary>

**Cause:** The symlink at `~/.claude/skills/factory-activity-agent` didn't resolve, or Claude Code hasn't rescanned the skills directory.

**Fix:** Re-check `ls -l ~/.claude/skills/factory-activity-agent` — it should show a working symlink into the repo. Restart Claude Code. If still missing, copy the directory in instead of symlinking (`cp -r software-factory/factory-activity-agent ~/.claude/skills/factory-activity-agent`).

</details>

### Issue 2: `gc rig add` fails with a missing `.gc/...` file (e.g. `gc-beads-bd`)

<details>
<summary>Solution</summary>

**Cause:** The factory directory has `city.toml` but **`gc init` was never run**, so `.gc/` was never created.

**Fix:** From the factory directory, `gc init --file city.toml .`, then retry `gc rig add`. If `gc init --file` conflicts with an existing `city.toml`, use the merge workaround in Step 3.

</details>

### Issue 3: `gc rig add` reports "path does not exist"

<details>
<summary>Solution</summary>

**Cause:** You passed a relative path from a directory where the rig isn't reachable, or the absolute path typo'd.

**Fix:** Use an absolute path. `cd` to the repo and use `$(pwd)`:

```bash
cd ~/Projects/actual-software/software-factory-intensive/software-factory/reference-project
gc rig add "$(pwd)"
```

</details>

### Issue 4: `gc start` succeeds but `gc status` shows all six agents as dead / red

<details>
<summary>Solution</summary>

**Cause:** The `includes` path in `city.toml` still points at `/abs/path/to/...` (you forgot to substitute), or the provider (`claude` vs `codex`) doesn't match what you have installed.

**Fix:** `cat city.toml` and confirm the include resolves (`ls` on the path prints the `pack.toml`). If it does, re-check `provider = ...` matches a CLI on your PATH, then `gc restart`.

</details>

### Issue 5: Planner doesn't wake after `bd label add <id> needs-plan`

<details>
<summary>Solution</summary>

**Cause:** Either the order gate isn't registered, or the label you added isn't exactly `needs-plan` (capitalization matters; trailing spaces matter).

**Fix:** `bd label list <id>` — does it show `needs-plan` exactly? Then `gc order list` — is the Planner's intake order present? If neither surfaces a problem, `gc doctor --fix`. Common sneaky cause: the factory was started before you registered the rig; restart with `gc restart`.

</details>

### Issue 6: Two agents race on the same file in the rig

<details>
<summary>Solution</summary>

**Cause:** Parallel children of FUP-1 both landed in `ready-to-build` and two Coder sessions picked them up simultaneously — both are editing `src/menu/`.

**Fix:** This is rare with a fresh factory. When it happens, the later write wins and the earlier session errors out. Close the stray bead (`bd close <id> --reason "duplicate"`) and re-label the kept one. The real fix — serializing concurrent work via bead dependencies — is introduced in W3 (coordination primitives); for W1 just note the behavior.

</details>

### Issue 7: Dashboard shows the bead stuck on `ready-to-build` and no Coder session starts

<details>
<summary>Solution</summary>

**Cause:** The rig's `package.json` is missing dependencies the Coder needs to run tests (`npm ci` has never been run), so the Coder errors out instantly on boot. This happens on a freshly-cloned repo.

**Fix:**

```bash
cd ~/Projects/actual-software/software-factory-intensive/software-factory/reference-project
npm ci
```

Then `gc restart` to pick up the change.

</details>

### Issue 8: `gc dashboard serve` fails with "address already in use"

<details>
<summary>Solution</summary>

**Cause:** Another factory (probably from a previous session) has a dashboard on :8080.

**Fix:** `lsof -i :8080` to find the process; kill it; retry. Or `gc dashboard serve --port 8081` if you want both running.

</details>

### Issue 9: The Reviewer keeps returning `request-changes` and the Coder re-cycles

<details>
<summary>Solution</summary>

**Cause:** The Coder is regenerating the same issue because the shipped coder prompt is generic. That's expected — customizing the coder for your project is L3's entire job; you'll see the fix-via-config discipline land then.

**Fix (for W1 specifically):** nothing. Let it cycle. The point of this session is to see the pipeline move, not to produce merge-ready code. If it cycles more than three times on the same finding, stop the factory (`gc stop`) and call a facilitator over — the failure mode might be worth walking the room through.

</details>

### Issue 10: `import-tickets.sh` printed warnings like "failed to create FUP-2"

<details>
<summary>Solution</summary>

**Cause:** Your `bd` database already has beads with matching titles from a previous workshop run.

**Fix:** Either clear the prior state (`bd list` + close or delete duplicates) or continue — the script is idempotent-ish; duplicates just don't get re-imported. `bd list` should still show at least FUP-1 through FUP-6 once.

</details>

---

## Exit Criteria

Before leaving this workshop, verify all of these:

- [ ] `~/.claude/skills/factory-activity-agent` (or `~/.codex/skills/factory-activity-agent` or other agent's skills directory) resolves to the repo
- [ ] `/factory-activity-agent status` responds with accurate factory information and lists your factory directory under *Installed Activities* / *Registered Cities*
- [ ] `/factory-activity-agent dashboard` shows six agents as running (idle or working — not dead)
- [ ] At least one output produced by the factory

**W1 is the foundation for everything that follows.** W2 (next) shifts you from "watching the reference factory run" to "understanding what the agents consume and emit so you can configure them for your own project." L1 installs the factory on your project. L2–L4 customize each agent pack.

---

## Quick Reference: What You Built

| Component | Location | What It Does |
|-----------|----------|--------------|
| `/factory-activity-agent` skill | `~/.claude/skills/factory-activity-agent` → `software-factory/factory-activity-agent` | Slash command and Python wrapper for `install` / `delete` / `status` / `doctor` / `sling` / `dashboard` / `list` |
| Fired-Up Pizza factory workspace | `~/Projects/factory/workshop_w1/w1-project/` | Your live reference Gas City workspace — `city.toml`, registered rig and agents |

---

## Next Steps

**[W2](../W2/README.md)** turns the lens inward: *how* do the agents do their job? You'll trace a feature bead through the six packs, read each agent's prompt template + formula, and start building the mental model you'll need in L1/L2 when the packs become *your* configuration to edit.

**[L1](../L1/README.md)** is where the factory becomes *yours*. You'll register your own project as the rig, point the six shipped packs at it, and watch the same cycle you just saw run against *your* codebase's first feature bead.
