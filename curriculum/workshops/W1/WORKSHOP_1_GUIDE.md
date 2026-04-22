# W1 · Run the 6-Agent Software Factory

> **Goal:**
Prepare your environment to be software factory-ready, and demonstrate it by running a multi-agent software factory that delivers basic software features without human intervention.

| | |
|---|---|
| **Estimated duration** | ~60 minutes |
| **Type** | Workshop |
| **Deliverable** | A running Fired Up Pizza factory on your machine, with a set of initial tasks being processed by agents |

## Deliverable

By the end of this workshop, you will have:

- The `factory-activity-agent` skill installed in your coding agent and reachable as `/factory-activity-agent`.
- A running 6-agent factory at `~/Projects/factory/workshop_w1/w1-gc-factory/` operating against the Fired Up Pizza reference project at `~/Projects/factory/workshop_w1/w1-project/`.
- The FUP-1 … FUP-6 backlog imported as beads and visibly moving through Planner → Architect → Designer → Coder → Reviewer → Deployer.
- Hands-on familiarity with the three observability surfaces (web dashboard, `bd`, `gc events --follow`) you will use for the rest of the curriculum.

W1 runs against the reference project so nothing produced here is required as input to later sessions — the workshop is the warmup. The skill install, however, is assumed by every session after this one.

## Overview

In this workshop, you'll get hands-on with a 6-agent software factory using the Gas City framework and this repo. The high-level goal: demonstrate how feature requests flow through Planner, Architect, Designer, Builder (Coder), Reviewer, and Deployer for the **Fired Up Pizza** project, with each agent using labels to manage task status and handing off work without human intervention.

Through this workshop you will:
- Explore the Fired Up Pizza project and its 6-agent software factory
- Understand the basic logic behind agent wakeups and task assignment
- Learn to use core agent orchestration tools (`factory-activity-agent` skill, slash commands)
- Observe the complete automated pipeline as one task moves through every stage
- Use multiple observability surfaces to monitor, debug, and understand factory state

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
              │  closes task            │
              └─────────────────────────┘
```

Every transition is triggered by a label flip on a task bead by an agent.

## Part 1: Read about the labeled beads protocol (10 min)

> **Goal:** Understand the basic coordination principles that allow agents to collaborate on shared work, establishing the conceptual foundation for inter-agent communication that underpins software factories.

Software factories implemented with Gas City use a graph-based framework called `beads` to manage task dependencies and status. These "beads" are the basic unit of work in the factory, and are manipulated by the agents in the process of producing software. They can include priorities, dependencies on other tasks, notes from agents, and other metadata. For more information on beads, see [gastownhall/beads](https://github.com/gastownhall/beads).

For the purpose of this workshop, a simple label protocol is added on top of the beads framework to manage task status and handoff. Every question W1 raises — *"why did the Architect wake?" "why did the task move to `ready-to-build`?" "what does the Coder look at to know what to build?"* — is answered in [`docs/labeled-beads.md`](../../../docs/labeled-beads.md). Read it before installing anything.

1. The **six canonical labels** table (`needs-architecture`, `needs-plan`, `needs-design`, `ready-to-build`, `needs-review`, `ready-to-ship`).
2. The **example lifecycle** walkthrough — the single worked example of a bead walking the factory.
3. The note on **skipping stages** — a pure-backend bead can skip `needs-design`; a hotfix can skip Planner. The labels, not the pipeline DAG, determine the path.

You do not need to memorize these labels, but you should understand what they are and how they are used. Everything you see this session uses this labeling protocol.

> **Insight: A shared protocol is what separates a factory from six chatbots.**
>
> The six labels aren't metadata — they're the assembly line. Without them, every handoff would need a human saying "Architect, Planner is done, you're up." The protocol is what lets specialists coordinate without a conductor. It's the invisible infrastructure that makes autonomy possible; every workshop and lab after this one runs on the same rails.

## Part 2: Install the `factory-activity-agent` Skill (10 min)

> **Goal:** Install the common tooling you will rely on throughout the curriculum, so that every subsequent session begins from a consistent, known-good starting point.

The **factory-activity-agent** is the tooling you'll use across every workshop and lab for setup, teardown, status, and diagnosis. Install it once now; every session after this assumes it is on your path. In this repo it lives under [`skills/factory-activity-agent/`](../../../skills/factory-activity-agent/); [`SKILL.md`](../../../skills/factory-activity-agent/SKILL.md) is the canonical entry, with Bash helpers under [`scripts/`](../../../skills/factory-activity-agent/scripts/) and `install` / `delete` implemented by [`scripts/factory_activity_agent.py`](../../../scripts/factory_activity_agent.py) at the repo root.

### Step 1: Install the skill into your coding agent

Follow the installation steps in [`docs/factory-activity-agent.md`](../../../docs/factory-activity-agent.md#installation) to symlink (or copy) the skill into your coding agent's skills directory. The guide covers Claude Code and Codex, and gives you three options for where to place it (user-level vs project-level, symlink vs copy).

You only do this once — every session after W1 assumes the skill is on your path.

### Step 2: Verify the skill is installed

Restart your coding agent and run `/factory-activity-agent list` in its session to verify the skill is installed. You should see a table of activities (`W1`-`W4`, `L1`-`L4`, `C1`, `B1`) with their install status. Every row will say `no` — nothing is installed yet. If the slash command isn't recognized, the symlink didn't resolve; see [Troubleshooting CLI coding agents](../../../troubleshooting/cli-coding-agents.md).

### Step 3: Learn the seven commands you'll use throughout the curriculum

The factory-activity-agent is a wrapper over `gc` and `python` scaffolding. You'll re-use these commands across most sessions in the curriculum, so it's worth knowing what's in the toolbox before you start pulling things out of it:

- `/factory-activity-agent install <activity>` — stand up a factory for a curriculum activity
- `/factory-activity-agent delete <activity>` — tear down a factory
- `/factory-activity-agent status <activity>` — survey factory and agent health
- `/factory-activity-agent doctor <activity>` — run Gas City diagnostics (with auto-fix)
- `/factory-activity-agent sling <activity>` — route work to a factory agent
- `/factory-activity-agent dashboard <activity>` — start the gc web dashboard
- `/factory-activity-agent list` — list activities and install status

Every command takes a `--dry-run` flag that prints what it *would* do without executing — the fastest way to explore one is to run it with `--dry-run` and read the commands it prints.

For the detailed reference on what each command does under the hood, when to reach for it, and which `gc` or script calls it delegates to, see [`docs/factory-activity-agent.md`](../../../docs/factory-activity-agent.md). Keep it open in a tab; you'll come back to it throughout the curriculum.

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

## Part 3: Install the Fired Up Pizza Factory (10 min)

> **Goal:** Bring up a reference factory and confirm it operates correctly, establishing a working baseline you can compare against when configuring factories for your own projects later in the curriculum.

### Step 1: Install the Fired Up Pizza factory

With the commands above, you can now install the Fired Up Pizza factory.
```bash
# In your agent session, run:
/factory-activity-agent install W1
```

This copies the W1 workshop Gas City packs from `activities/workshops/W1/gascity/step_0/packs/` into your factory workspace, in addition to the [PROJECT_MANIFEST.md](./docs/PROJECT_MANIFEST.md). For a browsable view of the **fired-up-pizza** composite packaging in-repo, see [`packs/fired-up-pizza/`](../../../packs/fired-up-pizza/). The curriculum’s **reference** app lives at [`reference-project/fired-up-pizza/`](../../../reference-project/fired-up-pizza/), with `docs/PROJECT_MANIFEST.md`, `tickets.md`, and `package.json`; your installed rig under `~/Projects/factory/workshop_w1/w1-project/` is the working copy the agents mutate.

### Step 2: Move into the factory directory

```bash
cd ~/Projects/factory/workshop_w1/w1-gc-factory
```

This is the home of your factory. It contains a Gas City `city.toml`, agent packs, and other configuration files for the factory. You can run `gc start`, `gc status`, and similar commands from this directory to supervise the factory. The project workspace, known in Gas City as a "rig", is next door at `~/Projects/factory/workshop_w1/w1-project/`.

### Step 3: Verify the factory is installed

You can now verify the factory is installed by running:
```bash
# In your agent session
/factory-activity-agent status W1
```

As long as you see agents listed and the rig configured correctly, you can proceed to the next step. You may also run the doctor command to check for potentially missing or broken dependencies:

```bash
# In your agent session
/factory-activity-agent doctor W1
```

## Part 4: Walk a Feature Task Through the Factory (15 min)

> **Goal:** Learn how a feature task progresses through each stage of the factory line, forming a clear understanding of the path from initial request to final delivered feature.

### Step 1: Import the Fired Up Pizza task backlog

The project workspace was seeded with two files during install:

- `tickets.md` — the initial FUP-1 … FUP-6 backlog, copied from [`reference-project/fired-up-pizza/tickets.md`](../../../reference-project/fired-up-pizza/tickets.md).
- `scripts/import-tickets.sh` — a thin wrapper that parses `tickets.md` and calls `bd create` for each entry, copied from [`packs/fired-up-pizza/scripts/import-tickets.sh`](../../../packs/fired-up-pizza/scripts/import-tickets.sh).

Inside the factory directory, run this to import the list of tickets:

```bash
bash ./../w1-project/scripts/import-tickets.sh ../w1-project/tickets.md
```

### Step 2: Switch to the project directory and observe the tasks queued in the project

```bash
cd ~/Projects/factory/workshop_w1/w1-project
bd list --all
bd show <task-id>
```

Each ticket is created with `--labels needs-plan`, so every task lands on the Planner's order gate (`bd ready --label=needs-plan`) the moment the factory wakes. `bd list` should now show six tasks titled after FUP-1 through FUP-6. No need to prompt the Planner, since the label is the trigger for the agent to wake and start working.

If the tasks are loaded correctly, you should see something like this:

```bash
 ~/Projects/factory/workshop_w1/w1-gc-factory $ bd list --all
○ wp-269 ● P0 Pizza customization
○ wp-k04 ● P0 Shopping cart
○ wp-roo ● P0 Menu display page
○ wp-dzh ● P1 Order status tracking
○ wp-ulo ● P1 Order placement
○ wp-lju ● P2 Order history page

--------------------------------------------------------------------------------
Total: 6 issues (6 open, 0 in progress)

Status: ○ open  ◐ in_progress  ● blocked  ✓ closed  ❄ deferred
```

Next, start the factory so the agents can start working (from the **factory** directory):

```bash
cd ~/Projects/factory/workshop_w1/w1-gc-factory
gc start
```

If you run into an error like `standalone controller already running...`, please read the troubleshooting guide in [`troubleshooting/gas-city.md`](../../../troubleshooting/gas-city.md).

Then, watch the task move through the factory:

```bash
# Optional: peek at the agent's live tmux session
gc session peek <rig>/<agent>     # e.g. w1-project/planner
```

Or, you can observe the agents and tasks in-action via the dashboard:

```bash
/factory-activity-agent dashboard W1
```

Concretely, here is what you'll see. Label values are what to expect *on the task*; the bullet underneath is the agent action each label transition describes.

1. **Start** — task has `needs-plan`. Planner wakes, reads the task bead, `docs/PROJECT_MANIFEST.md`, and existing task beads, and either (a) decomposes it into child beads each labelled for the next stage, or (b) sets `needs-architecture` if it decides new rules are required first.
2. **Post-Plan** — child tasks appear with `needs-design` (UI parts), `needs-architecture` (backend parts), or `ready-to-build` (backend parts). The Designer, Architect, and Builder agents all wake and run in parallel to implement the child tasks.
3. **Builder picks up work** — the Builder agent picks up the work and begins implementing it. Once complete, tasks are flipped to `needs-review`.
4. **Reviewer verdict** — the Reviewer agent reviews the output and either approves it (flips to `ready-to-ship`) or sends it back with notes (flips back to `ready-to-build`).
5. **Deployer picks up work** — the Deployer agent picks up the work and begins deploying it. Once complete, tasks are closed.

**Importing tasks was the only human action, and in future sessions you may not even need to do that.** The only human action was one shell command at Step 1. In future workshops and labs, you will explore how a software factory can ingest tasks and requirements without a specific import step.

### Step 3: Inspect the completed work

Once the task is closed, you can inspect the completed work in the `~/Projects/factory/workshop_w1/w1-project/` directory. The contents of the task (from `bd show <id>`) should point to the completed work in the project.

## Part 5: Observability — How to Watch a Factory Run (10 min)

> **Goal:** Become familiar with the primary observability surfaces of a running factory, so you can independently monitor its progress and diagnose issues throughout the remainder of the curriculum.

You kept the dashboard open during Part 4; now use the last few minutes to internalize the three observability surfaces you can reach for across every remaining session outside of the `/factory-activity-agent` commands.

### Surface 1 — the web dashboard (`/factory-activity-agent dashboard <activity>`)

Best for: realtime overview, grouped task queue, which agent is working right now.

Keep `http://localhost:8080` open whenever a factory is running.

### Surface 2 — the beads CLI

Best for precise per-bead task state and history.

```bash
bd list                           # all beads
bd list --label needs-review       # filter by label
bd ready --label needs-plan        # what the Planner's order gate is matching on
bd show <id>                       # every note written by every agent on this bead
bd label list <id>                 # current labels on a single bead
bd label list-all                  # label vocabulary currently in use
```

These are the commands the agents themselves use; seeing the same output gives you the agents' view of the world.

### Surface 3 — Gas City sessions and events

Best for: drilling into what an agent is doing in a live session.

```bash
gc status                          # all agents, one-line per
gc session list                    # every live session with its state
gc session peek <rig>/<agent>      # snapshot of the agent's tmux session
gc events --follow                 # stream label transitions and session lifecycle
```

`gc events --follow` is the most useful flag of the three — it's the verbose log of every label flip and agent wake. If the factory stalls, this is where you look first.

## Part 6: Add Your Own Feature Request (5 min, optional)

> **Goal:** Close the loop by adding a task to the backlog yourself — proving the factory accepts new work at any time, not just at install, and that authoring a ticket is the entire shape of your contribution.

The factory is still running. Pick any small feature you wish Fired Up Pizza had — a "today's special" banner, a loyalty-points badge, a nearest-store lookup — and hand it to the Planner the same way the workshop sling works elsewhere in the curriculum:

```bash
cd ~/Projects/factory/workshop_w1/w1-gc-factory
gc bd --rig w1-project create \
  --title "<YOUR_FEATURE_REQUEST>" \
  --label needs-plan
```

What to expect:

1. `gc bd create` creates a new task with the title as its description and routes it to the Planner with the `needs-plan` label.
2. The Planner wakes, decomposes the request, and hands child tasks to Architect / Designer / Builder just like it did for FUP-1.
3. Your task flows through the same five transitions you watched in Part 4 — alongside any FUP-* tasks still in flight.

Track it with the surfaces from Part 5: the dashboard groups it into the right column as its label flips, `gc events --follow` streams the transitions, and `bd show <id>` carries every note each agent writes.

There is no limit on how many tasks you sling — each one is another order the gate can match. If you want to stress the factory, sling two or three requests in quick succession and see the pools fan out. This is the same mechanism L1 will use when the backlog becomes *your* project's tickets instead of Fired Up Pizza's.

> **Insight: Why Participants Don't Write Code This Session**
>
> A reasonable thing to want on your first hands-on is to type *something* — to feel productive. W1 deliberately denies that. The whole point is that **the factory types for you**: you place a ticket, the agents take it from there. If you find yourself wanting to "just open `src/menu/MenuPage.tsx` and tweak that one line," notice the feeling — it's the exact habit the workshop exists to unbuild. The place for your customization is the agent packs in L2–L4, not the source code in `src/`. W1 is where you see that the customization location has moved.

## Common Issues and Solutions

If you hit a problem during W1, jump to the relevant topic-scoped guide in [`troubleshooting/`](../../../troubleshooting/README.md), such as [Troubleshooting Gas City (`gc`)](../../../troubleshooting/gas-city.md) or [Troubleshooting beads (`bd`)](../../../troubleshooting/beads.md).

## Exit Criteria

Before leaving this workshop, verify all of these:

- [ ] `~/.claude/skills/factory-activity-agent` (or `~/.codex/skills/factory-activity-agent` or other agent's skills directory) resolves to the repo
- [ ] `/factory-activity-agent status` responds with accurate factory information and lists your factory directory under *Installed Activities* / *Registered Cities*
- [ ] `/factory-activity-agent dashboard` shows agents in progress on tasks

## Next Steps

**[W2](../W2/README.md)** turns the lens inward: *how* do the agents do their job? You'll trace a new feature through the six packs, read each agent's prompt template and formula, and start building the mental model you'll need in L1/L2 when the packs become *your* configuration to edit.

**[L1](../L1/README.md)** is where the factory becomes *yours*. You'll register your own project as the workspace rig, point the six shipped packs at it, and watch the same cycle you just saw run against *your* codebase's first feature task.
