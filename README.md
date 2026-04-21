<h1><img src="images/software_factory_intensive_title.svg" alt="Software Factory Intensive"></h1>

<p>
  Event by <a href="https://aitinkerers.org/"><img src="images/ai_tinkerers.png" alt="AI Tinkerers" height="28" valign="middle"></a>
  &nbsp;|&nbsp;
  Hosted by <a href="https://www.actual.ai/"><img src="images/actual_ai.png" alt="Actual AI" height="28" valign="middle"></a>
</p>

Hands-on, project-based workshop to learn how to build a software factory — a system of AI agents that can plan, architect, code, review, and deploy software continuously.

| | |
|---|---|
| **Format** | Self-paced walkthroughs (9 sessions: 4 workshops + 4 labs + 1 capstone) |
| **Estimated total time** | ~9 hours of guided work |
| **Reference project** | [Fired Up Pizza](reference-project/fired-up-pizza/) |

---

## Community & Support

Stuck on a step, want to share what you've built, or looking to collaborate with other participants? Join the **Actual AI User Community** Slack:

- Join the [Actual AI User Community Slack](https://join.slack.com/t/actualaiusercommunity/shared_invite/zt-3vibgzapf-ywx0Db29mZ4lhtQJGzZfGQ), then join the [#sfi-seattle-2026 channel](https://actualaiusercommunity.slack.com/archives/C0AU22650RZ). Here you can share what you've built, ask questions, and get help from other participants.

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
brew update
brew tap-new $USER/local
brew extract --force --version=0.14.1 gastownhall/gascity/gascity $USER/local
brew install gascity@0.14.1
```

### 3. Python Installation

[Python 3.8+](https://www.python.org/downloads/) is required to run the factory-activity-agent script, which makes the curriculum setup and teardown much easier. You can check your Python version with `python3 --version`.

### 4. Clone the `software-factory-intensive` repo

Clone the [software-factory-intensive](https://github.com/actual-software/software-factory-intensive) repo locally into a new project directory. **Note**: the path specified below is important for the workshops and labs to run correctly:
```bash
mkdir -p ~/Projects/actual-software/
git clone https://github.com/actual-software/software-factory-intensive.git ~/Projects/actual-software/software-factory-intensive
```

### 5. Software Project Overview

You should bring a real software project to build your factory around. Before starting the curriculum, write a **Project Overview** for it using [`PROJECT_OVERVIEW_TEMPLATE.md`](PROJECT_OVERVIEW_TEMPLATE.md) — a loosely structured document that answers a few questions about the project. Your local coding agent will generate the Project Manifest and Software Factory Manifest from this document. You can see [`reference-project/fired-up-pizza/docs/PROJECT_OVERVIEW.md`](reference-project/fired-up-pizza/docs/PROJECT_OVERVIEW.md) for a completed example.

During the intensive, you will use a [Manifest Generator Skill](https://github.com/audiojak/manifest-generator) to go from your project overview to a coherent, structured `PROJECT_MANIFEST.md` file that the software factory agents read from.

---

## Why Gas City

This curriculum is built on top of [Gas City](https://github.com/gastownhall/gascity), an open-source framework for running multi-agent systems. Gas City abstracts the primitives of multi-agent coordination — agents, packs, rigs, beads, sessions, orders, routes — so that any multi-agent architecture can be expressed within the same framework rather than re-invented each time.

We use Gas City here because the 6-agent factory is one instance of a much broader pattern. Once you've learned the primitives, you can swap out the specific agent roles and build pipelines for code review, research, data processing, ops automation — the framework doesn't care what the agents do. The goal of the workshop is to make these primitives internalized enough that you can design your own multi-agent systems after you leave.

For the authoritative definitions of every Gas City term used across the curriculum (agent, pack, rig, bead, sling, order, route, formula, overlay, etc.), see the glossary: [Gas City glossary](https://github.com/gastownhall/gascity/blob/main/engdocs/architecture/glossary.md). Here is the brief summary:

| Gas City Term | Analogous Term |
|---------------|----------------|
| bead   | Issue / ticket / task |
| convoy | Epic / batch |
| dog    | Daemon / cron worker |
| formula| Workflow / pipeline / recipe |
| mail   | Message / inbox item |
| order  | Cron job / scheduled task |
| pack   | Plugin / module / package |
| rig    | Workspace / repository |
| sling  | Job dispatch / enqueue |

---

## The 6-Agent Software Factory

Across 9 sessions you will build a factory of agents that turn feature requests into deployed software:

```
Feature Request → Planner → Architect → Designer → Coder → Reviewer → Deployer → Functional Software → Improver
```

| Agent Role | Shipped pack | What It Does |
|-------------------|-------------|---------------------------------------|
| **Architect** | `packs/architect` | Makes technical decisions, produces ADRs |
| **Coder** | `packs/builder` | Implements code from specs |
| **Deployer** | `packs/deployer` | Evaluates release gates and deploys functional software |
| **Designer** | `packs/designer` | Creates component/module specs and documentation |
| **Improver** | `packs/improver` | Additional process to collect runtime signals and feed them back into the factory |
| **Planner** | `packs/planner` | Breaks features into structured work packages |
| **PM** | `packs/pm` | Shreds architecture and design documents into atomic tasks |
| **Reviewer** | `packs/reviewer` | Reviews code against specs and standards; verifies acceptance-criteria coverage |
| **Supervisor** | `packs/supervisor` | Monitors the factory and ensures it is running smoothly |

## Core Principle: Config Over Prompting

The single most important discipline this workshop teaches: **change agent behavior through config, not through ad-hoc prompting.**

When an agent produces wrong output, update its config file and re-run — don't type a correction into the chat. This discipline is the bridge between individual AI use and a factory that runs 24/7 without a human at the keyboard.

---

## Session Map (in order of completion)

| ID | Type | Estimated Duration | Title |
|----|------|--------------------|-------|
| [W1](curriculum/workshops/W1/WORKSHOP_1_GUIDE.md) | Workshop | ~60 min | Run the 6-Agent Software Factory |
| [W2](curriculum/workshops/W2/WORKSHOP_2_GUIDE.md) | Workshop | ~45 min | From Individual AI Workflow to Software Factory Pipeline |
| [L1](curriculum/labs/L1/LAB_1_GUIDE.md) | Lab | ~60 min | Build a Structured Development Loop |
| [W3](curriculum/workshops/W3/WORKSHOP_3_GUIDE.md) | Workshop | ~45 min | Architect Multi-Agent Coordination |
| [L2](curriculum/labs/L2/LAB_2_GUIDE.md) | Lab | ~75 min | Deploy Planner + Architect Agents |
| [L3](curriculum/labs/L3/LAB_3_GUIDE.md) | Lab | ~75 min | Deploy Designer + Coder Agents |
| [L4](curriculum/labs/L4/LAB_4_GUIDE.md) | Lab | ~75 min | Deploy Reviewer + Deployer Agents |
| [W4](curriculum/workshops/W4/WORKSHOP_4_GUIDE.md) | Workshop | ~45 min | Create Continuous Improvement Loops |
| [C1](curriculum/capstone/C1/CAPSTONE_1_GUIDE.md) | Capstone Lab | ~90 min | Run the Software Factory End-to-End |

---

## Repo Structure

```
software-factory-intensive/
├── activities/                      # Activities directory for participants to do their work
├── curriculum/                      # Read-only directory for the curriculum walkthroughs
├── docs/                            # General documentation for the curriculum
├── images/                          # Images for the curriculum
├── packs/                           # Packs containing agents and configurations for the curriculum
│   ├── all/                         # Composite 6-agent factory
│   ├── architect/                   # Added in L2
│   ├── builder/                     # Added in L3
│   ├── designer/                    # Added in L3
│   ├── fired-up-pizza/              # Demonstrated in W1
│   ├── improver/                    # Additional process in W4
│   ├── planner/                     # Added in L2
│   ├── release-gate/                # Added in L4
│   ├── reviewer/                    # Added in L4
│   ├── validator/
│   ├── workshop/                    # [Experimental] Plug-and-play integrations pack (Jira, Linear, GitHub, etc.)
│   ├── city.toml
│   └── README.md
├── reference-project/               # Pizza restaurant website project with complete 6-agent factory 
├── scripts/                         # Scripts for the curriculum
├── skills
│   └── factory-activity-agent/      # /factory-activity-agent skill to manage the curriculum
├── PROJECT_MANIFEST_TEMPLATE.md     # Template for the project manifest (filled in by the manifest generator skill)
├── PROJECT_OVERVIEW_TEMPLATE.md     # Template for the project overview (filled in by you)
├── README.md                        # You are here
└── troubleshooting/                 # Topic-scoped troubleshooting guides (gas city, cli coding agents, beads, tmux)
```

---

## Next Steps

Ready to get started? Jump to [W1](curriculum/workshops/W1/WORKSHOP_1_GUIDE.md) to start.

---

## Troubleshooting

If you encounter any issues during the workshop, jump to the relevant guide under [`troubleshooting/`](troubleshooting/).
