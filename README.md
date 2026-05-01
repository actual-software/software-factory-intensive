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

The active curriculum is built around self-contained lesson packs. Each runnable lab has one complete factory under `packs/lessons/<lesson>/`: agents, prompts, formulas, doctors, and commands live together so students can inspect the whole system in one place.

## Community & Support

Stuck on a step, want to share what you've built, or looking to collaborate with other participants? Join the **Actual AI User Community** Slack:

- Join the [Actual AI User Community Slack](https://join.slack.com/t/actualaiusercommunity/shared_invite/zt-3vibgzapf-ywx0Db29mZ4lhtQJGzZfGQ), then join [#sfi-seattle-2026](https://actualaiusercommunity.slack.com/archives/C0AU22650RZ). Here you can share what you've built, ask questions, and get help from other participants.

## Before You Start

### 1. Follow installation guide

Please read the [installation guide](installation.md) to install the necessary tools and dependencies.

### 5. Software Project Overview

You should bring a real software project to build your factory around. Before starting the curriculum, write a **Project Overview** for it in `~/path/to/your-project/docs/PROJECT_OVERVIEW.md` using [`PROJECT_OVERVIEW_TEMPLATE.md`](curriculum/PROJECT_OVERVIEW_TEMPLATE.md) — a loosely structured document that answers a few questions about the project.

```bash
mkdir -p ~/path/to/your-project/docs
cp curriculum/PROJECT_OVERVIEW_TEMPLATE.md ~/path/to/your-project/docs/PROJECT_OVERVIEW.md
```

Then fill in the template with your project details. See [`reference-project/fired-up-pizza/docs/PROJECT_OVERVIEW.md`](reference-project/fired-up-pizza/docs/PROJECT_OVERVIEW.md) for a completed example.


### 6. Generate the Project Manifest and Software Factory Manifest

While in your project directory, download and install the [Manifest Generator Skill](https://github.com/audiojak/manifest-generator):

```bash
cd ~/path/to/your-project/docs
npx skills add https://github.com/audiojak/manifest-generator
```

Follow the steps to install the skill for your specific coding agent(s). Each agent has its own skill location — for example, Claude Code reads `.claude/skills`, OpenCode/Codex CLI/etc. read other paths. Select the install option matching your agent, then choose the Installation scope and Method (Symlink recommended).

Once the skill is installed, you can invoke it inside a session with your coding agent (Claude Code, Codex CLI, OpenCode, etc.):

```bash
# Claude Code:
claude /manifest-generator
# Or invoke `/manifest-generator` inside whichever CLI coding agent you use.
```

The agent should provide some prompts to guide you through the process. You can also reference the [Manifest Generator Skill](https://github.com/audiojak/manifest-generator) documentation for more details. The end result should be `PROJECT_MANIFEST.md` and `SOFTWARE_FACTORY_MANIFEST.md` files in your project directory.

## Why Gas City

This curriculum is built on top of [Gas City](https://github.com/gastownhall/gascity), an open-source framework for running multi-agent systems. Gas City abstracts the primitives of multi-agent coordination — agents, packs, rigs, beads, sessions, orders, routes — so that any multi-agent architecture can be expressed within the same framework rather than re-invented each time.

We use Gas City here because the curriculum factory is just one example of a multi-agent system. Once you've learned the primitives, you can swap out the specific agent roles and build pipelines for code review, research, data processing, ops automation — the framework doesn't care what the agents do. The goal of the workshop is to make these primitives internalized enough that you are confident designing your own multi-agent systems after you leave.

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

## Architecture

The student path is:

```text
choose lesson factory pack -> sync the existing project rig -> sling one request -> formula routes work
```

Formulas define the workflow graph; beads record runtime work and artifacts; labels are metadata for searching and reporting.

## Repo Layout

```text
software-factory-intensive/
├── my-factory/                 # city templates and quickstart
├── packs/
│   ├── lessons/
│   │   ├── L2/                 # planner + architect factory
│   │   ├── L3/                 # planner + architect + designer + builder
│   │   ├── L4/                 # delivery review factory
│   │   └── C1/                 # end-to-end release factory
│   └── workshop/               # optional service-integration helpers
├── curriculum/                 # long-form walkthroughs
├── activities/                 # student deliverables and short instructions
└── reference-project/          # example project artifacts
```

## Lesson Packs

Each lesson pack is portable factory code. The folder name may include a lesson number for navigation, but files inside the pack should read like production factory definitions: no prompt should tell an agent it is in a class, lab, or workshop.

| Lesson | Factory Pack | Entry Formula | Entry Target |
|---|---|---|---|
| L2 | `packs/lessons/L2` | `mol-feature-intake` | `<rig>/factory.planner` |
| L3 | `packs/lessons/L3` | `mol-feature-delivery` | `<rig>/factory.planner` |
| L4 | `packs/lessons/L4` | `mol-delivery-review` | `<rig>/factory.planner` |
| C1 | `packs/lessons/C1` | `mol-release-delivery` | `<rig>/factory.planner` |

## Core Principle: Config Over Prompting

The single most important discipline this workshop teaches: **change agent behavior through config, not through ad-hoc prompting.**

When an agent produces wrong output, update its config file and re-run — don't type a correction into the chat. This discipline is the bridge between individual AI use and a factory that runs 24/7 without a human at the keyboard.

## Session Map (in order of completion)

Each session has a concrete deliverable — what you should walk away having produced. The summary column below is the at-a-glance version; each guide opens with a full `## Deliverable` section that names the exact files, paths, and runtime state.

| ID | Type | Duration | Title | Deliverable |
|----|------|----------|-------|-------------|
| [W1](curriculum/workshops/W1/README.md) | Workshop | ~60 min | Optimize the Individual AI Workflow | `workflow-card.md` that describes how *you*, personally, drive a CLI coding agent on a single feature end-to-end |
| [L1](curriculum/labs/L1/README.md) | Lab | ~15 min | Agent instructions + project rig | Working `my-factory/` gas city implementation connected to your project rig |
| [W2](curriculum/workshops/W2/README.md) | Workshop | ~45 min | Design The Software Factory | `factory-map.md` that explains which role owns each kind of decision, which artifact each role writes, which formula step should route to that role, which checks prove the step is done, and which context the next step needs |
| [L2](curriculum/labs/L2/README.md) | Lab | ~75 min | Deploy Planner + Architect Agents | Planner and Architect each equipped with at least one MCP capability |
| [L3](curriculum/labs/L3/README.md) | Lab | ~75 min | Deploy Designer + Coder Agents | Designer and Coder each equipped with at least one Skill or CLI tool |
| [W3](curriculum/workshops/W3/README.md) | Workshop | ~45 min | Architect Multi-Agent Coordination | `formula-design.md` that explains how your factory should coordinate work |
| [L4](curriculum/labs/L4/README.md) | Lab | ~75 min | Deploy Reviewer + DevOps Agents | Reviewer and DevOps (a.k.a Release Gate) agents reading their manifest sections (Review Standards + Release Criteria) |
| [W4](curriculum/workshops/W4/README.md) | Workshop | ~45 min | Create Continuous Improvement Loops | `improvement-criteria.md` that defines the signals your factory emits and the criteria you'll use to judge improvement |
| [C1](curriculum/capstone/C1/README.md) | Capstone Lab | ~90 min | Run the Software Factory End-to-End | All 6 custom agents wired together as a complete software factory running against your software project, with a `retrospective.md` describing the run |

## Quickstart

The Quickstart spans two directories. Each block is annotated with which one to be in. From `~/path/to/software-factory-intensive` (the curriculum repo), create local runtime config from the templates:

```bash
cp my-factory/pack.toml.template my-factory/pack.toml
cp my-factory/city.toml.template my-factory/city.toml
```

Then, from `my-factory/`, register the city and add your project rig:

```bash
cd my-factory     # now in ~/path/to/software-factory-intensive/my-factory
gc register .
gc rig add ~/path/to/your-repo/
gc doctor --fix
```

If `gc doctor` reports `bd create: ... issue_prefix config is missing`, see [troubleshooting/beads.md#issue-issue_prefix-config-is-missing](troubleshooting/beads.md#issue-issue_prefix-config-is-missing).

The default template selects the L2 factory:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/L2"
```

When you move to another runnable lesson, update that source path and sync the existing rig (still in `my-factory/`):

```bash
gc --rig your-project import remove factory
gc --rig your-project import add ../packs/lessons/L3 --name factory
```

Then sling work to the lesson formula (replace `<rig>` with your rig name and the feature description with your own):

```bash
gc sling <rig>/factory.planner \
  "<a small feature for your project>" \
  --on mol-feature-delivery
```

Watch progress with:

```bash
gc events --follow
gc session list
gc session peek your-project/factory.planner
gc graph <workflow-bead-id>
```

## Next Steps

Start with [`curriculum/workshops/W1/README.md`](curriculum/workshops/W1/README.md), then follow the session map in [`curriculum/README.md`](curriculum/README.md).

## Troubleshooting

If you encounter any issues during the intensive, jump to the relevant guide under [`troubleshooting/`](troubleshooting/).
