# L1 · Agent instructions + project rig

> **Goal:** Understand how the configuration of a software factory depends on the nature of the project it is building, and how to adapt the configuration to the specific needs of the project.

L1 converts the workflow card from W1 into agent-readable config and registers your project with Gas City. You are not running agents yet — that starts in L2.

| | |
|---|---|
| **Estimated duration** | ~15 minutes |
| **Type** | LAB |
| **Deliverable** | A registered Gas City city with your project rig ready for L2 |

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│   PROJECT_MANIFEST.md and agent instructions             │
│   (ex. CLAUDE.md for Claude Code, AGENTS.md for others)  │
│  Overview · Tech Stack · Domain Model · Conventions      │
│  Review Standards · Release Criteria · Task Inputs       │
└───────┬──────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│   6-agent factory installed against YOUR project         │
│                                                          │
│   Planner ──▶ Architect ──▶ Designer ──▶ Coder           │
│       ▲                                     │            │
│       │                                     ▼            │
│  input sources                     Reviewer ──▶ Deployer │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## Goal

By the end of L1:

- Your W1 workflow card is converted to your relevant agent instruction files (ex. `CLAUDE.md` for Claude Code, `AGENTS.md` for OpenCode/Codex CLI/etc.)
- Gas City is registered with formula v2 enabled
- Your project rig is ready for L2

## Directories used in this lab

L1 moves between two directories. Each step below tells you which one to be in.

- `~/path/to/your-project` — your project repo (the rig).
- `~/path/to/software-factory-intensive` — this curriculum repo (where `my-factory/` lives).

## Prerequisites

Before starting, confirm you have already produced the two files described in the main [`README.md`](../../../README.md) ("Before You Start", sections 5–6):

- `~/path/to/your-project/docs/PROJECT_OVERVIEW.md`
- `~/path/to/your-project/docs/PROJECT_MANIFEST.md`

If you haven't, create them now from `curriculum/PROJECT_OVERVIEW_TEMPLATE.md` and `curriculum/PROJECT_MANIFEST_TEMPLATE.md` — L2 onward will read them.

## 1. Convert Your Workflow Card to Agent Instructions (~5 min)

**Working in:** `~/path/to/your-project`.

Your W1 workflow card already contains your project rules. Convert it into the file(s) your CLI coding agent(s) read at the project root:

```bash
cd ~/path/to/your-project
# For Claude Code:
$EDITOR CLAUDE.md
# For OpenCode, Codex CLI, Gemini CLI, etc.:
$EDITOR AGENTS.md
```

You can create both files (some agents read one, some read the other; some read both). If you only use one agent, create only the file it reads.

Map from your workflow card:

| W1 Section | Agent Instruction File Equivalent |
|------------|-----------------------------------|
| Prompt Template | Project purpose, tech stack, build/test/lint commands |
| Context Reset Rule | Session lifecycle notes |
| Iteration Loop | Coding standards, source layout |
| Decision Checkpoint | Files agents must not edit, decisions requiring approval |

Keep it concrete. Every bullet should name a file, command, or specific rule — the same specificity discipline from W1.

## 2. Register the City (~5 min)

**Switch to:** `~/path/to/software-factory-intensive` (the curriculum repo) for the rest of this lab.

Create local runtime config from templates:

```bash
cd ~/path/to/software-factory-intensive
cp my-factory/pack.toml.template my-factory/pack.toml
cp my-factory/city.toml.template my-factory/city.toml
```

Confirm `my-factory/city.toml` has formula v2 enabled:

```toml
[daemon]
formula_v2 = true
```

The default `my-factory/pack.toml` selects the first runnable lesson factory:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/L2"
```

Register the city and add your project rig. From `my-factory/`:

```bash
cd my-factory     # now in ~/path/to/software-factory-intensive/my-factory
gc register .
gc rig add ~/path/to/your-project
gc doctor --fix
gc status
```

`gc rig add` derives the rig name from the project directory's basename (e.g. `your-project`). Note this name — every later lab will refer to it as `<rig>`.

Later labs keep using the same rig so artifacts accumulate naturally.

### Initialize the city's beads database

The supervisor needs its own beads store. Initialize it explicitly from `my-factory/`:

```bash
# still in my-factory/
git config beads.role maintainer
bd init --reinit-local --prefix mf --discard-remote --destroy-token DESTROY-mf
```

If you skip this, or if `gc doctor` / a later `gc sling` reports `bd create: ... issue_prefix config is missing`, see [troubleshooting/beads.md#issue-issue_prefix-config-is-missing](../../../troubleshooting/beads.md#issue-issue_prefix-config-is-missing).

`bd init` and the supervisor will also drop a few transient files into `my-factory/` (`AGENTS.md`, `CLAUDE.md`, `.claude/`, `control-dispatcher-trace.log`, `packs.lock`). They are listed in `my-factory/.gitignore`, so `git status` should still come up clean.

## 3. Verify (~2 min)

**Switch to:** `~/path/to/your-project`.

```bash
cd ~/path/to/your-project
git status --short
npm test
# or your project's equivalent (e.g. `node --test`)
```

If a command fails, fix your agent instruction file (ex. `CLAUDE.md`) before moving on. Later agents will rely on these instructions.

## Exit Criteria

- [ ] The relevant agent instruction file (ex. `CLAUDE.md` for Claude Code, `AGENTS.md` for OpenCode/Codex CLI/etc.) exists in the project rig with project-specific rules.
- [ ] `~/path/to/your-project/docs/PROJECT_MANIFEST.md` exists with overview, tech stack, and project structure.
- [ ] `my-factory/city.toml` enables formula v2.
- [ ] `my-factory/pack.toml` selects `../packs/lessons/L2` as `factory`.
- [ ] `gc status` (run from `my-factory/`) shows your city and project rig.

## Next

**[W2](../../workshops/W2/README.md)** comes next — you'll design the factory structure (roles, artifacts, handoff contracts) before running it. Then **[L2](../../labs/L2/README.md)** runs the first slice of that design: Planner and Architect agents on a real feature request.

You do not need to run agents before W2. The design comes first so you understand what each role does before watching it work. Your rig stays registered — L2 will use the same one.
