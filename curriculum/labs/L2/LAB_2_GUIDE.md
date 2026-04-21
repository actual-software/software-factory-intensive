# L2 · Deploy Planner + Architect Agents

> **Goal:** Understand the role of the Planner and Architect agents in the software factory, and explore the unique configurations that best adapt these agents to your specific software project.

| | |
|---|---|
| **Estimated duration** | ~75 minutes |
| **Type** | LAB |
| **Deliverable** | Working Planner + Architect agents with at least one suppported Skill and/or CLI capability each |

## Overview

L1 connected a 6-agent factory to your project and explained how to think about updating the capabilities of your software factory agents. Now, you are going to apply that knowledge to build uniquely-customized Planner and Architect agents with Skills and CLI tools. You'll install the Planner and Architect, attach a real capability to each (a skill, a CLI tool, or both), and demonstrate that those capabilities change the quality of the artifacts the stages produce.

In this lab you will:
- Install and run the Planner and Architect against your software project
- Equip each agent with at least one skill or CLI capability
- Trace a single feature from its source through Planner → Architect, taking advantage of the custom capabilities you have added to the agents

## What You'll Build

```
   feature request source
              │
              ▼
   ┌────────────────────┐
   │   Planner (L2)     │    ←  Skill/CLI: e.g. backlog CLI tool,
   │                    │       `actual`, a team-specific
   │   produces:        │       research skill
   │   work-packages/   │
   │     <slug>.md      │
   └──────────┬─────────┘
              │  handoff (via files + work items)
              ▼
   ┌────────────────────┐
   │  Architect (L2)    │    ←  skill/CLI: e.g. ADR seeding
   │                    │       (`actual adr-bot`), a
   │   produces:        │       standards-library CLI
   │   docs/adr/        │
   │     NNNN-<slug>.md │
   └────────────────────┘
```

Each stage will have access to: **the manifest** (what to honor), **the task input** (what to work on), and **a capability** (what to use to accomplish the task). The capability is the part that distinguishes a generic agent "playing the role" from a true customized agent.

## Part 1: Install the L2 Factory (10 min)

> **Goal:** Bring up a factory that includes the Planner and Architect packs installed against your project, carrying forward the manifest and channel work you've already done.

### Step 1: Install L2

```bash
# In your agent session, run:
/factory-activity-agent install L2
```

### Step 2: Carry forward L1 + W3 artifacts

```bash
cp ~/Projects/factory/lab_l1/l1-project/docs/PROJECT_MANIFEST.md \
   ~/Projects/factory/lab_l2/l2-project/docs/PROJECT_MANIFEST.md

cp ~/Projects/factory/workshop_w3/w3-project/docs/coordination-channels.md \
   ~/Projects/factory/lab_l2/l2-project/docs/coordination-channels.md

```

If either L1 or W3 wasn't installed, the matching carry-forward should be skipped — install whichever is missing from the baseline or reference set before continuing.

### Step 3: Verify the Planner and Architect are up

```bash
/factory-activity-agent status L2
```

You should see `planner` and `architect` listed. Other stages are installed but idle — you'll activate them in L3 and L4.

## Part 2: Read the Planner and Architect (10 min)

> **Goal:** Know the inputs, outputs, and decision shape of each stage so the capability you attach in Part 3 is the right one.

Each pack ships with a prompt template at `packs/<stage>/prompts/<stage>.md.tmpl`. Open both side-by-side in your editor and read the prompts.

| Stage | Prompt file | Reads | Produces |
|-------|-------------|-------|----------|
| **Planner** | [`packs/planner/prompts/planner.md.tmpl`](../../../packs/planner/prompts/planner.md.tmpl) | Feature request, `docs/PROJECT_MANIFEST.md`, prior work packages | Goal, stories, acceptance criteria, scope |
| **Architect** | [`packs/architect/prompts/architect.md.tmpl`](../../../packs/architect/prompts/architect.md.tmpl) | Work package, manifest, existing ADRs | Context, options, decision, consequences |

## Part 3: Equip Each Agent With a Capability (20 min)

> **Goal:** Attach at least one skill or CLI capability to each of the two agents so the artifacts they produce reflect your team's actual tools, not just the shipped defaults.

Open `docs/PROJECT_MANIFEST.md` and read the `Planner` and `Architect` rows. At least one capability per row should be wireable now.

### Step 1: Pick the Planner's capability

Choose from your W2 inventory. Typical picks:

- **Backlog integration (MCP)** — Linear / Jira / GitHub Issues MCP so the Planner pulls live tickets rather than a static file
- **Knowledge-base MCP** — Notion, Confluence, a team wiki MCP to cross-reference product docs
- **`actual status`** — the bundled `actual` CLI if you've installed it; the Planner reads it for current repo health before scoping
- **A custom skill** — e.g. a `/scope-check` skill you already use individually that enforces acceptance-criteria rigor

Pick one and record the choice in `docs/factory-pipeline.md → Planner row → Tools / MCPs` if it's not already there.

### Step 2: Wire the Planner capability in

Edit the Planner's prompt to name the capability under `## Inputs you consume` and, if it's an action, under the relevant step of `## Work loop`:

```
packs/planner/prompts/planner.md.tmpl

## Inputs you consume
  + <your new capability, e.g. "Linear project `ACME-PROD` via Linear MCP">

## Work loop
  1. Intake.
     + "Fetch the next item labelled `factory-ready` from Linear via MCP..."
```

Restart the factory so the prompt edit takes effect:

```bash
cd ~/Projects/factory/lab_l2/l2-gc-factory
gc stop && gc start
```

### Step 3: Pick and wire the Architect's capability

Repeat for the Architect. Typical picks:

- **`actual adr-bot`** — seeds tailored ADR baselines into `CLAUDE.md` so the Architect only writes feature-specific ADRs, not industry ones. Install: `brew install actual-software/actual/actual`.
- **A standards-library MCP** — if your team has an internal patterns repo, an MCP that reads it so the Architect references existing decisions
- **A research MCP** — Context7, a documentation-aware MCP for looking up framework-specific behavior before deciding
- **A schema-inspection CLI** — for data architecture decisions, a CLI that introspects your staging DB

Edit the Architect prompt the same way — add the capability under `## Inputs you consume` and/or name it in the relevant step of `## Work loop`. Restart the factory.

### Step 4: Sanity-check that the capabilities are reachable

Sling a dry-run to each stage that exercises only the new capability:

```bash
gc bd --rig l2-project create \
  --title "Dry run: use the <capability> you were given and report what you can read. Do not produce a work package." \
  --label needs-plan

gc bd --rig l2-project create \
  --title "Dry run: use the <capability> you were given and report what you can read. Do not produce an ADR." \
  --label needs-architecture
```

If a dry-run fails, fix the wiring before moving to Part 4.

## Part 4: Run a Feature Through Planner → Architect (20 min)

> **Goal:** Demonstrate the handoff end-to-end against your project, and use any failure as a prompt-edit opportunity — not a chat-correction opportunity.

### Step 1: Pick a small, real feature

Pick something your team actually wants delivered, with **at least one open architectural decision** (so the Architect has something meaningful to do). If you're stuck, the list of candidates on your L1 Planner input source is the right place to draw from.

### Step 2: Sling the Planner

Use the same pickup mechanism you wired in L1:

```bash
gc bd --rig l2-project create \
  --title "<feature>" \
  --label needs-plan
```

### Step 3: Sling the Architect

The Planner should have created a downstream work item and (depending on your channel choices in W3) mailed the Architect. Either way, you can sling the Architect explicitly:

```bash
gc bd --rig l2-project create \
  --title "<feature>" \
  --label needs-architecture
```

### Step 4: Practice the config-over-chat discipline

At least one of the two artifacts will have a problem — stories that don't reference the manifest's domain model, an ADR that skips options, a scope boundary that's too broad. **Resist the urge to correct in chat.** Instead:

1. Identify which section of which prompt should have prevented the failure (usually `## Constraints` or `## Work loop`).
2. Edit the prompt file in the pack.
3. Restart the factory.
4. Re-sling the failed stage. The agent should produce the correct artifact on the second run.

Log the iteration briefly in `docs/factory-iterations.md` — one line per edit, the change in one sentence, the file path. This log becomes the evidence that customization is working and the seed for W4's improvement loops.

## Exit Criteria

Before leaving this lab, verify all of these:

- [ ] `/factory-activity-agent status L2` shows `planner` and `architect` running
- [ ] Each agent has at least one skill or CLI capability named in its prompt and exercised in a dry-run

## Next Steps

**[L3](../L3/LAB_3_GUIDE.md)** adds the Designer and Coder against the same project and requires each to be equipped with at least one MCP server. The Designer reads your ADRs and produces specs; the Coder implements them.
