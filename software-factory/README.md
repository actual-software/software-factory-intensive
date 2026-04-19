# Software Factory Intensive

Hands-on, project-based workshop to learn how to build a software factory — a system of AI agents that can plan, architect, code, review, and deploy software continuously.

| | |
|---|---|
| **Format** | Self-paced walkthroughs (9 sessions: 4 workshops + 4 labs + 1 capstone) |
| **Estimated total time** | ~9 hours of guided work |
| **Reference project** | [Fired Up Pizza](reference-project/) |

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
  - **Recommended**: Claude Code Max (20x) or Codex Pro (20x)
  - **Minimum**: Claude Code Max or Codex Pro (standard tier)
  - **Alternatives**: Gemini CLI, OpenCode (compatibility not guaranteed)

### 2. Gas City Installation

Refer to the Gas City [Installation Guide](https://github.com/gastownhall/gascity/blob/main/docs/getting-started/installation.md) for the full dependency list and platform-specific notes.

**Note: Gas City is pinned to v0.14.1 for this curriculum.** Check your version: `gc version`

If your version differs, install the pinned version:
```bash
brew tap-new $USER/local
brew extract --version=0.14.1 gastownhall/gascity/gascity $USER/local
brew install gascity@0.14.1
```

### 3. Python Installation

[Python 3.8+](https://www.python.org/downloads/) is required to run the factory-activity-agent script, which makes the curriculum setup and teardown much easier. You can check your Python version with `python3 --version`.

### 4. Clone the `software-factory-intensive` repo

Clone the `software-factory-intensive` repo locally into a new project directory (this specific path is important for the factory-activity-agent to work correctly):
```bash
mkdir -p ~/Projects/actual-software/
git clone https://github.com/actual-software/software-factory-intensive.git ~/Projects/actual-software/software-factory-intensive
```

### 5. Software Project Overview

You should bring a real software project to build your factory around. Before starting the curriculum, write a **Project Overview** for it using [`PROJECT_OVERVIEW_TEMPLATE.md`](PROJECT_OVERVIEW_TEMPLATE.md) — a loosely structured document that answers a few questions about the project. Your local coding agent will generate the Project Manifest and Software Factory Manifest from this document. You can see [`reference-project/fired-up-pizza/docs/PROJECT_OVERVIEW.md`](reference-project/docs/PROJECT_OVERVIEW.md) for a completed example.

---

## Why Gas City

This curriculum is built on top of [Gas City](https://github.com/gastownhall/gascity), an open-source framework for running multi-agent systems. Gas City abstracts the primitives of multi-agent coordination — agents, packs, rigs, beads, sessions, orders, routes — so that any multi-agent architecture can be expressed within the same framework rather than re-invented each time.

We use Gas City here because the 6-agent factory is one instance of a much broader pattern. Once you've learned the primitives, you can swap out the specific agent roles and build pipelines for code review, research, data processing, ops automation — the framework doesn't care what the agents do. The goal of the workshop is to make these primitives internalized enough that you can design your own multi-agent systems after you leave.

For the authoritative definitions of every Gas City term used across the curriculum (agent, pack, rig, bead, sling, order, route, formula, overlay, etc.), see the glossary: [Gas City glossary](https://github.com/gastownhall/gascity/blob/main/engdocs/architecture/glossary.md). Skim it once before W1 and keep it open as a reference during the labs.

---

## The 6-Agent Software Factory

Across 9 sessions you build a factory of six AI agents that turn feature requests into deployed code:

```
Feature Request → Planner → Architect → Designer → Coder → Reviewer → Deployer → Functional Software
```

| Role (curriculum) | Shipped pack | What It Does |
|-------------------|-------------|---------------------------------------|
| **Planner** | `packs/planner` | Breaks features into structured work packages |
| **Architect** | `packs/architect` | Makes technical decisions, produces ADRs |
| **Designer** | `packs/designer` | Creates component/module specs and documentation |
| **Coder** | `packs/coder` | Implements code from specs |
| **Reviewer** | `packs/reviewer` | Reviews code against specs and standards; verifies acceptance-criteria coverage |
| **Deployer** | `packs/deployer` | Evaluates release gates and deploys functional software |

W4 introduces an **optional 7th agent**, the **Improver** (`packs/improver`), for continuous-improvement loops that feed runtime signals back into the factory. It is not part of the essential 6 — the factory runs end-to-end without it.

The agents hand work off via **labels on beads** ([beads](https://github.com/gastownhall/beads) is a dependency-aware graph for issue tracking). A bead walks the factory by being re-labeled at each stage: `needs-plan` → `needs-architecture` → `needs-design` → `ready-to-build` → `needs-review` → `ready-to-ship` → closed. Each agent watches the queue for the label aimed at it and re-labels the bead for the next stage. See [`LABELED_BEADS.md`](LABELED_BEADS.md) for the canonical reference — this is foundation material for every workshop and lab.

## Core Principle: Config Over Prompting

The single most important discipline this workshop teaches: **change agent behavior through config, not through ad-hoc prompting.**

When an agent produces wrong output, update its config file and re-run — don't type a correction into the chat. This discipline is the bridge between individual AI use and a factory that runs 24/7 without a human at the keyboard.

---

## Session Map

| ID | Type | Estimated Duration | Title |
|----|------|--------------------|-------|
| [W1](curriculum/workshops/W1/) | Workshop | ~60 min | Run the 6-Agent Software Factory |
| [W2](curriculum/workshops/W2/) | Workshop | ~45 min | From Individual AI Workflow to Software Factory Pipeline |
| [L1](curriculum/labs/L1/) | Lab | ~60 min | Build a Structured Development Loop |
| [W3](curriculum/workshops/W3/) | Workshop | ~45 min | Architect Multi-Agent Coordination |
| [L2](curriculum/labs/L2/) | Lab | ~75 min | Deploy Planner + Architect Agents |
| [L3](curriculum/labs/L3/) | Lab | ~75 min | Deploy Designer + Coder Agents |
| [L4](curriculum/labs/L4/) | Lab | ~75 min | Deploy Reviewer + Deployer Agents |
| [W4](curriculum/workshops/W4/) | Workshop | ~45 min | Create Continuous Improvement Loops |
| [L5](curriculum/labs/L5/) | Capstone Lab | ~90 min | Run the Software Factory End-to-End |

---

## Repo Structure

```
software-factory-intensive/
├── curriculum/
│   ├── labs/L1..L5/                 # Participant-led, exploratory work sessions
│   └── workshops/W1..W4/            # Instructor-led, structured sessions
├── factory-activity-agent/                # factory-activity-agent skill to manage the curriculum
├── images/                          # Images for the curriculum
├── packs/                           # Packs containing agents and configurations for the curriculum
│   ├── all/                         # Composite 6-agent factory
│   ├── architect/                   # Added in L2
│   ├── coder/                       # Added in L3
│   ├── deployer/                    # Added in L4
│   ├── designer/                    # Added in L3
│   ├── fired-up-pizza/              # Demonstrated in W1
│   ├── improver/                    # Optional 7th — introduced in W4
│   ├── planner/                     # Added in L2
│   ├── reviewer/                    # Added in L4
│   ├── workshop/                    # [Experimental] Plug-and-play integrations pack (Jira, Linear, GitHub, etc.)
│   └── README.md
├── reference-project/               # Pizza restaurant website project with complete 6-agent factory 
├── scripts/                         # Scripts for the curriculum
├── LABELED_BEADS.md                 # Label reference for beads handoff process
├── PROJECT_MANIFEST_TEMPLATE.md     # Template for the project manifest (agent-generated in orientation)
├── PROJECT_OVERVIEW_TEMPLATE.md     # Template for the project overview (you fill in)
├── README.md                        # You are here
└── TROUBLESHOOTING.md               # Troubleshooting guide
```

---

## Curriculum Guide

### The additive, independent model

Every session ships ready-to-use reference packs under `../packs/<agent>/`. The curriculum is designed so that **skipping a session does not break the pipeline** — you just include the shipped pack as-is instead of your own customised copy.

Within a session you can customise a pack with the following steps:

1. **Copy it** — `cp -r ../../packs/<agent> packs/<agent>/` inside the session's activity folder (you may do this multiple times in a session).
2. **Edit your copy** — edit the prompt or formula to suit your project.
3. **Point `../../my-factory/city.toml`'s `includes`** at `../activities/<session>/packs/<agent>` instead of the shipped `../packs/<agent>`.

At the end of the session you **update `../my-factory/city.toml`** to have your factory running with your customised packs. Each session's README tells you the exact lines.

### Typical session flow

1. Open `../curriculum/<session>/README.md` and read the walkthrough.
2. Work inside this session's folder (`activities/<session>/`). Most sessions will modify some portion of your factory.
3. For labs that deploy new agents: copy the shipped pack(s) into `activities/<session>/packs/<agent>/`, customise, and wire it into `../my-factory/city.toml`. (If you skip customisation, just wire the shipped `../packs/<agent>` path directly.)
4. Run `gc service restart && gc doctor` from `../my-factory/` to reload the city.

### Getting un-stuck

If a session breaks your factory:

1. `git checkout activities/<session>/packs/` to discard the customised pack copy.
2. Edit `../my-factory/city.toml` so the include points at `../packs/<name>` (shipped) instead of `../activities/<session>/packs/<name>` (your copy).
3. `gc service restart` from `my-factory/`.

You lose the customisation but keep a working factory, and you can retry the customisation later.

---

## Next Steps

Ready to get started? Jump to [W1](curriculum/workshops/W1/) to start.

---

## Troubleshooting

If you encounter any issues during the workshop, please refer to the [Troubleshooting Guide](TROUBLESHOOTING.md) for solutions.
