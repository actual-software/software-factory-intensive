# Fired Up Pizza

Reference project for the Software Factory Intensive workshop. A pizza restaurant web app built entirely by a 6-agent Gas City software factory.

## Quick Start

### 1. Set up Gas City

```bash
# Install Gas City (macOS)
brew install gastownhall/gascity/gascity

# Initialize a city
gc init ~/pizza-factory
```

### 2. Add agents incrementally (or all at once)

```bash
cd ~/pizza-factory

# Option A: Add agents one at a time (matches the lab progression)
gc rig add /path/to/fired-up-pizza --include /path/to/packs/planner
gc rig add /path/to/fired-up-pizza --include /path/to/packs/architect
# ... add designer, coder, reviewer, deployer as needed

# Option B: Add all 6 agents at once
gc rig add /path/to/fired-up-pizza --include /path/to/packs/fired-up-pizza
```

### 3. Import the ticket backlog

```bash
cd /path/to/fired-up-pizza
bash /path/to/packs/fired-up-pizza/scripts/import-tickets.sh tickets.md
bd list
```

### 4. Run the factory

```bash
# Sling the first ticket to the planner
gc sling fired-up-pizza/planner <bead-id>

# Watch the pipeline
gc events --follow
gc session list
gc session peek <agent>      # Watch an agent work
```

## Project Structure

```
fired-up-pizza/
  src/                        # Application code (Coder output)
  docs/
    PROJECT_OVERVIEW.md       # Loose brief written by the founder before the curriculum
    PROJECT_MANIFEST.md       # Structured skeleton generated from the overview
    factory-wiring.md         # W2 deliverable — per-agent table + integration points
    gates/                    # W3 human-gate justification docs (e.g. approve_deploy.md)
    adr/                      # Architecture Decision Records (Architect output)
  workflow-card.md            # W1 deliverable — single-agent workflow discipline
  orchestrator.yaml           # W3 deliverable — 6-stage pipeline with gates + on_reject
  DECISIONS.md                # L1 log of CLAUDE.md rule evolutions
  work-packages/              # Planner output (L2)
  design/                     # Designer output (L3)
  review-reports/             # Reviewer output (L4)
  release-gates/              # Deployer output (L4)
  feedback-loops/             # W4 deliverables — reactive, aggregate, external rules
  factory-run-report.md       # C1 deliverable — end-to-end run record
  retrospective-card.md       # C1 deliverable — keep / change / question
  tickets.md                  # Initial feature backlog
  CLAUDE.md                   # Agent instructions
  package.json                # Node.js project
```

## Reference Deliverables by Session

Each curriculum session has at least one concrete artifact participants produce. This project ships a completed example of each so participants can see the target shape before they start:

| Session | Deliverable | File in this project |
|---------|-------------|----------------------|
| W1 | Workflow card | [`workflow-card.md`](./workflow-card.md) |
| W2 | Factory wiring | [`docs/factory-wiring.md`](./docs/factory-wiring.md) |
| W3 | Orchestrator + gate justification | [`orchestrator.yaml`](./orchestrator.yaml), [`docs/gates/approve_deploy.md`](./docs/gates/approve_deploy.md) |
| W4 | Feedback loops (reactive / aggregate / external) | [`feedback-loops/`](./feedback-loops/) |
| L1 | Agent instructions + decision log | [`CLAUDE.md`](./CLAUDE.md), [`DECISIONS.md`](./DECISIONS.md) |
| L2 | Work package + ADR | [`work-packages/loyalty-points-system.md`](./work-packages/loyalty-points-system.md), [`docs/adr/0001-loyalty-points-storage.md`](./docs/adr/0001-loyalty-points-storage.md) |
| L3 | Design spec | [`design/loyalty-points-spec.md`](./design/loyalty-points-spec.md) |
| L4 | Review report + release gate | [`review-reports/loyalty-points-review.md`](./review-reports/loyalty-points-review.md), [`release-gates/loyalty-points-gate.md`](./release-gates/loyalty-points-gate.md) |
| C1 | Factory run report + retrospective | [`factory-run-report.md`](./factory-run-report.md), [`retrospective-card.md`](./retrospective-card.md) |

## The 6-Agent Pipeline

| Stage | Agent | Input | Output |
|-------|-------|-------|--------|
| 1. Plan | Planner | Feature request | `work-packages/<slug>.md` |
| 2. Architect | Architect | Work package | `docs/adr/NNNN-<slug>.md` |
| 3. Design | Designer | Work package + ADR | `design/<slug>-spec.md` |
| 4. Code | Coder | Component spec | `src/` implementation |
| 5. Review | Reviewer | Code diff + spec | `review-reports/<slug>-review.md` |
| 6. Deploy | Deployer | Review report | `release-gates/<slug>-gate.md` |

## Adapting for Your Project

This reference is designed to be forked and modified:

1. Replace `docs/PROJECT_MANIFEST.md` with your project's tech stack and domain model
2. Replace `tickets.md` with your feature backlog
3. Adjust agent prompts in `packs/fired-up-pizza/prompts/` for your conventions
4. Update `docs/REVIEW_POLICY.md` and `docs/RELEASE_CRITERIA.md` for your standards
5. Re-run the factory against your codebase

The agent prompts, manifests, and policies are the config layer. Change behavior by editing these files — not by re-prompting agents.

## Workshop Curriculum

This project is used across the Software Factory Intensive:

- **W1/L1**: Individual workflow optimization against this codebase
- **W2/L2**: Deploy Planner + Architect agents (produces work packages + ADRs)
- **L3**: Deploy Designer + Coder agents (produces specs + implementation)
- **W3/L4**: Orchestration and Reviewer + Deployer agents
- **C1**: Full factory run for a new feature (Order History page)
