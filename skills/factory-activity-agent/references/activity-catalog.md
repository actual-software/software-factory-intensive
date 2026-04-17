# Activity Catalog

Detailed reference for all Software Factory Intensive curriculum activities. Load this file when you need activity descriptions, prerequisites, or pack details.

## Curriculum Overview

The Software Factory Intensive is a 9-session curriculum teaching multi-agent system design using Gas City.

| Session | Type | Activity | Focus |
|---------|------|----------|-------|
| 1 | Workshop | W1 | Optimize individual AI workflow |
| 2 | Lab | L1 | Build structured dev loop (create CLAUDE.md + PROJECT_MANIFEST) |
| 3 | Workshop | W2 | Design 6-agent factory architecture |
| 4 | Lab | L2 | Deploy Planner + Architect agents |
| 5 | Lab | L3 | Deploy Designer + Builder agents |
| 6 | Workshop | W3 | Multi-agent coordination patterns |
| 7 | Lab | L4 | Deploy Reviewer + Release-Gate agents |
| 8 | Workshop | W4 | Continuous improvement feedback loops |
| 9 | Capstone | C1 | Run end-to-end factory on real project |

## Activity Details

### W1 — Optimize Individual AI Workflow

- **Category:** workshops
- **Slug:** `workshop_w1`
- **Focus:** Setting up and optimizing your personal AI-assisted development workflow
- **Packs source:** `activities/workshops/W1/gascity/step_0/packs/`
- **Prerequisites:** None (first session)

### W2 — Design 6-Agent Factory Architecture

- **Category:** workshops
- **Slug:** `workshop_w2`
- **Focus:** Understanding the 6 core agent roles (planner, architect, designer, builder, reviewer, release-gate) and designing how they work together
- **Packs source:** `activities/workshops/W2/gascity/step_0/packs/`
- **Prerequisites:** W1, L1

### W3 — Multi-Agent Coordination Patterns

- **Category:** workshops
- **Slug:** `workshop_w3`
- **Focus:** Label-based handoff protocols, order gates, convergence loops, and convoy patterns
- **Packs source:** `activities/workshops/W3/gascity/step_0/packs/`
- **Prerequisites:** W2, L2, L3

### W4 — Continuous Improvement Feedback Loops

- **Category:** workshops
- **Slug:** `workshop_w4`
- **Focus:** Adding improver agent, retrospectives, metrics, and feedback-driven refinement
- **Packs source:** `activities/workshops/W4/gascity/step_0/packs/`
- **Prerequisites:** W3, L4

### L1 — Build Structured Dev Loop

- **Category:** labs
- **Slug:** `lab_l1`
- **Focus:** Creating CLAUDE.md, PROJECT_MANIFEST.md, and establishing the foundational development loop
- **Packs source:** `activities/labs/L1/gascity/step_0/packs/`
- **Prerequisites:** W1

### L2 — Deploy Planner + Architect Agents

- **Category:** labs
- **Slug:** `lab_l2`
- **Focus:** Deploying and configuring the first two pipeline agents — planner (breaks work into packages) and architect (makes ADR decisions)
- **Packs source:** `activities/labs/L2/gascity/step_0/packs/`
- **Prerequisites:** W2

### L3 — Deploy Designer + Builder Agents

- **Category:** labs
- **Slug:** `lab_l3`
- **Focus:** Adding designer (component specs) and builder (code implementation) agents to the pipeline
- **Packs source:** `activities/labs/L3/gascity/step_0/packs/`
- **Prerequisites:** L2

### L4 — Deploy Reviewer + Release-Gate Agents

- **Category:** labs
- **Slug:** `lab_l4`
- **Focus:** Adding reviewer (code review) and release-gate (quality gates) agents to complete the 6-agent pipeline
- **Packs source:** `activities/labs/L4/gascity/step_0/packs/`
- **Prerequisites:** L3, W3

### C1 — End-to-End Factory Capstone

- **Category:** capstone
- **Slug:** `capstone_c1`
- **Focus:** Running the complete factory (all 6+ agents) on a real project end-to-end
- **Packs source:** `activities/capstone/C1/gascity/step_0/packs/`
- **Prerequisites:** All workshops and labs (W1-W4, L1-L4)

## Agent Roles (Packs)

Each activity's factory includes some or all of these agent packs:

| Pack | Role | Persona |
|------|------|---------|
| `planner` | Break features into work packages | Product/Program Manager |
| `architect` | ADR decisions and architectural rules | Principal Engineer |
| `designer` | Component specifications | UI/UX Designer |
| `builder` | Code implementation | Backend/Frontend Engineer |
| `reviewer` | Code review | Engineering Manager |
| `release-gate` | Release quality gates | Release Engineer |
| `validator` | Test case authoring (optional) | QA Engineer |
| `improver` | Feedback loops (optional) | SRE/Performance Engineer |
| `all` | Composition pack — includes all above | (meta) |

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
