# L3: Deploy Designer + Coder Agents

> **Goal:** Extend your software factory with the next two specialists, and demonstrate that it can now carry a planned feature from concept through to a committed implementation.

| | |
|---|---|
| **Estimated duration** | ~75 minutes |
| **Type** | LAB |
| **Deliverable** | Working Designer + Coder agents, with at least one supported Skill or CLI tool each |

## Architecture

```
    docs/plans/<slug>.md   docs/architecture/<slug>.md
           (from L2)                (from L2)
                │                      │
                └──────────┬───────────┘
                           ▼
                ┌──────────────────────┐
                │   Designer (L3)      │  ←  Skill or CLI tool: e.g. Figma,
                │                      │     design-system repo,
                │   produces:          │     a screenshot tool
                │   docs/designs/      │
                │   <slug>.md          │
                └──────────┬───────────┘
                           │  handoff (file)
                           ▼
                ┌──────────────────────┐
                │   Coder (L3)         │  ←  Skill or CLI tool: e.g. GitHub,
                │                      │     Postgres (staging),
                │   produces:          │     or test runner tool
                │   src/** + tests     │
                └──────────────────────┘
```

## Mental Model

You keep the same project rig across labs. The rig owns the project files,
beads, sessions, and artifacts. The city root chooses which factory pack is
active for that rig.

L3 uses:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/L3"
```

The imported agents are rig-scoped, so their targets are:

```text
<rig>/factory.planner
<rig>/factory.architect
<rig>/factory.designer
<rig>/factory.builder
```

The formula is `mol-feature-delivery`:

```text
plan -> architecture -> design -> build
```

## How four agents run from one sling

The formula graph controls the order. Each `[[steps]]` entry in `mol-feature-delivery.toml` has a `needs` field that says which steps must close before this step becomes ready, and a `gc.run_target` that says which agent runs it:

| Step | Needs | Agent | Writes |
|------|-------|-------|--------|
| plan | (none) | `factory.planner` | `docs/plans/<slug>.md` |
| architecture | plan | `factory.architect` | `docs/architecture/<slug>.md` |
| design | architecture | `factory.designer` | `docs/designs/<slug>.md` |
| build | design | `factory.builder` | code + tests on feature branch |

When you `gc sling` to the planner, Gas City compiles the formula, creates a bead for each step, and sets routing metadata on every bead up front. The `plan` step has no `needs`, so it's immediately ready — the planner's worker pool picks it up.

When the planner closes its step, the store checks which other steps depended on it. The `architecture` step had `needs = ["plan"]`, so it becomes ready. The architect's worker pool was already assigned to that bead (the routing was set at sling time), so it picks it up. Same for designer after architect, builder after designer.

The agents don't know about each other. Each one works its assigned bead, reads whatever project files exist (including artifacts upstream agents wrote), and closes the bead when done. The store evaluates dependencies and surfaces the next ready step.

## Working directory

Unless a step says otherwise, run all commands in this lab from:

```
~/path/to/software-factory-intensive/my-factory
```

"Step 6: Inspect Outputs" is the only step that cds into the rig; the snippet flags it explicitly.

## 1. Enable formula v2

This is a one-time city setting. Confirm `my-factory/city.toml` contains:

```toml
[daemon]
formula_v2 = true
```

## 2. Select the L3 Factory Pack

Edit `my-factory/pack.toml` so the active factory import points at L3:

```toml
[pack]
name = "my-factory"
schema = 2

[defaults.rig.imports.factory]
source = "../packs/lessons/L3"
```

## 3. Sync the Existing Rig

Root default imports are applied when a rig is created. Because you are keeping
the same rig from L2, sync it explicitly. From `my-factory/`:

```bash
gc --rig <rig> import remove factory
gc --rig <rig> import add ../packs/lessons/L3 --name factory
gc restart
gc doctor
```

Use your real rig name from:

```bash
gc rig list
```

## 4. Start the Formula

Use the rig-qualified target (replace `<rig>` with your rig name and the feature description with your own):

```bash
gc sling <rig>/factory.planner \
  "<a small feature for your project>" \
  --on mol-feature-delivery
```

For example, on the Fired Up Pizza reference project: `"Add a loyalty-points line to the cart total"`. Capture the workflow bead id printed by `Attached workflow ...`.

## 5. Watch Progress

Use these commands while the graph runs:

```bash
gc events --follow
gc session list
gc session peek <session-id>
gc graph <workflow-bead-id>
bd list
```

You should see the formula advance through:

```text
factory.planner -> factory.architect -> factory.designer -> factory.builder
```

Use all six observability commands from L2. Watch the four-agent handoff.

## 6. Inspect Outputs

**Switch to:** `~/path/to/your-project` for this step, then return to `my-factory` for steps 7–8.

```bash
cd ~/path/to/your-project
ls docs/plans
ls docs/architecture
ls docs/designs
git log --oneline -5
npm test       # or `node --test`
cd -           # back to my-factory
```

Expected outputs:

- a work package in `docs/plans/`
- an architecture decision in `docs/architecture/`
- an implementation design in `docs/designs/`
- a new implementation commit
- passing tests

## 7. Add a Skill to the Builder

L2 taught MCP integration (external tool access). L3 teaches skill integration — project-specific instructions that shape how an agent works.

Packs have a `skills/` directory. Each skill is a subdirectory with a `SKILL.md` file.

1. Create a testing-conventions skill for the builder:

```bash
mkdir -p packs/lessons/L3/agents/builder/skills/testing-conventions
$EDITOR packs/lessons/L3/agents/builder/skills/testing-conventions/SKILL.md
```

Contents:

```markdown
---
name: testing-conventions
description: Project-specific testing conventions for this project.
---

These rules are mandatory for all test files in this project:

- Import `assert` from `node:assert/strict` and use `assert.strictEqual` for every comparison. Never use `assert.equal` or `assert.ok` for value checks.
- Structure every test file with `describe()` blocks. Each exported function gets its own `describe('functionName', () => { ... })` block. Do NOT use bare `test()` calls at the top level.
- Inside each `describe()` block, use `it()` for individual test cases, not `test()`.
- Include at least one edge case per function: zero input, negative input, and boundary values.
- Each `it()` description must state the expected behavior, not the implementation detail.
```

2. Edit the builder prompt to reference the skill:

```bash
$EDITOR packs/lessons/L3/agents/builder/prompt.template.md
```

Add to the Inputs section:

```markdown
Before writing tests, read the testing-conventions skill and follow its rules for assert methods, describe blocks, and edge cases.
```

3. Restart and re-sling with a different feature:

```bash
gc restart
gc sling <rig>/factory.planner "<a different small feature>" \
  --on mol-feature-delivery
```

4. Compare the builder's test code from the two commits. The second commit should use `assert.strictEqual` (not `assert.equal`), `describe()` blocks, and explicit edge case tests — because the skill told it to.

In L2 you added an MCP (external data). Here you added a skill (internal rules). Different mechanisms, same idea — tell the agent what you want in a file it reads every time, not in a chat message it forgets.

## 8. Continue adding additional skills (including CLI tools)

For the rest of the lab, continue adding new skills to the other agents. For example, you can try adding the [Actual CLI](https://cli.actual.ai/) tool along with the [Actual CLI Skill](https://github.com/actualai/actual-cli-skill) to the architecture agent.

## Exit Criteria

- The run started with one `gc sling <rig>/factory.planner ... --on mol-feature-delivery`.
- No stage labels or manual downstream beads were used.
- The graph routed all four roles.
- The builder committed the implementation and tests.
- Testing-conventions skill added to builder with visible impact on test code (assert.strictEqual, describe blocks).

## Next Steps

**[W3](../../workshops/W3/README.md)** introduces multi-agent coordination. You will create a formula graph design note in `formula-design.md` that explains how your factory should coordinate work.
