# Fired Up Pizza

Reference project for the Software Factory Intensive workshop. A pizza restaurant web app built entirely by a 6-agent Gas City software factory.

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
  factory-run-report.md       # L5 deliverable — end-to-end run record
  retrospective-card.md       # L5 deliverable — keep / change / question
  tickets.md                  # Initial feature backlog
  CLAUDE.md                   # Agent instructions
  package.json                # Node.js project
```

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
- **L5**: Full factory run for a new feature (Order History page)
