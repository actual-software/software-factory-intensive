# W2 · From Individual AI Workflow to Software Factory Pipeline

> **Goal:** Understand what unique capabilities you've built into your current AI workflow, learn how these differ in a software factory pipeline, and map those to capabilities in a software factory workflow document that you will leverage over the remainder of the curriculum.

| | |
|---|---|
| **Estimated duration** | ~45 minutes |
| **Type** | WORKSHOP |
| **Deliverable** | `factory-pipeline.md` that encapsulates all of your current agent toolsets, memory, model selections, and other capabilities mapped to the software factory pipeline |

## Deliverable

By the end of this workshop, you will have a single committed file:

- `~/Projects/factory/workshop_w2/w2-project/docs/factory-pipeline.md`, containing:
  - `## Current Workflow Inventory` — every model, skill, MCP, memory file, knowledge source, CLI, and playbook you currently rely on as a solo AI user.
  - A six-row mapping table assigning each capability to the Planner / Architect / Designer / Coder / Reviewer / Deployer that should own it (with a `## Shared Knowledge Base` subsection for cross-stage items).
  - `## Missing Capabilities` — capabilities your factory will need but doesn't yet have, each with a tentative implementation strategy.

You will copy this file forward into L1, W3, L2, L3, and L4 — it is the design source the rest of the curriculum customises against.

## Overview

When you code solo with an AI assistant, you've already accumulated more than a single chat window: a preferred model (or mix of models), a set of skills or slash commands, one or more MCP servers, a memory file, a knowledge base, some keybindings, a personal playbook in your head. **A software factory is the same set of capabilities — but distributed across specialist agents, hardened into config, and running without a human mediating handoffs.**

W2 is the bridge from "I drive an AI" to "I maintain an autonomous software production line". You will not install or customize agents yet (that begins in L1); you will audit what you already have, see what each factory stage consumes and produces, and decide what belongs where.

Through this workshop you will:
- Inventory the capabilities that power your current solo workflow
- Read the six factory stages (Planner, Architect, Designer, Coder, Reviewer, Deployer) through the lens of *what each stage needs to do its job*
- Map each of your capabilities onto the pipeline stage(s) that should own it
- Surface gaps — capabilities no agent currently owns — so L1–L4 can close them

## The Pipeline You're Mapping Onto

```
  ┌──────────────┐
  │  Your Solo   │  ← models, memory, skills, MCP servers,
  │  AI Workflow │    knowledge bases, CLI tools, playbooks
  └──────┬───────┘
         │  distribute capabilities across 6 specialist stages
         ▼
┌──────────────────────────────────────────────────────────────┐
│  Feature Request                                             │
│        │                                                     │
│        ▼                                                     │
│  ┌───────────┐   plan   ┌───────────┐   decide   ┌──────────┐│
│  │  Planner  │─────────▶│ Architect │───────────▶│ Designer ││
│  └───────────┘          └───────────┘            └────┬─────┘│
│                                                       │ spec │
│                                                       ▼      │
│  ┌───────────┐   gate   ┌───────────┐   review   ┌──────────┐│
│  │  Deployer │◀─────────│  Reviewer │◀───────────│  Coder   ││
│  └─────┬─────┘          └───────────┘            └──────────┘│
│        │                                                     │
└────────┼─────────────────────────────────────────────────────┘
         ▼
   Functional Software
```

Each stage needs: **a task to act on**, **knowledge sources to consult**, **tools or integrations to invoke**, **an output format to hand off**, and **some form of memory to persist decisions**. Your workflow already supplies most of these — W2 is about naming them and deciding which stage each one belongs to.

## Part 1: Install the W2 workspace (5 min)

> **Goal:** Stand up a scratch workspace to hold your `factory-pipeline.md` deliverable.

### Step 1: Install W2

```bash
# In your agent session, run:
/factory-activity-agent install W2
```

The install copies the contents of `software-factory-intensive/docs/` (your **central deliverables folder** — see [Central Deliverables Folder](../../../README.md#central-deliverables-folder) in the main README) into `~/Projects/factory/workshop_w2/w2-project/docs/`. Since W2 is the first session that authors a cross-session deliverable, the workspace's `docs/` will be effectively empty unless you've seeded it from the [Backup Project Setup](../../../README.md#backup-project-setup).

### Step 2: Verify the workspace was set up correctly

```bash
/factory-activity-agent status W2
ls ~/Projects/factory/workshop_w2/w2-project/docs/
```

You should see the W2 agents listed and a `docs/` directory ready to receive your deliverable.

### Step 3: Create the deliverable file in your central docs folder

You will author the W2 deliverable directly in the central docs folder so that every later session install picks it up automatically:

```bash
touch ~/Projects/actual-software/software-factory-intensive/docs/factory-pipeline.md
```

This is a documentation-only workshop — no code, no agents to manage. Subsequent sessions (`L1`, `W3`, `L2`, …) will read your `factory-pipeline.md` from the central folder when they install, and copy it into their own workspace `docs/`.

## Part 2: Inventory Your Individual AI Workflow (10 min)

> **Goal:** Produce a concrete list of the capabilities you already rely on so you can place them deliberately in Part 4, rather than losing them when you hand off to a factory.

Open `~/Projects/actual-software/software-factory-intensive/docs/factory-pipeline.md` (your central deliverable from Step 3) and, under a heading `## Current Workflow Inventory`, write a one-line entry for every capability that currently contributes to how you ship code. Be specific: a name the next agent (or you, in three months) could act on.

Use these buckets as prompts — skip any that don't apply, and add your own when needed:

| Bucket | What to list | Example entries |
|--------|--------------|-----------------|
| **Models** | Which model(s) you reach for, and when | `claude-opus-4-7` for planning, `claude-sonnet-4-6` for bulk coding, `claude-haiku-4-5` for quick lookups |
| **Skills / slash commands** | Scripts, skills, or commands you invoke repeatedly | `/security-review`, `/simplify`, a custom `/release-notes` skill |
| **MCP servers / integrations** | External systems your agent reads or writes through | GitHub MCP, Linear MCP, a Postgres MCP against staging |
| **Memory / persistence** | Durable notes or long-term state your agent draws on | `CLAUDE.md`, `MEMORY.md`, project-specific auto-memory |
| **Knowledge sources** | Authoritative references your agent consults | Team wiki, ADR folder, design system docs, API reference |
| **Tools / CLIs** | Non-AI tools you lean on between agent turns | `gh`, `rg`, `jq`, a custom `scripts/` folder, a pre-commit hook |
| **Playbook / rules** | Unwritten routines you always apply | "Always run typecheck before committing", "Always write an ADR for storage choices" |

> **Insight: Ask your agent to help you with this step.**
>
> Your agent can help you with this step by asking pointed questions about your workflow and helping you list the capabilities. Try copying the prompt below into your agent's chat and see how it does:

```
You are a helpful assistant that helps me list the capabilities that I rely on in my individual AI workflow. Please read ~/Projects/actual-software/software-factory-intensive/curriculum/workshops/W2/WORKSHOP_2_GUIDE.md and ask me questions to help me with Part 2 of the workshop to fill out ~/Projects/actual-software/software-factory-intensive/docs/factory-pipeline.md. Please ask the questions one at a time and wait for my response before asking the next question.
```

## Part 3: Read the Pipeline Through the Capability Lens (20 min)

> **Goal:** Understand what each factory stage needs in terms of inputs, tools, memory, and outputs, so you can decide in Part 4 which of *your* capabilities should flow to which stage.

Every stage in a software factory has the same shape — a specialist with a narrow mandate, a small input set, and a well-defined handoff. The capabilities you inventoried in Part 2 are what let each stage do its job.

Scan the rows below. For each stage, the *Inputs / Tools / Memory* column is where your inventory items will land in Part 4.

| Agent | Produces | Inputs / Tools / Memory it draws on |
|-------|----------|-------------------------------------|
| **Planner** | A work package — goal, stories, acceptance criteria, scope boundary | Feature request, project manifest, backlog, ticket history; a reasoning-strong model; memory of past scoping decisions |
| **Architect** | An ADR per open decision | Work package, existing ADRs, tech-stack reference, industry patterns; research-capable model; ADR-seeding tooling (e.g. `actual adr-bot`) |
| **Designer** | A component/module spec | Work package, ADRs, design system, existing UI patterns; visual-reference MCPs (Figma, screenshot tools); memory of established UI conventions |
| **Coder** | Implementation + tests on a feature branch | Spec, ADRs, manifest, existing source tree; fast-iteration model; language-specific tools (linters, test runners); repo MCPs (GitHub, local file search) |
| **Reviewer** | A review report with a verdict | Diff, spec, acceptance criteria, project review standards; careful-reasoning model; security-scan tooling; memory of past violations |
| **Deployer** | A release gate report (PASS/FAIL per criterion) | Review report, branch state, release criteria, CI signals; deterministic model or scripted checks; deploy/PR MCPs |

> **Insight: When acting on the shipped reference, each agent is implemented as its own configurable module.**
>
> Even though the factory is a complete system, each agent can be broken down to a set of capabilities that can be implemented as a unique module. Some capabilities may be shared between agents, but more specialized tools will usually rest under a single agent. In Gas City in particular, these configurable sets of capabilities are bundled into *packs*.

### The capability shift from solo to factory

In a solo workflow, *you* move knowledge across stages in your head. In a factory:

- **Inputs are files, not chat memory.** A stage cannot remember what the prior stage "said" — it reads an artifact.
- **Tools are declared, not summoned.** A stage's available MCPs and CLIs are configured up front, not picked ad-hoc.
- **Agent communication must be explicit.** The factory does not have a human mediator — each agent must understand how to communicate its needs and decisions to other agents in the factory.

Keep this in mind as you map your inventory: every capability must land on a specific agent *and* must have a durable home. Now, please fill out the table below with the capabilities you inventoried in Part 2:

| Agent     | Model | Tools / MCPs | Knowledge / memory | Connections |
|-----------|-------|--------------|--------------------|-------------|
| Planner   |       |              |                    |             |
| Architect |       |              |                    |             |
| Designer  |       |              |                    |             |
| Coder     |       |              |                    |             |
| Reviewer  |       |              |                    |             |
| Deployer  |       |              |                    |             |

Rules of thumb while you fill it in:

1. **Every inventory entry should land on at least one stage.** If a capability has no home in the pipeline, either you've found a gap to log, or the capability belongs to all stages (list it as a shared manifest item instead).
2. **Prefer the narrowest stage.** A linter belongs to the Coder, not "every stage." A security scanner belongs to the Reviewer, not the Coder.
3. **Memory decisions are project-level, not stage-level.** `CLAUDE.md`, `docs/PROJECT_MANIFEST.md`, and an ADR folder are shared — note them once, under a `## Shared Knowledge Base` subsection, and reference them from each stage's row.

> **Insight: If you're unsure how to fill out the table, check out the Fired Up Pizza reference at [../../../reference-project/fired-up-pizza/docs/factory-pipeline.md](../../../reference-project/fired-up-pizza/docs/factory-pipeline.md) for a complete example.**
>
> It's alright if you don't know where exactly to place all capabilities, you can simply focus on the essentials first and come back to the rest later.

## Part 4: Surface any final gaps in your factory-pipeline.md (10 min)

> **Goal:** Name the capabilities your current workflow doesn't yet provide, so your software factory can start from a known list of holes rather than discovering them mid-run.

### Step 1: Identify missing capabilities

Under a new section `## Missing Capabilities`, list any capabilities that either don't have a home in the table above or are not currently available in your workflow. For each missing capability, explore:

- Is it an essential capability that your software factory must have?
- Is it a structure only needed by a single agent?
- How can you implement it in a way that is shared between agents?
- Or, how can you implement it in a way that is agent-specific?

Once you've explored the missing capability, add it to the table with a note detailing a tentative implementation strategy.

### Step 2: Commit the deliverable

```bash
cd ~/Projects/actual-software/software-factory-intensive
git add docs/factory-pipeline.md
git commit -m "Add factory-pipeline.md (W2 deliverable)"
```

Commit on your own branch or fork — the curriculum tracks central deliverables in git so you have a durable history of how this file evolves across the rest of the sessions.

This file is what you'll use to guide your software factory implementation for the remainder of the curriculum. Every later session install copies it from the central folder into its own workspace's `docs/` automatically.

## Exit Criteria

Before leaving this workshop, verify all of these:

- [ ] `~/Projects/actual-software/software-factory-intensive/docs/factory-pipeline.md` exists in the central deliverables folder and is committed on your branch
- [ ] Every capability you inventoried appears in the mapping table or the missing capabilities section
- [ ] Every agent row has at least `Model` and `Connections` filled in
- [ ] Every missing capability has a note detailing a tentative implementation strategy

## Next Steps

**[L1](../../labs/L1/LAB_1_GUIDE.md)** is where the factory becomes yours. You'll install a 6-agent factory against your own project and connect each agent to the `PROJECT_MANIFEST` using the inputs, tools, and knowledge sources you mapped here.

**[W3](../W3/WORKSHOP_3_GUIDE.md)** continues the design track by examining how agents coordinate within the factory via various coordination channels.
