# W2 · Design The Software Factory

W2 is a design workshop. You are not wiring separate runtime packs. You are deciding what roles, artifacts, and quality gates your small factory should have before the L2-L4 lesson packs run it.

## Goal

Create a factory map that explains:

- which role owns each kind of decision
- which artifact each role writes
- which formula step should route to that role
- which checks prove the step is done
- which context the next step needs

## 1. Inspect A Complete Lesson Factory

Open the L3 lesson pack:

```bash
ls packs/lessons/L3
find packs/lessons/L3 -maxdepth 3 -type f | sort
```

Notice the shape:

```text
pack.toml
agents/<role>/agent.toml
agents/<role>/prompt.template.md
formulas/mol-feature-delivery.toml
commands/status/
doctor/factory-ready/
```

That folder is the factory. It contains the roles and the graph that coordinates them.

## 1a. Inventory Your Current Capabilities

Before mapping roles, catalog what your factory can use:

| Category | What You Have | Relevant Roles |
|----------|---------------|----------------|
| AI Models | Claude via Claude Code | All agents |
| CLI Tools | npm, gh, your test runner | Builder, Release Gate |
| MCP Servers | GitHub, Sentry, etc. | Reviewer, Architect |
| Project Instructions | CLAUDE.md, AGENTS.md | All agents |
| Knowledge Sources | PROJECT_MANIFEST.md, ADRs | Planner, Architect |
| External Services | Linear, Jira, etc. | Planner (via orders) |

Inspect the workshop pack to see what integrations are available:

```bash
ls packs/workshop/orders/
ls packs/workshop/mcp/
```

Compare your inventory to a lesson pack:

```bash
find packs/lessons/L3 -maxdepth 3 -type f | sort
```

Map which tools would strengthen which roles in your factory-map.md.

MCP servers give agents tool access to external systems (GitHub, Sentry, issue trackers). Skills give agents project-specific instructions. In L2 you add an MCP server to an agent's `mcp/` directory. In L3 you add a skill to an agent's `skills/` directory.

## 2. Map Roles To Artifacts

Create the activity deliverable:

```bash
mkdir -p activities/workshops/W2
$EDITOR activities/workshops/W2/factory-map.md
```

Use this table:

| Role | Responsibility | Reads | Writes | Done When |
|---|---|---|---|---|
| Planner | turn request into scoped work | manifest, request | `docs/plans/<slug>.md` | acceptance criteria are testable |
| Architect | choose technical approach | plan, project rules | `docs/architecture/<slug>.md` | decision and tradeoffs are explicit |
| Designer | specify implementation shape | plan, architecture | `docs/designs/<slug>.md` | interfaces and edge cases are clear |
| Builder | change code and tests | plan, architecture, design | code commit | project tests pass |
| Validator | run acceptance checks | code, tests, acceptance criteria | `docs/validation/<slug>.md` | pass/fail is recorded |
| Reviewer | review against standards | diff, artifacts, project rules | `docs/reviews/<slug>.md` | findings have severity |
| Release Gate | decide readiness | validation, review, release criteria | `docs/releases/<slug>.md` | PASS or FAIL is justified |

Adjust the paths to match your project.

## 3. Map The Formula Graph

Add a second table:

| Step ID | Target | Needs | Artifact |
|---|---|---|---|
| plan | `factory.planner` | none | work package |
| architecture | `factory.architect` | plan | architecture decision |
| design | `factory.designer` | architecture | design spec |
| build | `factory.builder` | design | implementation commit |
| validate | `factory.validator` | build | validation report |
| review | `factory.reviewer` | validate | review report |
| release | `factory.release-gate` | review | release gate |

This table is the conceptual source for a formula graph. The real lesson packs encode it in TOML under `formulas/`.

## 4. Write Handoff Contracts

For each edge in the graph, write one sentence:

- what upstream must provide
- what downstream may assume
- what downstream must not guess

Example:

```text
Architect may assume Planner wrote user stories and acceptance criteria, but
must not assume the storage model until it has checked the project manifest.
```

## 5. Compare Against Lesson Packs

The lesson packs (L2, L3, L4, C1) are pre-built instances of the pattern you just designed. Open them to see how your factory map translates to real TOML:

```bash
cat packs/lessons/L3/formulas/mol-feature-delivery.toml
cat packs/lessons/C1/formulas/mol-release-delivery.toml
```

Compare your factory map to the actual graph steps. Look for:

- missing dependencies
- artifacts that should be renamed for your project
- checks that belong in a prompt, validator, or release gate
- roles that should be skipped for small changes

The lesson packs don't match your design exactly — they're generic calculator-project factories. Your design should reflect your real project's roles and artifacts. The point of comparison is structural: does your graph have the same shape of dependencies and handoffs?

## Exit Criteria

- [ ] `activities/workshops/W2/factory-map.md` exists.
- [ ] Every role has reads, writes, and done criteria.
- [ ] Every graph step has a target and artifact.
- [ ] Every handoff has an explicit contract.

## Next

L2 runs the first slice of this factory: Planner and Architect. The L2 lesson pack is a pre-built 2-agent factory, not your custom design — you'll use the lesson packs to learn the mechanics, then apply your W2 design to your own project afterward.
