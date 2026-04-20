# L1 · Connect a Factory to Your Project Manifest

> **Goal:**
Connect a six-agent software factory to your own project by authoring the `PROJECT_MANIFEST` that every stage reads, and wiring the Planner's inputs — feature requests, knowledge bases, and other project-specific sources identified in W2 — into the factory so the pipeline can acquire work without ad-hoc human hand-offs.

| | |
|---|---|
| **Estimated duration** | ~60 minutes |
| **Type** | Lab |
| **Deliverable** | A working six-agent software factory applied to your software project, with `docs/PROJECT_MANIFEST.md` filled in and the Planner's input sources (feature requests, knowledge bases, and other artifacts from W2) connected to the factory |

## Overview

W1 ran a factory against a reference project that was already fully wired. W2 mapped the capabilities from your individual workflow onto the six stages and produced a `factory-pipeline.md`. L1 is where those two halves meet: you install a factory against **your project**, fill in the `PROJECT_MANIFEST.md` that grounds every agent, and connect the Planner's input sources so the factory can ingest real work instead of seeded tickets.

Through this lab you will:
- Install a six-agent factory workspace against your own project
- Author a `PROJECT_MANIFEST.md` from your project overview + W2 capability map
- Wire the Planner's input sources (feature requests, knowledge bases, external systems) into the factory so it can acquire planning inputs automatically
- Verify each agent can read the manifest and that the Planner can pull a task from the sources you configured

> **Fired Up Pizza reference:** For a completed example of a manifest plus Planner input set, see [`reference-project/fired-up-pizza/docs/PROJECT_MANIFEST.md`](../../../reference-project/fired-up-pizza/docs/PROJECT_MANIFEST.md) and [`reference-project/fired-up-pizza/tickets.md`](../../../reference-project/fired-up-pizza/tickets.md). Use it as a *shape reference*, not as content to copy.

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
│   Six-agent factory installed against YOUR project       │
│                                                          │
│   Planner ──▶ Architect ──▶ Designer ──▶ Coder           │
│       ▲                                     │            │
│       │                                     ▼            │
│  input sources                     Reviewer ──▶ Deployer │
│  (from W2 mapping)                                       │
│  • backlog / tickets                                     │
│  • knowledge base                                        │
│  • external integrations                                 │
└──────────────────────────────────────────────────────────┘
```

The Planner's **input sources** are the difference between a factory that waits for you to sling a bead and one that pulls work on its own. In this lab you wire one real source end-to-end (at minimum, the feature backlog) and stub the rest so L2 has something concrete to extend.

## Part 1: Install the L1 Factory Against Your Project (10 min)

> **Goal:** Stand up the factory workspace and point it at your own project repository, so every later step operates against your real code rather than a reference.

### Step 1: Install L1

```bash
# In your agent session, run:
/factory-activity-agent install L1
```

This scaffolds `~/Projects/factory/lab_l1/l1-project/` (the project workspace the factory acts on) and `~/Projects/factory/lab_l1/l1-gc-factory/` (the factory itself).

### Step 2: Point the workspace at your project

L1 starts with a mostly-empty project workspace on purpose — you bring the code. Pour your project into it alongside the scaffolding the install created:

```bash
cp -R ~/path/to/your-repo/. ~/Projects/factory/lab_l1/l1-project/
```

This merges your code into the installed workspace. Do **not** `rm -rf` the installed workspace or replace it with a symlink — the install registered the path with the factory (the `gc rig add` step), so deleting or swapping it out leaves the registration dangling.

### Step 3: Confirm the W2 deliverable was carried forward

The install step above automatically copies `docs/factory-pipeline.md` from your W2 workspace into the L1 workspace. Verify it arrived:

```bash
ls ~/Projects/factory/lab_l1/l1-project/docs/factory-pipeline.md
```

If W2 wasn't installed, the carry-forward is skipped silently — install W2 first if you want your capability map on hand during Part 2.

### Step 4: Verify the factory is healthy

```bash
/factory-activity-agent status L1
/factory-activity-agent doctor L1
```

You should see all six agents listed. No task has been seeded yet — agents will idle until you wire the Planner's inputs in Part 3.

## Part 2: Author the PROJECT_MANIFEST (20 min)

> **Goal:** Produce the single document that grounds every agent in your project's reality, so each stage reads the same authoritative source before making decisions.

Every agent in the factory consults `docs/PROJECT_MANIFEST.md` first. A thin or missing manifest is the single most common reason L2–L4 go sideways — every downstream decision becomes speculation.

### Step 1: Start from the template

```bash
mkdir -p ~/Projects/factory/lab_l1/l1-project/docs
cp ~/Projects/actual-software/software-factory-intensive/curriculum/PROJECT_MANIFEST_TEMPLATE.md \
   ~/Projects/factory/lab_l1/l1-project/docs/PROJECT_MANIFEST.md
```

The template is a *schema*, not prose. It expects concrete fill-ins (tech stack table, domain entities, conventions list, review standards) — not narrative.

### Step 2: Generate the manifest with a local coding agent

Rather than hand-fill every section, let your local coding agent produce a first draft from your project overview:

```
Read docs/PROJECT_OVERVIEW.md (or the project's README and source tree)
and fill in docs/PROJECT_MANIFEST.md using the schema in
curriculum/PROJECT_MANIFEST_TEMPLATE.md. Ask me at most three clarifying
questions before you start writing.
```

> If you don't have a project overview yet, author one first using [`PROJECT_OVERVIEW_TEMPLATE.md`](../../../PROJECT_OVERVIEW_TEMPLATE.md). The overview is free-form and subjective; the manifest is structured and factual — the agent turns one into the other.

### Step 3: Reconcile the manifest against your W2 capability map

Open `docs/factory-pipeline.md` and `docs/PROJECT_MANIFEST.md` side by side. For each stage row in your W2 pipeline map, confirm the manifest carries the information that stage needs:

| W2 mapping row | Manifest section that must support it |
|----------------|----------------------------------------|
| Planner inputs (backlog, knowledge base) | `Task Inputs → Planner` row, `Overview`, `Constraints` |
| Architect inputs (ADR seeds, tech-stack) | `Tech Stack`, `Constraints`, existing `docs/adr/` |
| Designer inputs (design system) | `Conventions → Styling`, `Project Structure` |
| Coder inputs (source tree, build scripts) | `Project Structure`, `Tech Stack`, `Conventions` |
| Reviewer standards | `Review Standards` section |
| Deployer release criteria | `Release Criteria` section |

If a stage in `factory-pipeline.md` references a capability or source that the manifest doesn't describe, add it now — the manifest is the only place durable enough for the factory to find that information on the next run.

### Step 4: Validate the manifest with the factory

Each agent in the installed factory has a bundled check that reads the manifest and flags missing sections. Run it:

```bash
cd ~/Projects/factory/lab_l1/l1-gc-factory
gc doctor --fix
```

Resolve any manifest-related warnings before moving on. A clean `doctor` run is your first proof that every stage can at least *load* the manifest.

## Part 3: Wire the Planner's Input Sources (20 min)

> **Goal:** Configure the Planner to acquire feature requests, knowledge, and other planning inputs from the sources you identified in W2, so the factory can pull work without a human manually slinging each task.

A Planner that only accepts hand-entered requests is a chat interface with extra steps. A Planner connected to your real input sources is the front door to an autonomous pipeline.

### Step 1: Enumerate the Planner's sources from your W2 map

Open `docs/factory-pipeline.md` and copy the `Planner` row's `Tools / MCPs` and `Knowledge / memory` entries into a working list. Typical sources fall into four categories:

| Category | Examples | How the Planner consumes it |
|----------|----------|-----------------------------|
| **Feature backlog** | Linear project, Jira board, GitHub Issues, local `tickets.md` | Primary source of feature requests |
| **Project knowledge** | `PROJECT_MANIFEST.md`, `CLAUDE.md`, team wiki | Constraints, conventions, domain model |
| **Prior artifacts** | Existing work packages, ADRs, release notes | Context and consistency |
| **External signals** | Product analytics, user feedback, incident reports | Input into scoping and prioritization |

### Step 2: Pick one primary backlog source and wire it in

At minimum, the Planner needs one reliable feed of feature requests. Pick the one your team actually uses.

**If your backlog is in a markdown file inside your repo** (the simplest case), the factory is already wired — the Planner reads `tickets.md` (or whatever you name it) directly.

```bash
# Confirm the file exists and the Planner's prompt references it
cat ~/Projects/factory/lab_l1/l1-project/tickets.md | head
```

**If your backlog is in an external system**, install the corresponding MCP server and register it with the factory. Examples:

```bash
# Linear (via the shipped Linear MCP)
/factory-activity-agent sling L1 planner \
  "Authenticate with the Linear MCP and confirm you can list issues in project <project-name>."

# GitHub Issues (via the shipped GitHub MCP)
/factory-activity-agent sling L1 planner \
  "Authenticate with the GitHub MCP and confirm you can list open issues in <owner>/<repo>."

# Jira (via the Atlassian MCP)
/factory-activity-agent sling L1 planner \
  "Authenticate with the Atlassian MCP and confirm you can list issues for site <site>."
```

Each of these prompts is a one-shot verification — the agent reports back whether it has working access. The lasting configuration lives in the Planner pack prompt (you'll edit that in L2).

### Step 3: Record each source in the manifest

Edit `docs/PROJECT_MANIFEST.md` → `Task Inputs → Planner` row. For each source you wired, write a single line naming the source, its access method, and a filter (e.g., the label or status that marks an item as ready for the factory).

```markdown
| Agent | Receives | From |
|-------|----------|------|
| Planner | Feature requests labelled `factory-ready` | Linear project `ACME-PROD` via Linear MCP |
| Planner | Domain model, constraints, Review Standards | `docs/PROJECT_MANIFEST.md` (this file) |
| Planner | Existing work packages (for consistency) | `work-packages/*.md` in this repo |
```

This is the line the Planner reads every run — without it, the agent will either fall back on chat input or hallucinate a source.

### Step 4: Verify the Planner can acquire work from its sources

Sling a dry-run to the Planner that exercises each configured source:

```bash
/factory-activity-agent sling L1 planner \
  "Dry run: list every feature request you can currently read from the sources declared in docs/PROJECT_MANIFEST.md → Task Inputs → Planner. Do not plan anything — just confirm read access."
```

Expected outcome: a short bulleted list of items the Planner could pick up. If a source returns nothing or errors, fix access before continuing — a Planner that silently sees no work is indistinguishable from one that's stuck.

## Part 4: Observe the Pipeline Acquire Its First Feature (10 min)

> **Goal:** Watch a feature request flow from the sources you wired into a work package, confirming end-to-end that the factory is connected to your project's reality.

### Step 1: Place a small feature request in your primary source

Pick a real but small feature your project actually needs. For Linear / Jira / GitHub, create an issue with your `factory-ready` marker. For a `tickets.md` workflow, add a new entry.

### Step 2: Route the Planner at the source

```bash
# The Planner will pick up any item matching its source filters
/factory-activity-agent sling L1 planner \
  "Pick the next item from the sources declared in docs/PROJECT_MANIFEST.md and produce a work package."
```

### Step 3: Inspect the output

```bash
cd ~/Projects/factory/lab_l1/l1-project
ls work-packages/
cat work-packages/<latest-slug>.md
```

The work package should cite:
- the originating request (with source + ID or path),
- the manifest sections it drew on (domain model, constraints),
- an explicit scope boundary.

If any of those are missing, the connection is weak — edit the manifest to sharpen the missing section and re-sling.

## Common Issues and Solutions

- **"The Planner can't see items in my external tool."** Re-check the MCP is authenticated and the filter in `Task Inputs → Planner` actually matches items in that tool. A zero-match filter looks identical to a broken source.
- **"The work package references a domain entity that doesn't exist."** The manifest's `Domain Model` section is incomplete. Extend it and re-sling — the agent will not invent structure it can read.
- **"`gc doctor` keeps warning about manifest sections."** Every `##` heading in the template is expected; empty sections are flagged. Fill them or remove them explicitly.
- **"My project has no backlog system yet."** Start with `tickets.md` at the project root — the factory treats it as a first-class source. You can graduate to Linear/Jira/GitHub later.
- **"A stage in my W2 map isn't reflected in the manifest."** That's the gap list from W2 surfacing. Either add the section to the manifest now, or defer to the relevant L2–L4 session if it's agent-specific.

## Exit Criteria

Before leaving this lab, verify all of these:

- [ ] `/factory-activity-agent status L1` shows all six agents running
- [ ] `~/Projects/factory/lab_l1/l1-project/docs/PROJECT_MANIFEST.md` exists and is filled in for every schema section
- [ ] `docs/PROJECT_MANIFEST.md → Task Inputs → Planner` lists at least one real source with access method and filter
- [ ] A Planner dry-run reports that it can read items from every source listed
- [ ] One end-to-end run produced `work-packages/<slug>.md` that cites both an input source and a manifest section

## Quick Reference: What You Built

| Artifact | Location | What It Does |
|----------|----------|--------------|
| L1 factory | `~/Projects/factory/lab_l1/l1-gc-factory/` | Six-agent factory pointed at your project workspace |
| L1 project workspace | `~/Projects/factory/lab_l1/l1-project/` | Your code plus the manifest, work packages, and factory-pipeline doc |
| `docs/PROJECT_MANIFEST.md` | Inside the project workspace | Single source of truth every agent reads before acting |
| `docs/factory-pipeline.md` (from W2) | Inside the project workspace | Capability map the manifest was reconciled against |
| Planner input wiring | `docs/PROJECT_MANIFEST.md → Task Inputs → Planner` | Sources the Planner pulls work from on every run |

## Next Steps

**[W3](../../workshops/W3/WORKSHOP_3_GUIDE.md)** examines how the six agents coordinate across channels — mail, beads, files, and external services — and extends your factory with a new coordination channel.

**[L2](../L2/LAB_2_GUIDE.md)** is the first lab that customizes agent packs. You'll translate the Planner's input wiring from the manifest into concrete edits in `packs/planner/prompts/planner.md.tmpl`, then do the same for the Architect.

Bring to L2:

- [ ] Your running L1 factory at `~/Projects/factory/lab_l1/`
- [ ] A complete `docs/PROJECT_MANIFEST.md`
- [ ] At least one committed `work-packages/<slug>.md` from Part 4
