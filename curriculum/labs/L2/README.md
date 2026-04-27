# L2 - Deploy Planner + Architect Agents

> **What you will build:** a two-agent lesson factory. One `gc sling` creates
> a formula graph with two steps. The planner step runs first; when it
> closes, the architect step becomes ready and runs.

| | |
|---|---|
| **Estimated duration** | 60-75 minutes |
| **Type** | LAB |
| **Deliverable** | One plan, one architecture decision, and notes linking them to the formula run |

## Mental Model

L2 uses one self-contained pack:

```text
packs/lessons/L2/
  agents/planner/
  agents/architect/
  formulas/mol-feature-intake.toml
```

The formula is the workflow:

```text
plan -> architecture
```

The city selects the active lesson pack. The project rig keeps the work and
artifacts. That means you keep the same rig across lessons and only change
which lesson factory pack is active.

## Prerequisites

- You have copied `my-factory/pack.toml.template` to `my-factory/pack.toml`.
- You have copied `my-factory/city.toml.template` to `my-factory/city.toml`.
- `my-factory/city.toml` has formula v2 enabled:

```toml
[daemon]
formula_v2 = true
```

- Your project rig has already been added with `gc rig add`.

## Part 1: Select L2 As The Active Lesson

Open `my-factory/pack.toml` and set the city-wide active factory import:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/L2"
```

This import is city-wide lesson selection. The agents inside the factory pack
are still rig-scoped, so the Planner target is:

```text
<rig>/factory.planner
```

Because your rig already exists, sync that rig to the L2 pack:

```bash
cd my-factory
gc --rig <rig> import add ../packs/lessons/L2 --name factory
```

If the `factory` import already exists from another lesson, replace it:

```bash
gc --rig <rig> import remove factory
gc --rig <rig> import add ../packs/lessons/L2 --name factory
```

Restart and check the factory:

```bash
gc restart
gc doctor
```

## Part 2: Read The Lesson Pack

Open these files before running the lesson:

- `packs/lessons/L2/pack.toml`
- `packs/lessons/L2/formulas/mol-feature-intake.toml`
- `packs/lessons/L2/agents/planner/prompt.template.md`
- `packs/lessons/L2/agents/architect/prompt.template.md`

Confirm three things:

- The formula uses `version = 2` and `contract = "graph.v2"`.
- `plan` routes to `factory.planner`.
- `architecture` depends on `plan` and routes to `factory.architect`.

Compare the planner prompt to your W1 workflow card:

| Your Workflow Card | Planner Prompt Section |
|-------------------|----------------------|
| Prompt Template | `## Inputs` — what context the agent reads |
| Context Reset Rule | `wake_mode = "fresh"` in agent.toml |
| Iteration Loop | `## Graph Work Process` — the work loop |
| Decision Checkpoint | `## Role` — scope of authority, what to escalate |

Your workflow card described how you work with one agent. The planner prompt does the same thing for the planner inside a factory. The four sections map to each other — that's not a coincidence.

## Part 3: Run The Formula

From `my-factory`, sling one request to the lesson Planner:

```bash
gc sling planner "Plan the loyalty points feature for Fired Up Pizza" --on mol-feature-intake
```

Watch progress:

```bash
gc events --follow
```

When you have the root bead ID, inspect the graph:

```bash
gc graph <root-bead-id>
bd show <root-bead-id>
```

Expected graph:

| Step | Agent | Output |
|---|---|---|
| `plan` | `factory.planner` | `docs/plans/<slug>.md` |
| `architecture` | `factory.architect` | `docs/architecture/<slug>.md` |

## Observability Commands

These are your windows into a running factory. Practice all six while L2 runs:

| Command | What It Shows |
|---------|---------------|
| `gc events --follow` | Live event stream (agent wakes, step transitions) |
| `gc session list` | Active and recent agent sessions |
| `gc session peek <id>` | Live view of what an agent is doing now |
| `gc graph <bead-id>` | Formula step state graph |
| `bd list` | All beads in the current rig |
| `bd show <id>` | Detailed bead state and metadata |

You will use these throughout L3, L4, and C1.

## Part 4: Inspect The Artifacts

In your project rig, inspect:

```bash
ls docs/plans
ls docs/architecture
```

The plan should include:

- Goal
- User Stories
- Acceptance Criteria
- Scope Boundary
- Dependencies
- Open Questions
- Architect Handoff

The architecture artifact should include:

- Context
- Options Considered
- Decision
- Consequences
- Risks
- References

## Part 5: Attach a Real Capability

The planner and architect currently work from project context alone. Ground one of them in a real external system.

### Add an MCP server to the planner

Packs have a `mcp/` directory for MCP server definitions. Each server is a TOML file.

1. Create the MCP config:

       mkdir -p packs/lessons/L2/agents/planner/mcp
       $EDITOR packs/lessons/L2/agents/planner/mcp/context7.toml

   Contents:

   ```toml
   name = "context7"
   description = "Up-to-date library documentation via Context7"
   command = "npx"
   args = ["-y", "@upstash/context7-mcp"]
   ```

   Context7 requires no credentials. For MCP servers that need auth (GitHub, Sentry, Linear), add an `[env]` section to the TOML — see `packs/workshop/orders/sync-linear.toml` for an example of env var usage.

2. Edit the planner prompt to use the MCP:

       $EDITOR packs/lessons/L2/agents/planner/prompt.template.md

   Add to the Inputs section: "Before writing acceptance criteria, use the Context7 MCP to look up the latest node:test API. Reference specific node:test features (describe, it, assert methods) in the acceptance criteria."

3. Restart and re-sling:

       gc restart
       gc sling planner "Plan <another feature>" \
         --on mol-feature-intake

4. Compare the two plan artifacts. The second plan should reference specific node:test API details (assert.strictEqual, describe blocks) that came from Context7 — not generic knowledge.

Without the MCP, the planner guesses what the node:test API looks like. With it, the planner checks.

## Part 6: Record Notes

Create `activities/labs/L2/notes.md`:

```markdown
# L2 Notes

Root bead:

Plan artifact:

Architecture artifact:

Prompt or config changes:

What I would change before L3:
```

Commit the generated artifacts and your notes.

## Exit Criteria

- `gc graph <root-bead-id>` shows `plan -> architecture`.
- The formula route targets are `factory.planner` and `factory.architect`.
- The project rig contains a plan under `docs/plans/`.
- The project rig contains an architecture artifact under `docs/architecture/`.
- One prompt edit or MCP addition produced a visible artifact change.
- `activities/labs/L2/notes.md` records the root bead, artifact paths, and config changes.
