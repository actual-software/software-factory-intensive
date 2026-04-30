# L2 - Deploy Planner + Architect Agents

> **Goal:** Understand the role of the Planner and Architect agents in the software factory, and explore the unique configurations that best adapt these agents to your specific software project.

| | |
|---|---|
| **Estimated duration** | ~75 minutes |
| **Type** | LAB |
| **Deliverable** | Working Planner + Architect agents with at least one supported MCP server each |

## What You'll Build

```
   feature request source
              │
              ▼
   ┌────────────────────┐
   │   Planner (L2)     │    ←  MCP: Context7, a team-specific
   │                    │       research skill or other capability
   │   produces:        │
   │   docs/plans/      │
   │   <slug>.md        │
   └──────────┬─────────┘
              │
              ▼
   ┌────────────────────┐
   │  Architect (L2)    │    ←  MCP: ADR seeding a standards-library, or other capability
   │                    │
   │  produces:         │
   │  docs/architecture/│
   │  <slug>.md         │
   └────────────────────┘
```

Each stage will have access to: **the manifest** (what to honor), **the task input** (what to work on), and **a capability** (what to use to accomplish the task). Capabilities are one of the many parts that distinguish generic agents "playing the role" from true customized agents.

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

## Working directory

Unless a step says otherwise, run all commands in this lab from:

```
~/path/to/software-factory-intensive/my-factory
```

"Part 4: Inspect The Artifacts" reads files inside `~/path/to/your-project`; the snippet flags the cd. If Part 3 hits the `issue_prefix` error you'll also temporarily cd into the rig — see the troubleshooting reference there.

## Prerequisites

- You have copied `my-factory/pack.toml.template` to `my-factory/pack.toml`.
- You have copied `my-factory/city.toml.template` to `my-factory/city.toml`.
- `my-factory/city.toml` has formula v2 enabled:

```toml
[daemon]
formula_v2 = true
```

- Your project rig has already been added with `gc rig add`.
- The city's beads database is initialized (L1 step "Initialize the city's beads database").

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

If you ran `gc rig add` in L1 with the default `pack.toml`, your rig already has a `factory` import pointing at L2 — you can skip ahead. Verify with:

```bash
cd my-factory
gc --rig <rig> import list
```

If the `factory` import does not exist (or points elsewhere), set it explicitly:

```bash
gc --rig <rig> import remove factory   # only if it already exists
gc --rig <rig> import add ../packs/lessons/L2 --name factory
```

Then check the factory:

```bash
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

**Working in:** `~/path/to/software-factory-intensive/my-factory` for this part.

If `gc sling` fails with `database not initialized: issue_prefix config is missing`, the rig's beads database wasn't fully bootstrapped by `gc rig add` — see [troubleshooting/beads.md#issue-issue_prefix-config-is-missing](../../../troubleshooting/beads.md#issue-issue_prefix-config-is-missing) (scenario B). The fix runs `bd init` from the rig directory, then returns to `my-factory/`.

From `my-factory`, sling one request to the lesson Planner using the rig-qualified target (replace `<rig>` with your rig name and the feature name with your own):

```bash
gc sling <rig>/factory.planner "Plan the loyalty points feature for Fired Up Pizza" --on mol-feature-intake
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

**Switch to:** `~/path/to/your-project` for this part, then return to `my-factory` for Parts 5–7.

```bash
cd ~/path/to/your-project
ls docs/plans
ls docs/architecture
cd -    # back to my-factory
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

The planner and architect currently work from project context alone. Ground one of them in a real external system, using your `workflow-card.md` and `factory-map.md` as guides.

### Add an MCP server to the planner

Packs have a `mcp/` directory for MCP server definitions. Each server is a TOML file.

1. Create the MCP config:

For the Planner we will use Context7, which is an MCP server that provides up-to-date library documentation. Context7 requires no credentials to access public codebases and documentation.

```bash
mkdir -p packs/lessons/L2/agents/planner/mcp
$EDITOR packs/lessons/L2/agents/planner/mcp/context7.toml
```

```bash
echo '
name = "context7"
description = "Up-to-date library documentation via Context7"
command = "npx"
args = ["-y", "@upstash/context7-mcp"]
' > packs/lessons/L2/agents/planner/mcp/context7.toml
```

2. Edit the planner prompt to use the MCP:

```bash
$EDITOR packs/lessons/L2/agents/planner/prompt.template.md
```

Add to the Inputs section:

```markdown
Before writing acceptance criteria, use the Context7 MCP to look up the latest node:test API. Reference specific node:test features (describe, it, assert methods) in the acceptance criteria.
```

3. Restart and re-sling:

       gc restart
       gc sling <rig>/factory.planner "Plan <another feature>" \
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

## Part 7: Continue adding capabilities

Based on your experience with the Planner, explore other MCP servers you can add to the Architect (or more on the Planner) to customize these agents specially for your project.

Once you are done, commit the generated artifacts and your notes.

## Exit Criteria

- `gc graph <root-bead-id>` shows `plan -> architecture`.
- The formula route targets are `factory.planner` and `factory.architect`.
- The project rig contains a plan under `docs/plans/`.
- The project rig contains an architecture artifact under `docs/architecture/`.
- One prompt edit or MCP addition produced a visible artifact change.
- `activities/labs/L2/notes.md` records the root bead, artifact paths, and config changes.

## Next Steps

**[L3](../L3/README.md)** adds the Designer and Coder against the same project. The Designer reads your ADRs and produces specs; the Coder implements them.
