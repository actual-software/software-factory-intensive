# L1 · CLAUDE.md + first feature

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
│        PROJECT_MANIFEST.md and CLAUDE.md                 │
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

- Your W1 workflow card is converted to a `CLAUDE.md`
- Gas City is registered with formula v2 enabled
- Your project rig is ready for L2

## 1. Convert Your Workflow Card to CLAUDE.md (~5 min)

Your W1 workflow card already contains your project rules. Convert it into the file your CLI agent reads:

```bash
cd /path/to/your-project
$EDITOR CLAUDE.md
```

If you use another agent that reads `AGENTS.md`, use that filename instead.

Map from your workflow card:

| W1 Section | CLAUDE.md Equivalent |
|------------|---------------------|
| Prompt Template | Project purpose, tech stack, build/test/lint commands |
| Context Reset Rule | Session lifecycle notes |
| Iteration Loop | Coding standards, source layout |
| Decision Checkpoint | Files agents must not edit, decisions requiring approval |

Keep it concrete. Every bullet should name a file, command, or specific rule — the same specificity discipline from W1.

## 2. Register the City (~5 min)

Create local runtime config from templates:

```bash
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

Register and add your project rig:

```bash
cd my-factory
gc register .
gc rig add /path/to/your-project
gc doctor --fix
gc status
```

This creates the project rig. Later labs keep using the same rig so artifacts accumulate naturally.

## 3. Verify (~2 min)

From the project repo:

```bash
cd /path/to/your-project
git status --short
npm test
# or your project's equivalent
```

If a command fails, fix `CLAUDE.md` before moving on. Later agents will rely on these instructions.

## Exit Criteria

- [ ] `CLAUDE.md` or `AGENTS.md` exists in the project rig with project-specific rules.
- [ ] `docs/PROJECT_MANIFEST.md` has overview, tech stack, and project structure.
- [ ] `my-factory/city.toml` enables formula v2.
- [ ] `my-factory/pack.toml` selects `../packs/lessons/L2` as `factory`.
- [ ] `gc status` shows your city and project rig.

## Next

**[W2](../../workshops/W2/README.md)** comes next — you'll design the factory structure (roles, artifacts, handoff contracts) before running it. Then **[L2](../../labs/L2/README.md)** runs the first slice of that design: Planner and Architect agents on a real feature request.

You do not need to run agents before W2. The design comes first so you understand what each role does before watching it work. Your rig stays registered — L2 will use the same one.
