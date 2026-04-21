# L1 · Build a Structured Development Loop

> **Goal:** Understand how the configuration of a software factory depends on the nature of the project it is building, and how to adapt the configuration to the specific needs of the project.

| | |
|---|---|
| **Estimated duration** | ~60 minutes |
| **Type** | LAB |
| **Deliverable** | Working 6-agent software factory applied to your software project, with the `PROJECT_MANIFEST.md` and setup of the inputs on the Planner agent (feature requests, knowledge bases, and other artifacts) |

## Overview

W1 ran a factory against a reference project that was already fully wired. W2 mapped the capabilities from your individual workflow onto the six stages and produced a `factory-pipeline.md`. L1 is where those two halves meet: you install a factory against **your project**, with the `PROJECT_MANIFEST.md` grounding every agent, and capabilities pulled from the `factory-pipeline.md` mapped to the agents.

Through this lab you will:
- Install a 6-agent factory workspace against your own project
- Set up the `PROJECT_MANIFEST.md` file that grounds every agent
- Explore how agents in your software factory can leverage your existing solo AI workflow capabilities.

## What You'll Build

```
        factory-pipeline.md (from W2)
                  │
                  ▼
┌──────────────────────────────────────────────────────────┐
│                   PROJECT_MANIFEST.md                    │
│  Overview · Tech Stack · Domain Model · Conventions      │
│  Review Standards · Release Criteria · Task Inputs       │
└───────┬──────────────────────────────────────────────────┘
        │  every agent reads this before acting
        ▼
┌──────────────────────────────────────────────────────────┐
│   6-agent factory installed against YOUR project         │
│                                                          │
│   Planner ──▶ Architect ──▶ Designer ──▶ Coder           │
│       ▲                                     │            │
│       │                                     ▼            │
│  input sources                     Reviewer ──▶ Deployer │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## Part 1: Install the L1 Factory Against Your Project (10 min)

> **Goal:** Stand up the factory workspace and point it at your own project repository, so every later step operates against your real code rather than a reference.

### Step 1: Install L1

```bash
# In your agent session, run:
/factory-activity-agent install L1
```

### Step 2: Point the workspace at your project

L1 starts with a mostly-empty project workspace on purpose — you bring the code. Pour your project into it alongside the scaffolding the install created:

```bash
cp -R ~/path/to/your-repo/. ~/Projects/factory/lab_l1/l1-project/
```

This merges your code into the installed workspace. Do **not** `rm -rf` the installed workspace or replace it with a symlink — the install registered the path with the factory (the `gc rig add` step), so deleting or swapping it out leaves the registration dangling.

### Step 3: Copy the `PROJECT_MANIFEST.md` file from your W2 workspace into the L1 workspace

```bash
cp ~/Projects/factory/workshop_w1/w1-project/docs/PROJECT_MANIFEST.md \
   ~/Projects/factory/lab_l1/l1-project/docs/PROJECT_MANIFEST.md
```

### Step 4: Carry forward the `factory-pipeline.md` file from your W2 workspace

Install the `factory-pipeline.md` file from your W2 workspace into the L1 workspace:

```bash
cp ~/Projects/factory/workshop_w2/w2-project/docs/factory-pipeline.md \
   ~/Projects/factory/lab_l1/l1-project/docs/factory-pipeline.md
```

If W2 wasn't installed, the carry-forward is skipped silently — install W2 first if you want your capability map on hand during Part 2.

### Step 5: Verify the factory is healthy

```bash
/factory-activity-agent status L1
/factory-activity-agent doctor L1
```

You should see all agents listed. No task has been seeded yet — agents will idle until you wire the Planner's inputs in Part 3.

## Part 2: Send the first task to the factory (20 min)

> **Goal:** Demonstrate how the generic software factory can be applied to your own project, although without any customization.

### Step 1: Decide what small change or feature to send to the factory

Pick a small change or feature that your project actually needs. For example, you could:

- Add a new page to the website
- Add a new feature to the API
- Add a new feature to the mobile app
- Add a new feature to the desktop app
- Add a new feature to the backend
- Add a new feature to the frontend

Note that the feature may not be implemented well in the current state of the factory. The next step will be to explore improvements.

### Step 2: Create a bead with the `needs-plan` label

Create a bead with the `needs-plan` label in the rig db. This triggers the `planner-intake` order gate, which starts the planner automatically.

```bash
cd ~/Projects/factory/lab_l1/l1-gc-factory
gc bd --rig l1-project create \
  --title "YOUR_FEATURE_REQUEST" \
  --label needs-plan
```

### Step 3: Inspect the output

```bash
cd ~/Projects/factory/lab_l1/l1-project
ls -al
```

You should see the task with `beads`:

```bash
bd list --all
```

You can also inspect a given agent's session:

```bash
gc session attach <id>
```

Watch the output of the software factory to get a sense for how the feature is being implemented. Take note of potential tools or capabilities that should be used by your agents to help implement the feature.

### Step 4: Update an agent prompt based on your observations

You can update any of the agents' prompts by opening the `packs/<agent>/prompts/<agent>.md.tmpl` file and updating the prompt to use the tools or capabilities you noted in the previous step.

## Part 3: Observe the Pipeline Operating with the New Prompts (15 min)

> **Goal:** Observe the difference in pipeline output when the agents are configured to suite your project's needs.

### Step 1: Send a new task to the factory

Send a new task to the factory with the `needs-plan` label.

```bash
# In the factory (l1-gc-factory), run:
gc bd --rig l1-project create \
  --title "YOUR_FEATURE_REQUEST" \
  --label needs-plan
```

### Step 2: Observe the pipeline operating with the new prompts

Observe the pipeline operating with the new prompts and confirm that the feature is being implemented as expected.

### Step 3: Confirm that the capabilities are being used as expected

Confirm that the capabilities are being used as expected by checking the `gc session attach <id>` output.

## Part 4: Continue improving the factory (15 min)

> **Goal:** Show that software factories mold to the project they are building, and are ever-evolving entities.

Continue improving the factory by sending new tasks to the factory and observing the pipeline operating with the new prompts.

> **Insight: Software factories are not a one-size-fits-all solution.**
>
> Software factories require customization to work for specific software projects. In the same way that a factory producing cars needs to be customized to produce different types of cars, a factory producing software needs to be customized to produce different types of software.

## Exit Criteria

Before leaving this lab, verify all of these:

- [ ] `/factory-activity-agent status L1` shows all six agents running
- [ ] Some customizations have been made to the factory agents' prompts to improve the factory's performance for your project

## Next Steps

**[W3](../../workshops/W3/WORKSHOP_3_GUIDE.md)** examines how agents in your software factory coordinate across channels, which often requires customization similar to what you did in this lab.

**[L2](../L2/LAB_2_GUIDE.md)** is the first lab that customizes specific agent packs. You'll translate the Planner's input wiring from the manifest into concrete edits in `packs/planner/prompts/planner.md.tmpl`, then do the same for the Architect.
