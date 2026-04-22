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

You should bring a real software project to build your factory around. Before starting the curriculum, write a **Project Overview** for it using [`PROJECT_OVERVIEW_TEMPLATE.md`](PROJECT_OVERVIEW_TEMPLATE.md) — a loosely structured document that answers a few questions about the project. Save it as `docs/PROJECT_OVERVIEW.md` inside your local clone of this repo (i.e. `~/Projects/actual-software/software-factory-intensive/docs/PROJECT_OVERVIEW.md`) — that path is the **central deliverables folder** the rest of the curriculum reads from and writes to. You can see [`reference-project/fired-up-pizza/docs/PROJECT_OVERVIEW.md`](reference-project/fired-up-pizza/docs/PROJECT_OVERVIEW.md) for a completed example.

### 6. Generate a `PROJECT_MANIFEST.md` and `SOFTWARE_FACTORY_MANIFEST.md`

Download the [Manifest Generator Skill](https://github.com/audiojak/manifest-generator) and run it with your `PROJECT_OVERVIEW.md` file as input. The skill will facilitate the steps to go from your project overview to a coherent, structured `PROJECT_MANIFEST.md` file. The skill will also generate a `SOFTWARE_FACTORY_MANIFEST.md` file that maps out the software factory pipeline. Save the generated manifests as `docs/PROJECT_MANIFEST.md` and `docs/SOFTWARE_FACTORY_MANIFEST.md` in the same central folder.

---

## Central Deliverables Folder

Every cross-session deliverable you author during the curriculum (`PROJECT_MANIFEST.md`, `SOFTWARE_FACTORY_MANIFEST.md`, `factory-pipeline.md`, `coordination-channels.md`, `improvement-criteria.md`, `factory-iterations.md`) lives in one place: **`software-factory-intensive/docs/`** in your local clone of this repo.

When you run `/factory-activity-agent install <session>`, the install script will copy everything from `software-factory-intensive/docs/` into the new session's `~/Projects/factory/<slug>/<workspace>-project/docs/` automatically. This means you do not need to copy documents between session workspaces — you author once at the central path, and every later session install picks the file up.

These deliverables can be tracked in git if you `commit` them on your own branch (or fork) as you author them. That gives you durable history of how each deliverable evolved across sessions, plus the option to share your run with teammates or compare against the reference.

> **Special case — W1**: `W1` runs against the **Fired Up Pizza** reference project. The install script seeds W1's workspace from `reference-project/fired-up-pizza/docs/` instead of `software-factory-intensive/docs/`, so W1 always uses the canonical reference manifest regardless of what you've authored.

## Backup Project Setup

If you don't want to bring your own project — or you want a known-good fallback — use the **Fired Up Pizza** reference project as a substitute. There are two pieces to copy in.

To skip authoring deliverables and use the reference set instead:

```bash
cp -R /path/to/software-factory-intensive/reference-project/fired-up-pizza/docs/. \
      /path/to/software-factory-intensive/docs/
```

You can also cherry-pick. For example, copy only `factory-pipeline.md` if you want to skip W2 but author the rest yourself:

```bash
cp /path/to/software-factory-intensive/reference-project/fired-up-pizza/docs/factory-pipeline.md \
   /path/to/software-factory-intensive/docs/
```

The reference set covers every cross-session deliverable: `PROJECT_OVERVIEW.md`, `PROJECT_MANIFEST.md`, `factory-pipeline.md`, `coordination-channels.md`, `improvement-criteria.md`, `factory-iterations.md`, `c1-run-report.md`, plus an example `adr/` and `gates/`. From the next install onwards, your session workspaces pick these up automatically.

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

Each session has a concrete deliverable — what you should walk away having produced. The summary column below is the at-a-glance version; each guide opens with a full `## Deliverable` section that names the exact files, paths, and runtime state.

| ID | Type | Duration | Title | Deliverable |
|----|------|----------|-------|-------------|
| `O1` | Orientation | ~30 min | Factory Roadmap for Your Project | `docs/PROJECT_MANIFEST.md` and `docs/SOFTWARE_FACTORY_MANIFEST.md` |
| [W1](curriculum/workshops/W1/WORKSHOP_1_GUIDE.md) | Workshop | ~60 min | Run the 6-Agent Software Factory | Reference factory running against Fired Up Pizza and the `factory-activity-agent` skill installed |
| [W2](curriculum/workshops/W2/WORKSHOP_2_GUIDE.md) | Workshop | ~45 min | From Individual AI Workflow to Software Factory Pipeline | `docs/factory-pipeline.md` |
| [L1](curriculum/labs/L1/LAB_1_GUIDE.md) | Lab | ~60 min | Build a Structured Development Loop | A 6-agent factory installed against **your** project |
| [W3](curriculum/workshops/W3/WORKSHOP_3_GUIDE.md) | Workshop | ~45 min | Architect Multi-Agent Coordination | `docs/coordination-channels.md` |
| [L2](curriculum/labs/L2/LAB_2_GUIDE.md) | Lab | ~75 min | Deploy Planner + Architect Agents | Planner and Architect each equipped with at least one Skill/CLI capability |
| [L3](curriculum/labs/L3/LAB_3_GUIDE.md) | Lab | ~75 min | Deploy Designer + Coder Agents | Designer and Coder each equipped with at least one MCP |
| [L4](curriculum/labs/L4/LAB_4_GUIDE.md) | Lab | ~75 min | Deploy Reviewer + Deployer Agents | Reviewer and Deployer reading their manifest sections (Review Standards + Release Criteria) |
| [W4](curriculum/workshops/W4/WORKSHOP_4_GUIDE.md) | Workshop | ~45 min | Create Continuous Improvement Loops | `docs/improvement-criteria.md` and `docs/factory-iterations.md` |
| [C1](curriculum/capstone/C1/CAPSTONE_1_GUIDE.md) | Capstone Lab | ~90 min | Run the Software Factory End-to-End | All 6 custom agents wired together as a complete software factory running against your software project, with a `docs/c1-run-report.md` describing the run |

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
