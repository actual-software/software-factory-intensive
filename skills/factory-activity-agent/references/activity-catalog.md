# Activity Catalog

Detailed reference for all Software Factory Intensive curriculum activities. Load this file when you need activity descriptions, prerequisites, or pack details.

## Curriculum Overview

The Software Factory Intensive is a 9-session curriculum teaching multi-agent system design using Gas City. Sessions are delivered in the order shown below.

| Session | Type | Activity | Focus |
|---------|------|----------|-------|
| 1 | Workshop | W1 | Run the 6-agent software factory (install + observe a full factory end-to-end) |
| 2 | Workshop | W2 | From individual AI workflow to software factory pipeline |
| 3 | Lab | L1 | Build a structured development loop for your project |
| 4 | Workshop | W3 | Architect multi-agent coordination (labels, beads, mail, nudges, hooks) |
| 5 | Lab | L2 | Deploy Planner + Architect agents |
| 6 | Lab | L3 | Deploy Designer + Coder agents |
| 7 | Lab | L4 | Deploy Reviewer + DevOps agents |
| 8 | Workshop | W4 | Create continuous improvement loops |
| 9 | Capstone | C1 | Run the software factory end-to-end on a real feature |

## Activity Details

### W1 — Run the 6-Agent Software Factory

- **Category:** workshops
- **Slug:** `workshop_w1`
- **Focus:** Install a reference multi-agent factory and observe it work end-to-end, establishing a shared “known-good” baseline before customization
- **Packs source:** `activities/workshops/W1/gascity/step_0/packs/`
- **Prerequisites:** None (first session)
- **Outcomes:**
  - Participants have installed a reference “starter factory” and observed a fully functioning multi-agent software factory end-to-end.
  - Participants have a shared baseline for what “working” looks like before customization begins.
  - Participants can connect curriculum concepts to concrete artifacts (city config, packs, labels/handoffs).

### W2 — From Individual AI Workflow to Software Factory Pipeline

- **Category:** workshops
- **Slug:** `workshop_w2`
- **Focus:** Identify what must change to move from ad-hoc AI prompting to a configured software factory pipeline, and prepare the participant’s agent toolsets, memory, and configuration to be “factory-ready”
- **Packs source:** `activities/workshops/W2/gascity/step_0/packs/`
- **Prerequisites:** W1
- **Outcomes:**
  - Participants understand what must change to move from “individual prompting” to a configured, repeatable factory pipeline.
  - Participants have prepared their agent toolsets, memory, and configuration so their project is “factory-ready”.

### W3 — Architect Multi-Agent Coordination

- **Category:** workshops
- **Slug:** `workshop_w3`
- **Focus:** Learn and apply the unique coordination patterns for multi-agent systems — labels/handoffs, beads, mail, nudges, hooks, and file-based protocols — and add a new coordination mechanism to the factory
- **Packs source:** `activities/workshops/W3/gascity/step_0/packs/`
- **Prerequisites:** W2, L1
- **Outcomes:**
  - Participants understand core coordination patterns (labels/handoffs, beads, mail, nudges, hooks, and file-based protocols).
  - Participants have added at least one new coordination mechanism to their factory.

### W4 — Create Continuous Improvement Loops

- **Category:** workshops
- **Slug:** `workshop_w4`
- **Focus:** Introduce explicit self-improvement into the factory — improver agents, retrospectives, metrics, and feedback-driven refinement — and define criteria for what “improvement” means for the participant’s agents
- **Packs source:** `activities/workshops/W4/gascity/step_0/packs/`
- **Prerequisites:** W3, L4
- **Outcomes:**
  - Participants experience an explicit self-improvement step in the factory loop.
  - Participants understand why self-improvement is hard, what “good” can look like, and where it can fail.
  - Participants define criteria for self-improvement and encode it into agent instructions and/or gates.

### L1 — Build a Structured Development Loop

- **Category:** labs
- **Slug:** `lab_l1`
- **Focus:** Apply a 6-agent city to the participant’s own project — create the foundational development loop anchored in project-level artifacts (e.g. `CLAUDE.md` / `AGENTS.md`, project/factory manifest) so work can flow through the pipeline
- **Packs source:** `activities/labs/L1/gascity/step_0/packs/`
- **Prerequisites:** W1, W2
- **Outcomes:**
  - Participants have a functioning multi-agent city applied to their project (not just the reference starter).
  - Participants have a structured development loop anchored by project artifacts (e.g. `PROJECT_MANIFEST` + agent instructions).

### L2 — Deploy Planner + Architect Agents

- **Category:** labs
- **Slug:** `lab_l2`
- **Focus:** Develop, configure, and test the first two pipeline agents — Planner (breaks work into packages) and Architect (makes ADR-level decisions) — and extend them with a skill and/or CLI capability
- **Packs source:** `activities/labs/L2/gascity/step_0/packs/`
- **Prerequisites:** L1, W3
- **Outcomes:**
  - Participants have developed and tested custom Planner and Architect agents for their factory.
  - Participants have added at least one skill and/or CLI capability that their agents will rely on in real work.

### L3 — Deploy Designer + Coder Agents

- **Category:** labs
- **Slug:** `lab_l3`
- **Focus:** Develop, configure, and test the Designer (component/spec authoring) and Coder (code implementation) agents, and extend them with MCP-backed capabilities where appropriate
- **Packs source:** `activities/labs/L3/gascity/step_0/packs/`
- **Prerequisites:** L2
- **Outcomes:**
  - Participants have developed and tested custom Designer and Coder agents for their factory.
  - Participants have added at least one MCP-backed capability to their agents where appropriate.

### L4 — Deploy Reviewer + DevOps Agents

- **Category:** labs
- **Slug:** `lab_l4`
- **Focus:** Develop, configure, and test the Reviewer (code review) and DevOps / Deployer (release quality gates, ship path) agents, and align them with the product/project manifest so what ships matches what was requested
- **Packs source:** `activities/labs/L4/gascity/step_0/packs/`
- **Prerequisites:** L3
- **Outcomes:**
  - Participants have developed and tested custom Reviewer and DevOps agents for their factory.
  - Participants have aligned their project/product manifest with what their agents enforce (definitions of done, gates, checks).

### C1 — Run the Software Factory End-to-End

- **Category:** capstone
- **Slug:** `capstone_c1`
- **Focus:** Combine every custom agent into a single factory and run it end-to-end to deliver a complete feature from clearly-defined requirements
- **Packs source:** `activities/capstone/C1/gascity/step_0/packs/`
- **Prerequisites:** All prior workshops and labs (W1–W4, L1–L4)
- **Outcomes:**
  - Participants have combined all custom agents into a single factory that delivers a complete feature from clearly defined requirements.

## Agent Roles (Packs)

Each activity's factory includes some or all of these agent packs:

| Pack | Curriculum name | Role | Persona |
|------|-----------------|------|---------|
| `planner` | Planner | Break features into work packages | Product/Program Manager |
| `architect` | Architect | ADR decisions and architectural rules | Principal Engineer |
| `designer` | Designer | Component specifications | UI/UX Designer |
| `builder` | Coder | Code implementation | Backend/Frontend Engineer |
| `reviewer` | Reviewer | Code review | Engineering Manager |
| `release-gate` | DevOps / Deployer | Release quality gates and ship path | Release / DevOps Engineer |
| `validator` | Validator | Test case authoring (optional) | QA Engineer |
| `improver` | Improver | Feedback and self-improvement loops (optional) | SRE / Performance Engineer |
| `all` | — | Composition pack — includes all above | (meta) |

> **Naming note:** the curriculum uses friendly names (“Coder”, “DevOps”) in activity titles and schedules. The pack slugs in `packs/` stay as `builder` and `release-gate` so existing factories and scripts keep working.

## Label-Based Handoff Protocol

Work flows through agents via labels, not hardcoded routing:

```
(user creates bead)
  → needs-architecture → architect
    → needs-plan → planner
      → needs-design → designer
      → needs-tests → validator
      → ready-to-build → builder
        → needs-review → reviewer
          → ready-to-ship → release-gate
            → needs-improve → improver
              → done
```

## Directory Conventions

All factories are installed under `~/Projects/factory/`:

```
~/Projects/factory/
├── workshop_w1/
│   ├── w1-project/          # Project repo (rig)
│   └── w1-gc-factory/       # Gas City workspace
├── workshop_w2/
│   ├── w2-project/
│   └── w2-gc-factory/
├── lab_l1/
│   ├── l1-project/
│   └── l1-gc-factory/
...
└── capstone_c1/
    ├── c1-project/
    └── c1-gc-factory/
```

Each factory workspace contains:
- `city.toml` — workspace configuration
- `packs/actual/` — synced agent packs from the curriculum
