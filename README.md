# Software Factory Intensive

Hands-on, project-based workshop to learn how to build a software factory -- a system of AI agents that can plan, architect, code, review, and deploy software continuously.

**April 21-22, 2025 · Seattle, WA · Actual AI**

50 participants · 10 pods x 5 · Reference project: Fired Up Pizza

## Schedule

| ID | Day | Time | Type | Title |
|----|-----|------|------|-------|
| [W1](curriculum/workshops/W1/) | Day 1 | 10:30-11:30 | WORKSHOP | Optimize the Individual AI Workflow |
| [L1](curriculum/labs/L1/) | Day 1 | 11:30-12:30 | LAB | Build a Structured Development Loop |
| [W2](curriculum/workshops/W2/) | Day 1 | 1:30-2:15 | WORKSHOP | Design the 6-Agent Software Factory |
| [L2](curriculum/labs/L2/) | Day 1 | 2:15-3:30 | LAB | Deploy Planner + Architect Agents |
| [L3](curriculum/labs/L3/) | Day 1 | 3:45-5:00 | LAB | Deploy Designer + Coder Agents |
| [W3](curriculum/workshops/W3/) | Day 2 | 9:30-10:15 | WORKSHOP | Architect Multi-Agent Coordination |
| [L4](curriculum/labs/L4/) | Day 2 | 10:30-11:45 | LAB | Deploy Reviewer + DevOps Agents |
| [W4](curriculum/workshops/W4/) | Day 2 | 11:45-12:30 | WORKSHOP | Create Continuous Improvement Loops |
| [C1](curriculum/capstone/C1/) | Day 2 | 1:30-3:00 | CAPSTONE | Run the Software Factory End-to-End |

## The 6-Agent Software Factory

Over two days you build a pipeline of six AI agents that turn a feature request into deployed code:

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

When an agent produces wrong output, update its config file and re-run -- don't type a correction into the chat. This discipline is the bridge between individual AI use and a factory that runs 24/7 without a human at the keyboard.

## Repo Structure

```
curriculum/                    # Session details, rubrics, and facilitation prompts
  workshops/W1-W4/             # Instructor-led concept sessions
  labs/L1-L4/                  # Hands-on build sessions
  capstone/C1/                 # Full factory run assessment
  PROJECT_MANIFEST_TEMPLATE.md # Fill out before arriving

reference-project/
  fired-up-pizza/              # Working reference — complete 6-agent factory example

my-factory/                    # Your workspace — start here with your own project
  docs/PROJECT_MANIFEST.md     # Your project manifest (copy from template)
  CLAUDE.md                    # Your agent instructions

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

## Integrations

The [`packs/workshop/`](packs/workshop/) pack provides pre-configured integrations for external services your factory can connect to. Include it alongside your agent packs to get:

- **Issue tracker sync** -- Jira, Linear, GitHub Issues, GitLab Issues, Azure DevOps, Notion (via `bd` native sync with periodic orders)
- **Observability** -- Sentry, DataDog, PostHog, Grafana (via MCP servers giving agents direct tool access)
- **Cloud providers** -- AWS, GCP, Azure (validated via CLI auth)
- **Communication** -- Slack, Discord (via MCP servers)

```bash
# Add the workshop integrations pack to your rig
gc rig add ~/your-project --include packs/workshop

# Copy the env template and fill in your credentials
cp packs/workshop/env.example .env

# Validate connections
gc doctor
```

Only configure the integrations your project actually uses. See [`packs/workshop/README.md`](packs/workshop/README.md) for the full list and setup details.

## Before You Arrive

1. **Complete your [Project Manifest](curriculum/PROJECT_MANIFEST_TEMPLATE.md)** -- this defines the project you'll build your factory around
2. **Install Gas City**: `brew install gastownhall/gascity/gascity`
3. **Install Claude Code** (or your preferred AI coding agent)
4. **Clone this repo** and explore `reference-project/fired-up-pizza/` for a working example
5. **Have your project repo ready** -- cloned locally, dependencies installed

## Getting Started at the Workshop

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
