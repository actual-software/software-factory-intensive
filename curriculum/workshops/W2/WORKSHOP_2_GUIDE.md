# W2 · From Individual AI Workflow to Software Factory Pipeline

> **Goal:** Understand what unique capabilities you've built into your current AI workflow, learn how these differ in a software factory pipeline, and map those to capabilities in a software factory workflow document that you will leverage over the remainder of the curriculum.

| | |
|---|---|
| **Estimated duration** | ~45 minutes |
| **Type** | WORKSHOP |
| **Deliverable** | `factory-pipeline.md` that encapsulates all of your current agent toolsets, memory, model selections, and other capabilities mapped to the software factory pipeline |

## Overview

When you code solo with an AI assistant, you've already accumulated more than a single chat window: a preferred model (or mix of models), a set of skills or slash commands, one or more MCP servers, a memory file, a knowledge base, some keybindings, a personal playbook in your head. **A software factory is the same set of capabilities — but distributed across six specialists, hardened into config, and run without a human mediating handoffs.**

W2 is the bridge from "I drive an AI" to "an AI pipeline runs without me." You will not install or customize agents yet (that begins in L1); you will audit what you already have, see what each factory stage consumes and produces, and decide what belongs where.

Through this workshop you will:
- Inventory the capabilities that power your current solo workflow
- Read the six factory stages (Planner, Architect, Designer, Coder, Reviewer, Deployer) through the lens of *what each stage needs to do its job*
- Map each of your capabilities onto the pipeline stage(s) that should own it
- Surface gaps — capabilities no agent currently owns — so L1–L4 can close them

> **Fired Up Pizza reference:** Every concept in this workshop has a worked example in the reference project. If you want to see a completed mapping, skim [`reference-project/fired-up-pizza/docs/PROJECT_OVERVIEW.md`](../../../reference-project/fired-up-pizza/docs/PROJECT_OVERVIEW.md) and [`reference-project/fired-up-pizza/docs/PROJECT_MANIFEST.md`](../../../reference-project/fired-up-pizza/docs/PROJECT_MANIFEST.md). Use it sparingly — the point of W2 is to map *your* workflow, not to re-document the reference.

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

> **Goal:** Stand up a scratch workspace to hold your `factory-pipeline.md` deliverable, using the same install/delete pattern you'll use for every subsequent session.

### Step 1: Install W2

```bash
# In your agent session, run:
/factory-activity-agent install W2
```

This scaffolds `~/Projects/factory/workshop_w2/w2-project/` (where your deliverable lives) and `~/Projects/factory/workshop_w2/w2-gc-factory/` (a minimal factory you can use to inspect the shipped packs if you want to cross-reference them in Part 2).

### Step 2: Keep W1 open alongside

Do not delete your W1 installation yet. You'll reference the Fired Up Pizza factory at `~/Projects/factory/workshop_w1/w1-project/` whenever you need a concrete example of what a capability looks like in place.

> If you've already torn down W1, reinstall it with `/factory-activity-agent install W1` — the scaffolds at `w1-project/src/`, `w1-project/docs/PROJECT_MANIFEST.md`, and the installed packs under `w1-gc-factory/packs/actual/` are the reference you'll compare yourself against.

### Step 3: Open the W2 workspace and create the deliverable file

```bash
cd ~/Projects/factory/workshop_w2/w2-project
mkdir -p docs
touch docs/factory-pipeline.md
```

`docs/factory-pipeline.md` is the single design document you'll write in this workshop. No code, no agents to manage. Later sessions read it from `docs/factory-pipeline.md` — keep it there.

## Part 2: Inventory Your Individual AI Workflow (10 min)

> **Goal:** Produce a concrete list of the capabilities you already rely on so you can place them deliberately in Part 4, rather than losing them when you hand off to a factory.

Open `docs/factory-pipeline.md` and, under a heading `## Current Workflow Inventory`, write a one-line entry for every capability that currently contributes to how you ship code. Be specific: a name the next agent (or you, in three months) could act on.

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

> The goal is breadth, not depth. You're listing *what you have*, not explaining how it works. Aim for 15–30 entries total.

## Part 3: Read the Pipeline Through the Capability Lens (10 min)

> **Goal:** Understand what each factory stage needs in terms of inputs, tools, memory, and outputs, so you can decide in Part 4 which of *your* capabilities should flow to which stage.

Every stage in a software factory has the same shape — a specialist with a narrow mandate, a small input set, a single output artifact, and a well-defined handoff. The capabilities you inventoried in Part 2 are what let each stage do its job.

Scan the rows below. For each stage, the *Inputs / Tools / Memory* column is where your inventory items will land in Part 4.

| Stage | Produces | Inputs / Tools / Memory it draws on |
|-------|----------|-------------------------------------|
| **Planner** | A work package — goal, stories, acceptance criteria, scope boundary | Feature request, project manifest, backlog, ticket history; a reasoning-strong model; memory of past scoping decisions |
| **Architect** | An ADR per open decision | Work package, existing ADRs, tech-stack reference, industry patterns; research-capable model; ADR-seeding tooling (e.g. `actual adr-bot`) |
| **Designer** | A component/module spec | Work package, ADRs, design system, existing UI patterns; visual-reference MCPs (Figma, screenshot tools); memory of established UI conventions |
| **Coder** | Implementation + tests on a feature branch | Spec, ADRs, manifest, existing source tree; fast-iteration model; language-specific tools (linters, test runners); repo MCPs (GitHub, local file search) |
| **Reviewer** | A review report with a verdict | Diff, spec, acceptance criteria, project review standards; careful-reasoning model; security-scan tooling; memory of past violations |
| **Deployer** | A release gate report (PASS/FAIL per criterion) | Review report, branch state, release criteria, CI signals; deterministic model or scripted checks; deploy/PR MCPs |

> **Framework aside:** When acting on the shipped reference, each stage is implemented as a Gas City *pack* with its own `prompts/<name>.md.tmpl` and `pack.toml`. You'll edit those files in L2–L4. For now, treat "stage" as the concept and "pack" as one possible implementation.

### The capability shift from solo to factory

In a solo workflow, *you* move knowledge across stages in your head. In a factory:

- **Inputs are files, not chat memory.** A stage cannot remember what the prior stage "said" — it reads an artifact.
- **Tools are declared, not summoned.** A stage's available MCPs and CLIs are configured up front, not picked ad-hoc.
- **Memory is versioned.** Lessons don't live in a conversation; they live in `CLAUDE.md` / `AGENTS.md` or per-stage prompts.

Keep this in mind as you map your inventory: every capability must land on a specific stage *and* must have a durable home.

## Part 4: Map Your Capabilities onto the Pipeline (15 min)

> **Goal:** Produce a stage-by-stage assignment for every capability in your inventory, so the remainder of the curriculum has a clear starting configuration per specialist.

In `docs/factory-pipeline.md`, add a section `## Pipeline Mapping`. Fill in the table below — one row per stage — with:

- **Model**: which model best matches this stage's work style
- **Tools / MCPs**: which of your inventoried integrations this stage needs
- **Knowledge / memory**: which durable references this stage reads
- **Output**: the artifact this stage hands off
- **Gap**: anything the stage needs that your current workflow doesn't yet provide

```markdown
| Stage     | Model | Tools / MCPs | Knowledge / memory | Output | Gap |
|-----------|-------|--------------|--------------------|--------|-----|
| Planner   |       |              |                    | work-packages/<slug>.md         |   |
| Architect |       |              |                    | docs/adr/NNNN-<slug>.md         |   |
| Designer  |       |              |                    | design/<slug>-spec.md           |   |
| Coder     |       |              |                    | src/** + tests                   |   |
| Reviewer  |       |              |                    | review-reports/<slug>-review.md |   |
| Deployer  |       |              |                    | release-gates/<slug>-gate.md    |   |
```

Rules of thumb while you fill it in:

1. **Every inventory entry should land on at least one stage.** If a capability has no home in the pipeline, either you've found a gap to log, or the capability belongs to all stages (list it as a shared manifest item instead).
2. **Prefer the narrowest stage.** A linter belongs to the Coder, not "every stage." A security scanner belongs to the Reviewer, not the Coder.
3. **Memory decisions are project-level, not stage-level.** `CLAUDE.md`, `docs/PROJECT_MANIFEST.md`, and an ADR folder are shared — note them once, under a `## Shared Knowledge Base` subsection, and reference them from each stage's row.

> **Anchor to reference:** When you're unsure where to place something, look at how the W1 Fired Up Pizza factory wires equivalent capabilities — the installed packs under `~/Projects/factory/workshop_w1/w1-gc-factory/packs/actual/<agent>/` show each stage's consumed inputs, tool permissions, and output locations.

## Part 5: Surface and Log the Gaps (5 min)

> **Goal:** Name the capabilities your current workflow doesn't yet provide, so L1 can start from a known list of holes rather than discovering them mid-run.

Under a section `## Gaps and Actions`, list every row in your mapping table where the **Gap** column is non-empty. For each gap, decide:

- **Close now**: something you can add before L1 (e.g. install a specific MCP server)
- **Close in L1–L4**: an agent-specific capability you'll wire in during a later session
- **Accept**: something you've consciously decided is out of scope for this curriculum

A short example:

```markdown
## Gaps and Actions

| Gap | Stage | When to close |
|-----|-------|---------------|
| No security scanner configured        | Reviewer | Close in L4  |
| No ADR seed via `actual adr-bot`       | Architect | Close now (optional) |
| No Figma MCP; Designer has no visuals  | Designer | Accept (no UI work this cycle) |
| No staging DB access from agent        | Coder, Reviewer | Close in L3  |
```

Commit `docs/factory-pipeline.md`. This file is what you'll hand to each subsequent session — L1 will read it to decide what to install, L2–L4 will read it per agent.

## Common Issues and Solutions

- **"My inventory is mostly empty."** You're probably underselling your workflow — memory files, model choices, and implicit playbooks count. Re-scan the Part 2 buckets once more.
- **"The same MCP lands on three stages."** That's fine if it's truly shared (GitHub is); it's a smell if it's because you haven't decided who owns it. Pick one primary stage and list the others as secondary consumers.
- **"I don't know which model to put on Planner vs Coder."** Default to stronger/slower on Planner + Architect + Reviewer; faster/cheaper on Coder + Deployer. You can revise this in L2–L4 once you see each stage in action.
- **"My project has no Designer work."** Leave the Designer row blank with a note — L3 will either install a minimal designer or you'll skip the pack entirely.

## Exit Criteria

Before leaving this workshop, verify all of these:

- [ ] `~/Projects/factory/workshop_w2/w2-project/docs/factory-pipeline.md` exists and is committed
- [ ] Every capability you inventoried appears in the mapping table or the shared knowledge base section
- [ ] Every stage row has at least `Model` and `Output` filled in
- [ ] Every `Gap` has a decision (close now / close in L1–L4 / accept)

## Quick Reference: What You Built

| Artifact | Location | What It Holds |
|----------|----------|---------------|
| `factory-pipeline.md` | `~/Projects/factory/workshop_w2/w2-project/docs/factory-pipeline.md` | Inventory of your workflow, stage-by-stage mapping, gap list |
| W2 workspace | `~/Projects/factory/workshop_w2/` | Scratch factory + project for this design session |
| Reference factory (from W1) | `~/Projects/factory/workshop_w1/` | Worked example of each stage's configuration |

## Next Steps

**[L1](../../labs/L1/LAB_1_GUIDE.md)** is where the factory becomes yours. You'll install a 6-agent factory against your own project and connect each agent to the `PROJECT_MANIFEST` using the inputs, tools, and knowledge sources you mapped here.

**[W3](../W3/WORKSHOP_3_GUIDE.md)** continues the design track by examining how the six agents coordinate — mail, beads, files, and external services as coordination channels — and adding one to your factory.

Bring to L1:

- [ ] `factory-pipeline.md` with every stage row filled in
- [ ] Your project's overview document (see [`PROJECT_OVERVIEW_TEMPLATE.md`](../../../PROJECT_OVERVIEW_TEMPLATE.md))
- [ ] A list of gaps you chose to close before L1 (if any)
