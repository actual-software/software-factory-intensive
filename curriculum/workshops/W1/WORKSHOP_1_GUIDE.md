# W1 · Run the 6-Agent Software Factory

> **Goal:** Prepare your environment to be software factory-ready, and demonstrate it with a fully functional model software factory — a real task flowing end-to-end through autonomous agents without human intervention.

| | |
|---|---|
| **Estimated duration** | ~60 minutes |
| **Type** | Workshop |
| **Deliverable** | A running Fired-Up Pizza factory on your machine, with at least one bead visibly re-labelled by each of the six agents and inspectable via the dashboard |

---

## Overview

You will take a machine with `gc` and this repo and end with a **running six-agent Gas City factory** that uses the **Fired-Up Pizza** app as its rig: one human sling at the start, then autonomous label flips and handoffs through Planner, Architect, Designer, Builder, Reviewer, and Deployer until work ships.

**Part 1** has you read [`LABELED_BEADS.md`](../../../LABELED_BEADS.md) first so every later question — *why did this agent wake?* *why this label?* — has an answer. **Part 2** installs the [`factory-activity-agent`](../../../skills/factory-activity-agent/) skill and the seven slash commands you reuse for every W/L session. **Part 3** runs `install W1`, which creates two directories under `~/Projects/factory/workshop_w1/`: the **factory** (`w1-gc-factory`, Gas City + packs) and the **rig** (`w1-project`, git repo and code). **Part 4** is the proof: sling one bead and watch it traverse the pipeline. **Part 5** cements observability — dashboard, `bd`, and `gc` sessions/events — so you know where to look when something stalls.

Together, those steps produce the stated deliverable: environment ready for the curriculum, plus a concrete end-to-end run you can inspect in the dashboard and in `bd show`.

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

> **Goal:** Understand the shared protocol that lets multiple autonomous agents collaborate without stepping on each other, so the rest of the session is legible rather than magic.

Every question W1 raises — *"why did the Architect wake?" "why did the bead move to `ready-to-build`?" "what does the Coder look at to know it's up?"* — is answered in [`software-factory/LABELED_BEADS.md`](../../../LABELED_BEADS.md). Read it before installing anything.

1. The **six canonical labels** table (`needs-architecture`, `needs-plan`, `needs-design`, `ready-to-build`, `needs-review`, `ready-to-ship`).
2. The **example lifecycle** walkthrough — the single worked example of a bead walking the factory.
3. The note on **skipping stages** — a pure-backend bead can skip `needs-design`; a hotfix can skip Planner. The labels, not the pipeline DAG, determine the path.

You do not need to memorize these labels, but you should understand what they are and how they are used. Everything you see this session is an instance of that protocol.

> **Insight: A shared protocol is what separates a factory from six chatbots.**
>
> The six labels aren't metadata — they're the assembly line. Without them, every handoff would need a human saying "Architect, Planner is done, you're up." The protocol is what lets specialists coordinate without a conductor. It's the invisible infrastructure that makes autonomy possible; every W/L session after this one runs on the same rails.

---

## Part 2: Install the `factory-activity-agent` Skill (~10 min)

> **Goal:** Equip your environment with the shared tooling you'll use to set up, tear down, and diagnose every factory across the curriculum — one install now, no repeated setup later.

The **factory-activity-agent** is the tooling you'll use across every W/L session for setup, teardown, status, and diagnosis. Install it once now; every session after this assumes it is on your path. In this repo it lives under [`skills/factory-activity-agent/`](../../../skills/factory-activity-agent/); [`SKILL.md`](../../../skills/factory-activity-agent/SKILL.md) is the canonical entry, with Bash helpers under [`scripts/`](../../../skills/factory-activity-agent/scripts/) and `install` / `delete` implemented by [`scripts/factory_activity_agent.py`](../../../scripts/factory_activity_agent.py) at the repo root.

### Step 1: Install the skill into your coding agent

Follow the installation steps in [`docs/factory-activity-agent-commands.md`](../../../docs/factory-activity-agent-commands.md#installation) to symlink (or copy) the skill into your coding agent's skills directory. The guide covers Claude Code and Codex, and gives you three options for where to place it (user-level vs project-level, symlink vs copy).

You only do this once — every session after W1 assumes the skill is on your path.

### Step 2: Verify the skill is installed

Restart your coding agent and run `/factory-activity-agent list` in its session to verify the skill is installed. You should see a table of activities (`W1`-`W4`, `L1`-`L4`, `C1`, `B1`) with their install status. Every row will say `no` — nothing is installed yet. If the slash command isn't recognized, the symlink didn't resolve; see [Troubleshooting CLI coding agents](../../../troubleshooting/cli-coding-agents.md).

### Step 3: Learn the seven commands you'll use throughout the curriculum

The factory-activity-agent is a wrapper over `gc` + Python scaffolding. You'll re-use these commands across most sessions in the curriculum, so it's worth knowing what's in the toolbox before you start pulling things out of it:

- `/factory-activity-agent install <activity>` — stand up a factory for a curriculum activity
- `/factory-activity-agent delete <activity>` — tear down a factory
- `/factory-activity-agent status <activity>` — survey factory and agent health
- `/factory-activity-agent doctor <activity>` — run Gas City diagnostics (with auto-fix)
- `/factory-activity-agent sling <activity>` — route work to a factory agent
- `/factory-activity-agent dashboard <activity>` — start the gc web dashboard
- `/factory-activity-agent list` — list activities and install status

Every command takes a `--dry-run` flag that prints what it *would* do without executing — the fastest way to explore one is to run it with `--dry-run` and read the commands it prints.

For the detailed reference on what each command does under the hood, when to reach for it, and which `gc` or script calls it delegates to, see [`docs/factory-activity-agent-commands.md`](../../../docs/factory-activity-agent-commands.md). Keep it open in a tab; you'll come back to it throughout the curriculum.

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

## Part 3: Install the Fired-Up Pizza Factory (~15 min)

> **Goal:** Stand up a working reference factory on your machine that you can point at a real project and verify end-to-end before trusting it with your own work.

### Step 1: Install the Fired-Up Pizza factory

With the commands above, you can now install the Fired-Up Pizza factory.
```bash
# In your agent session, run:
/factory-activity-agent install W1
```

This copies the W1 workshop Gas City packs from `activities/workshops/W1/gascity/step_0/packs/` into your factory workspace and wires the rig. For a browsable view of the **fired-up-pizza** composite packaging in-repo, see [`packs/fired-up-pizza/`](../../../packs/fired-up-pizza/). The curriculum’s **reference** app (what the rig is modeled on) lives at [`reference-project/fired-up-pizza/`](../../../reference-project/fired-up-pizza/) — React + TypeScript + SQLite, with `docs/PROJECT_MANIFEST.md`, `tickets.md`, and `package.json`; your installed rig under `~/Projects/factory/workshop_w1/w1-project/` is the working copy the agents mutate.

### Step 2: Move into the project workspace directory

```bash
cd ~/Projects/factory/workshop_w1/w1-project
```

This is the **rig** — your git repo for code, beads, and deliverables. The **factory** (Gas City `city.toml`, agent packs, where most `gc` commands assume your cwd) lives next door at `~/Projects/factory/workshop_w1/w1-gc-factory/`; run `gc start`, `gc status`, and similar from that directory unless a step says otherwise.

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

## Part 4: Walk a Feature Bead Through the Factory (~15 min)

> **Goal:** See a real task travel end-to-end through an autonomous team — from initial request to shipped work — with your only action being to hand off the task at the start.

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

Next, start the city so the agents can start working (from the **factory** directory):

```bash
cd ~/Projects/factory/workshop_w1/w1-gc-factory
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

## Part 5: Observability — How to Watch a Factory Run (~10 min)

> **Goal:** Build the situational awareness you need to see what a running factory is doing — so when something stalls or surprises you, you know where to look.

You kept the dashboard open during Part 4; now use the last few minutes to internalize the three observability surfaces you can reach for across every remaining session outside of the `/factory-activity-agent` commands.

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

> **Insight: Why Participants Don't Write Code This Session**
>
> A reasonable thing to want on your first hands-on is to type *something* — to feel productive. W1 deliberately denies that. The whole point is that **the factory types for you**: you place a ticket, the agents take it from there. If you find yourself wanting to "just open `src/menu/MenuPage.tsx` and tweak that one line," notice the feeling — it's the exact habit the workshop exists to unbuild. The place for your customization is the agent packs in L2–L4, not the source code in `src/`. W1 is where you see that the customization location has moved.

---

## Common Issues & Solutions

If you hit a problem during W1, jump to the relevant topic-scoped guide in [`troubleshooting/`](../../../troubleshooting/README.md), such as [Troubleshooting Gas City (`gc`)](../../../troubleshooting/gas-city.md) or [Troubleshooting beads (`bd`)](../../../troubleshooting/beads.md).

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
| `/factory-activity-agent` skill | `~/.claude/skills/factory-activity-agent` → repo [`skills/factory-activity-agent/`](../../../skills/factory-activity-agent/) | Slash command; `install` / `delete` via [`scripts/factory_activity_agent.py`](../../../scripts/factory_activity_agent.py); other verbs via Bash helpers in [`skills/factory-activity-agent/scripts/`](../../../skills/factory-activity-agent/scripts/) |
| Fired-Up Pizza **rig** (project) | `~/Projects/factory/workshop_w1/w1-project/` | Git repo — source, `.beads/`, deliverables |
| Fired-Up Pizza **factory** (Gas City city) | `~/Projects/factory/workshop_w1/w1-gc-factory/` | `city.toml`, synced packs, supervisor — run `gc` here unless noted |

---

## Next Steps

**[W2](../W2/README.md)** turns the lens inward: *how* do the agents do their job? You'll trace a feature bead through the six packs, read each agent's prompt template + formula, and start building the mental model you'll need in L1/L2 when the packs become *your* configuration to edit.

**[L1](../L1/README.md)** is where the factory becomes *yours*. You'll register your own project as the rig, point the six shipped packs at it, and watch the same cycle you just saw run against *your* codebase's first feature bead.
