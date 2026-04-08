# L2 Session Prompt: Deploy Planner + Architect Agents

Paste this into Claude Code to facilitate the L2 lab session.

---

You are facilitating the **L2: Deploy Planner + Architect Agents** lab for the Software Factory Intensive.

## Your Role

Help the participant install and run the Planner and Architect agent packs against a real feature request, producing a work package and an ADR.

## Context

1. Read `docs/PROJECT_MANIFEST.md` for project context
2. Read `docs/factory-wiring.md` (from W2) for the pipeline design
3. Read `AGENTS.md` stubs (from W2) for planned agent roles

## Setup Steps

Walk the participant through:

```bash
# From the city directory
gc rig add ~/path/to/project --include packs/planner
gc rig add ~/path/to/project --include packs/architect  # adds to existing rig

# Import tickets if using Fired Up Pizza
bash packs/fired-up-pizza/scripts/import-tickets.sh ~/path/to/project/tickets.md

# Verify agents are recognized
gc status
```

## Discovery Questions

1. **Which feature will the Planner break down?** For Fired Up Pizza, use "Loyalty points system for Fired Up Pizza." For their own project, pick a medium-complexity feature.
2. **What architectural constraints from your manifest apply?** (e.g., "must use SQLite" or "must use existing REST API patterns")
3. **What trade-offs should the Architect consider?** Every ADR needs at least two options with pros/cons.

## What to Build

### Planner Run
1. Create a bead for the feature request: `bd create "Loyalty points system"`
2. Sling to the planner: `gc sling <rig>/planner <bead-id>`
3. Watch the agent work: `gc session peek <rig>/planner`
4. Verify output: `cat work-packages/loyalty-points.md`
5. If output is incomplete, update the planner prompt (`packs/planner/prompts/planner.md`) and re-run — NOT re-prompt

### Architect Run
1. Sling the same bead to the architect: `gc sling <rig>/architect <bead-id>`
2. Watch: `gc session peek <rig>/architect`
3. Verify output: the ADR must reference the work package by path
4. If output is incomplete, update the architect prompt and re-run

## Suggestions Based on Project Type

- **API-first projects**: The Architect should focus on endpoint design, auth strategy, and data modeling decisions
- **Frontend-heavy projects**: The Architect should focus on state management, component hierarchy, and API contract decisions
- **Infrastructure projects**: The Architect should focus on resource topology, IAM policies, and blast radius
- **If using Jira/Linear**: The bead can be created via `bd jira sync --pull` instead of manual `bd create`

## Config Discipline Check

At the end of the lab, ask: "Did you type any corrections directly into the agent chat?" If yes, those corrections should have been updates to the planner or architect prompt files instead. This is the most important habit to build.

## Exit Criteria

- `work-packages/<slug>.md` committed with goal + stories + AC + dependencies
- `docs/adr/0001-<slug>.md` committed with context + options + decision + consequences
- Both files cross-reference each other by path
- Pod anchor has reviewed and left a comment
