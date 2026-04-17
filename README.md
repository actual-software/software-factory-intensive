# Software Factory Intensive

Hands-on, project-based workshop to learn how to build a software factory — a system of AI agents that can plan, architect, code, review, and deploy software continuously.

| | |
|---|---|
| **Format** | Self-paced walkthroughs (9 sessions: 4 workshops + 4 labs + 1 capstone) |
| **Estimated total time** | ~9 hours of guided work |
| **Reference project** | [Fired Up Pizza](reference-project/fired-up-pizza/) |

---

## Community & Support

Stuck on a step, want to share what you've built, or looking to collaborate with other participants? Join the **Actual AI User Community** Slack:

- **Join the community slack:** [actualaiusercommunity.slack.com](https://join.slack.com/t/actualaiusercommunity/shared_invite/zt-3vibgzapf-ywx0Db29mZ4lhtQJGzZfGQ)
- **Real-time help:** once you're in, join [#sfi-help-desk](https://actualaiusercommunity.slack.com/archives/C0ATHDM0NUD) for live support on the curriculum.

---

## Before You Arrive

### 1. Confirm Machine Requirements

- **Operating System**: MacOS and Linux are ready to go as-is. Windows users: please install [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) (Windows Subsystem for Linux) and run everything from inside the WSL shell.
- **CLI Coding Agents**: You’ll need at least one CLI coding agent installed. Having more than one gives you broader capabilities and redundancy.
  - **Recommended**: Claude Code Max (20x) or Codex Pro (20x), or equivalent
  - **Minimum**: Claude Code Max or Codex Pro (standard tier), or equivalent
  - **Alternatives**: Gemini CLI, OpenCode (compatibility not guaranteed)

### 2. Software Project Overview

You should bring a real software project to build your factory around. Before starting the curriculum, write a **Project Overview** for it using [`curriculum/PROJECT_OVERVIEW_TEMPLATE.md`](./PROJECT_OVERVIEW_TEMPLATE.md) — a loosely structured document that answers a few questions about the project. Your local coding agent will generate the Project Manifest and Software Factory Manifest from this document. You can see [`reference-project/fired-up-pizza/docs/PROJECT_OVERVIEW.md`](reference-project/fired-up-pizza/docs/PROJECT_OVERVIEW.md) for a completed example.

### 3. Gas City Installation

Refer to the Gas City [Installation Guide](https://github.com/gastownhall/gascity/blob/main/docs/getting-started/installation.md) for the full dependency list and platform-specific notes.

### 4. Gas City Quickstart

Follow the [Quickstart Guide](prerequisites/quickstart.md) to install Gas City and create a new workspace. This will help you understand the basics of the Gas City CLI before you start the workshop.

---

## Why Gas City

This curriculum is built on top of [Gas City](https://github.com/gastownhall/gascity), an open-source framework for running multi-agent systems. Gas City abstracts the primitives of multi-agent coordination — agents, packs, rigs, beads, sessions, orders, routes — so that any multi-agent architecture can be expressed within the same framework rather than re-invented each time.

We use Gas City here because the 6-agent factory is one instance of a much broader pattern. Once you've learned the primitives, you can swap out the specific agent roles and build pipelines for code review, research, data processing, ops automation — the framework doesn't care what the agents do. The goal of the workshop is to make these primitives internalized enough that you can design your own multi-agent systems after you leave.

For the authoritative definitions of every Gas City term used across the curriculum (agent, pack, rig, bead, sling, order, route, formula, overlay, etc.), see the upstream glossary: [Gas City glossary](https://github.com/gastownhall/gascity/blob/main/engdocs/architecture/glossary.md). Skim it once before W1 and keep it open as a reference during the labs.

---

## The 6-Agent Software Factory

Across 9 sessions you build a pipeline of six AI agents that turn a feature request into deployed code:

```
Feature Request → Planner → Architect → Designer → Builder → Reviewer → Release-Gate → Done
```

| Role (curriculum) | Shipped pack | What It Does |
|-------------------|-------------|-------------|
| **Planner** | `packs/planner` | Breaks features into structured work packages |
| **Architect** | `packs/architect` | Makes technical decisions, produces ADRs |
| **Designer** | `packs/designer` | Creates component/module specs |
| **Builder** (Coder) | `packs/builder` | Implements code from specs |
| **Reviewer** | `packs/reviewer` | Reviews code against specs and standards |
| **Release-Gate** (Deployer) | `packs/release-gate` | Evaluates release gates |

## Core Principle: Config Over Prompting

The single most important discipline this workshop teaches: **change agent behavior through config, not through ad-hoc prompting.**

When an agent produces wrong output, update its config file and re-run — don't type a correction into the chat. This discipline is the bridge between individual AI use and a factory that runs 24/7 without a human at the keyboard.

---

## Session Map

| ID | Type | Estimated Duration | Title |
|----|------|--------------------|-------|
| [W1](curriculum/workshops/W1/) | WORKSHOP | ~60 min | Optimize the Individual AI Workflow |
| [L1](curriculum/labs/L1/) | LAB | ~60 min | Build a Structured Development Loop |
| [W2](curriculum/workshops/W2/) | WORKSHOP | ~45 min | Design the 6-Agent Software Factory |
| [L2](curriculum/labs/L2/) | LAB | ~75 min | Deploy Planner + Architect Agents |
| [L3](curriculum/labs/L3/) | LAB | ~75 min | Deploy Designer + Coder Agents |
| [W3](curriculum/workshops/W3/) | WORKSHOP | ~45 min | Architect Multi-Agent Coordination |
| [L4](curriculum/labs/L4/) | LAB | ~75 min | Deploy Reviewer + Deployer Agents |
| [W4](curriculum/workshops/W4/) | WORKSHOP | ~45 min | Create Continuous Improvement Loops |
| [C1](curriculum/capstone/C1/) | CAPSTONE | ~90 min | Run the Software Factory End-to-End |

---

## Repo Structure

```
software-factory-intensive/
├── README.md                        # You are here
├── installation.md                  # Dependency install guide
│
├── my-factory/                      # Your Gas City workspace (top-level city.toml lives here)
│   ├── city.toml                    # Workspace config — add pack includes as you progress
│   ├── README.md                    # Quickstart: register workspace, add rig, wire packs
│
├── activities/                      # Where you place per-session deliverables + pack customisations
│   ├── README.md                    # Session layout + additive/independent model
│   ├── workshops/
│   │   ├── W1/README.md             # Workflow card
│   │   ├── W2/README.md             # Factory wiring
│   │   ├── W3/README.md             # orchestrator.yaml + gate justifications
│   │   └── W4/README.md             # Feedback-loop rule files
│   ├── labs/
│   │   ├── L1/README.md             # CLAUDE.md + DECISIONS.md
│   │   ├── L2/README.md             # Planner + Architect activity
│   │   ├── L3/README.md             # Designer + Builder activity
│   │   └── L4/README.md             # Reviewer + Release-Gate activity
│   └── capstone/
│       └── C1/README.md             # Run report + retrospective
│
├── curriculum/                      # Self-paced session walkthroughs
│   ├── README.md
│   ├── PROJECT_OVERVIEW_TEMPLATE.md # Loose-structure project brief (you fill in)
│   ├── PROJECT_MANIFEST_TEMPLATE.md # Structural skeleton (agent-generated in L1)
│   ├── workshops/W1..W4/            # README.md per session, with inline Agent Guide callouts
│   ├── labs/L1..L4/                 # README.md per session, with inline Agent Guide callouts
│   └── capstone/C1/                 # README.md with inline Agent Guide callouts
│
├── packs/                           # Shipped Gas City agent packs — use as-is or copy + customise
│   ├── README.md                    # Pack authoring + persona mapping
│   ├── city.toml                    # Sample workspace for standalone pack runs
│   ├── planner/                     # Added in L2
│   ├── architect/                   # Added in L2
│   ├── designer/                    # Added in L3
│   ├── builder/                     # Added in L3 (called "Coder" in the curriculum)
│   ├── reviewer/                    # Added in L4
│   ├── release-gate/                # Added in L4 (called "Deployer" in the curriculum)
│   ├── validator/                   # Optional — writes failing tests from ACs
│   ├── improver/                    # Optional — harvests feedback from runs
│   ├── all/                         # Composition pack bundling all 8
│   ├── fired-up-pizza/              # Composite pack for the reference project
│   └── workshop/                    # Pre-configured integrations (Jira, Linear, GitHub, etc.)
│
└── reference-project/
    └── fired-up-pizza/              # Working reference — complete 6-agent factory example
```

---

## Next Steps

Ready to get started? Jump to [W1](curriculum/workshops/W1/) to start.
