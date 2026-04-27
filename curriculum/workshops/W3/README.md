# W3 · Architect Multi-Agent Coordination

In L2 you ran a 2-step formula and watched plan flow to architecture. That formula was a TOML file with two `[[steps]]` and one `needs` dependency. W3 teaches you to design your own formula graphs — deciding which steps your factory needs, what each step produces, and where human judgment belongs.

We'll use the L4 formula as a reference because it has 6 steps and shows patterns (review, release-gate) that L2's simple graph doesn't. You're not running L4 yet — just reading its structure to learn the design vocabulary.

## Goal

Produce a graph design note that explains how your factory should coordinate work.

## 1. Read a formula graph

Start with the L2 formula you already ran:

```bash
cat packs/lessons/L2/formulas/mol-feature-intake.toml
```

That's a simple graph: two steps, one dependency. Now open the L4 graph to see how a larger factory looks:

```bash
cat packs/lessons/L4/formulas/mol-delivery-review.toml
```

Look for:

- `contract = "graph.v2"`
- `[[steps]]`
- `id`
- `needs`
- `metadata."gc.run_target"`
- artifact metadata

Each step is a unit of work. `needs` defines dependency order. `gc.run_target` defines which bound agent receives that step.

## 2. Draw The Smallest Useful Graph

Create:

```bash
mkdir -p activities/workshops/W3
$EDITOR activities/workshops/W3/formula-design.md
```

Start with the smallest graph that would handle a normal feature in your project:

```text
plan -> architecture -> design -> build -> validate -> review -> release
```

Then remove any step that is not useful for your project. A formula should be as small as the work requires, not as large as the org chart.

## 3. Decide Where Judgment Lives

For each judgment, choose the right home:

| Judgment | Best Home |
|---|---|
| "What problem are we solving?" | Planner prompt |
| "Which architecture should we choose?" | Architect prompt |
| "What code shape is expected?" | Designer prompt |
| "Did implementation satisfy tests?" | Validator step |
| "Is this safe to ship?" | Release gate step |
| "Should this branch retry?" | Formula check, condition, or explicit human loop |

Dependency closure alone does not mean success. If a failed step should change the path, encode that with an explicit check, condition, retry, or manual re-run rule.

## 3a. Define Decision Boundaries

For each category, decide what stays with you and what goes to agents:

| Decision | Human or Agent? | Rationale |
|----------|----------------|-----------|
| Database schema changes | Human | Irreversible |
| New dependencies | Human | Security burden |
| API contract changes | Human | Cross-system |
| Function internals | Agent (Builder) | Contained in scope |
| Test case design | Agent (Builder) | Follows acceptance criteria |
| Review severity | Agent (Reviewer) | Follows Review Standards |
| Release verdict | Agent (Release Gate) | Follows Release Criteria |

Customize for your project and add to `formula-design.md`. This is the factory-level version of your W1 Decision Checkpoint.

## 4. Specify Step Contracts

For each step in your graph, record:

- step ID
- target
- upstream needs
- expected inputs
- expected artifact
- close condition
- failure behavior

Example:

```text
Step: review
Target: factory.reviewer
Needs: validate
Inputs: diff, design spec, validation report, project rules
Artifact: docs/reviews/<slug>.md
Close condition: findings are grouped by severity
Failure behavior: human edits factory config or code, then re-runs the formula
```

## 5. Add Optional Branches Only When They Teach Something

Use the simple linear graph unless a branch makes the factory clearer.

Good reasons to branch:

- validator and reviewer can run independently after build
- a security review applies only when touched files match sensitive paths
- release gate should stop if validation fails

Bad reasons to branch:

- showing every feature the formula engine supports
- mirroring every team name
- replacing a clear prompt with a complicated graph

## 6. Compare Against C1

Open the capstone formula:

```bash
sed -n '1,320p' packs/lessons/C1/formulas/mol-release-delivery.toml
```

Compare it with your design note. Mark:

- one step you would keep
- one step you would simplify
- one check you would add for your real project

## 7. Orders as External Triggers

Formula graphs handle step-to-step coordination inside a factory run. External events — new tickets arriving, periodic health checks — need orders.

Inspect the workshop pack's tracker sync:

```bash
cat packs/workshop/orders/sync-linear.toml
```

Notice the structure:

- `gate = "cooldown"` — fires after an interval elapses
- `interval = "5m"` — every 5 minutes
- `exec = "bd linear sync || true"` — the command to run

Orders are for real external triggers, not for passing work between formula steps. In your `formula-design.md`, identify one external trigger your factory would need and describe it as an order.

## Coordination Beyond Graphs

For observing and debugging agent work:

| Tool | Purpose |
|------|---------|
| `gc session peek <id>` | See what an agent is doing now |
| `gc events --follow` | Stream factory events |
| `gc graph <bead-id>` | Inspect formula step states |

These are observability tools, not workflow dispatch.

## Exit Criteria

- [ ] `activities/workshops/W3/formula-design.md` exists.
- [ ] It lists step IDs, targets, dependencies, artifacts, and close behavior.
- [ ] It explains where success/failure judgment lives.
- [ ] It avoids using metadata labels as the primary routing mechanism.
- [ ] Decision boundaries are documented in `formula-design.md`.
- [ ] One external trigger is described as an order spec.

## Next

L4 uses a graph with review and release-gate steps. The review loop remains student-driven: read the review, update code or factory config, and re-run the formula when needed.
