# Software Factory Intensive

Hands-on, project-based workshop to learn how to build a software factory — a system of AI agents that can plan, architect, code, review, and deploy software continuously.

| | |
|---|---|
| **Format** | Self-paced walkthroughs (9 sessions: 4 workshops + 4 labs + 1 capstone) |
| **Estimated total time** | ~9 hours of guided work |
| **Reference project** | [Fired Up Pizza](reference-project/fired-up-pizza/) |

---

## Before You Arrive

### 1. Software Project Overview

You should bring a real software project to build your factory around. Before starting the curriculum, write a **Project Overview** for it — a loosely structured document answering the questions below. (Don't fill in the structured `docs/PROJECT_MANIFEST.md` yet — your local coding agent generates that from your overview during L1.)

A complete overview covers:

- **User needs** — what does this software do, and for whom?
- **Size, type, languages, resource constraints** — is it a new project or an existing codebase? Which languages and frameworks? Any limits on memory, runtime, or platform?
- **Potential SDLC service integrations** — which external services is this factory likely to touch (Vercel, Jira, Linear, AWS, Grafana, GitHub, etc.)?

Use [`curriculum/PROJECT_OVERVIEW_TEMPLATE.md`](curriculum/PROJECT_OVERVIEW_TEMPLATE.md) as a starting point. See [`reference-project/fired-up-pizza/docs/PROJECT_OVERVIEW.md`](reference-project/fired-up-pizza/docs/PROJECT_OVERVIEW.md) for a completed example.

### 2. Library Dependencies

Install Gas City and the tools it depends on. See [`installation.md`](installation.md) for the full dependency list and platform-specific notes.

- **Gas City**: `brew install gastownhall/gascity/gascity`
- **Supporting tools**: `git`, `tmux`, `jq`, `dolt` — typically installed automatically alongside Gas City on macOS

### 3. CLI Coding Agents

You need at least one CLI coding agent installed and authenticated. Additional agents give you broader capabilities and redundancy (different models have different strengths).

- **Recommended**: Claude Code Max 20×, Codex Pro 20×, or similar paid tiers
- **Minimum**: Claude Code Max, Codex Pro, or similar
- **Others may work** (no compatibility guarantees):
  - Gemini CLI
  - OpenCode
  - GitHub Copilot
  - Cursor

For the current list of supported providers and their configuration keys, see Gas City's provider registry: [`internal/config/provider.go#L203-L209`](https://github.com/gastownhall/gascity/blob/73f09ddd78fed9b90e0589b324255c36d030eb46/internal/config/provider.go#L203-L209).

### 4. Operating System

- **macOS / Linux**: works as-is
- **Windows**: install [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) first; run everything from inside the WSL shell

---

## Why Gas City

This curriculum is built on top of [Gas City](https://github.com/gastownhall/gascity), an open-source framework for running multi-agent systems. Gas City abstracts the primitives of multi-agent coordination — agents, packs, rigs, beads, sessions, orders, routes — so that any multi-agent architecture can be expressed within the same framework rather than re-invented each time.

We use Gas City here because the 6-agent factory is one instance of a much broader pattern. Once you've learned the primitives, you can swap out the specific agent roles and build pipelines for code review, research, data processing, ops automation — the framework doesn't care what the agents do. The goal of the workshop is to make these primitives internalized enough that you can design your own multi-agent systems after you leave.

---

## The 6-Agent Software Factory

Across 9 sessions you build a pipeline of six AI agents that turn a feature request into deployed code:

```
Feature Request → Planner → Architect → Designer → Coder → Reviewer → Deployer → Done
```

| Agent | What It Does | Output |
|-------|-------------|--------|
| **Planner** | Breaks features into structured work packages | `work-packages/<slug>.md` |
| **Architect** | Makes technical decisions, produces ADRs | `docs/adr/NNNN-<slug>.md` |
| **Designer** | Creates component/module specs | `design/<slug>-spec.md` |
| **Coder** | Implements code from specs | `src/` files |
| **Reviewer** | Reviews code against specs and standards | `review-reports/<slug>-review.md` |
| **Deployer** | Evaluates release gates | `release-gates/<slug>-gate.md` |

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
curriculum/                    # Self-paced session walkthroughs and facilitation prompts
  workshops/W1-W4/             # Concept + design sessions
  labs/L1-L4/                  # Hands-on build sessions
  capstone/C1/                 # Full factory run
  PROJECT_OVERVIEW_TEMPLATE.md # Fill out before starting — loose-structure project brief
  PROJECT_MANIFEST_TEMPLATE.md # Structural skeleton — generated by your agent, not hand-written

reference-project/
  fired-up-pizza/              # Working reference — complete 6-agent factory example

my-factory/                    # Starter workspace — copy into your own project repo
  CLAUDE.md                    # Bare agent instructions template
  docs/PROJECT_MANIFEST.md     # Manifest template (generated by an agent in L1)

packs/                         # Gas City agent packs
  planner/                     # Added in L2
  architect/                   # Added in L2
  designer/                    # Added in L3
  coder/                       # Added in L3
  reviewer/                    # Added in L4
  deployer/                    # Added in L4
  fired-up-pizza/              # All 6 bundled (reference project only)
  workshop/                    # Pre-configured integrations (Jira, Linear, GitHub, etc.)
```

---

## Integrations

The [`packs/workshop/`](packs/workshop/) pack provides pre-configured integrations for external services your factory can connect to. Include it alongside your agent packs to get:

- **Issue tracker sync** — Jira, Linear, GitHub Issues, GitLab Issues, Azure DevOps, Notion (via `bd` native sync with periodic orders)
- **Observability** — Sentry, DataDog, PostHog, Grafana (via MCP servers giving agents direct tool access)
- **Cloud providers** — AWS, GCP, Azure (validated via CLI auth)
- **Communication** — Slack, Discord (via MCP servers)

```bash
# Add the workshop integrations pack to your rig
gc rig add ~/your-project --include packs/workshop

# Copy the env template and fill in your credentials
cp packs/workshop/env.example .env

# Validate connections
gc doctor
```

Only configure the integrations your project actually uses. See [`packs/workshop/README.md`](packs/workshop/README.md) for the full list and setup details.

---

## Getting Started

```bash
# Initialize your factory city
gc init ~/my-city

# Add your project as a rig (agents added incrementally in labs)
cd ~/my-city
gc rig add ~/your-project

# Your first agent pack gets added in L2:
# gc rig add ~/your-project --include packs/planner
```

See the [curriculum README](curriculum/README.md) for session structure details, or jump to [W1](curriculum/workshops/W1/) to start.
