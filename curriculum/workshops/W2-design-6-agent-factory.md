# W2 · Design the 6-Agent Software Factory

> Architecture before automation -- spec the factory, not just the feature

| | |
|---|---|
| **Day** | Day 1 |
| **Time** | 1:30 - 2:15 |
| **Type** | WORKSHOP |

## Goal

Understand the architecture of all eight factory stages and produce a wiring diagram mapping agent roles to the participant's project.

## Acceptance Criteria

- Participant can articulate the responsibility boundary of each agent.
- Factory wiring diagram maps all eight stages to either the participant project or Fired Up Pizza.
- At least one handoff contract (output-of-stage-N = input-of-stage-N+1) documented per stage pair.

## Prerequisites

- L1 CLAUDE.md / AGENTS.md in place
- Understanding of SDLC stages

## Inputs

- Fired Up Pizza project manifest (provided)
- Factory Architecture slide deck (provided)
- CLAUDE.md from L1

## Outputs

- Factory wiring diagram (Mermaid or draw.io, committed to repo)
- Handoff contract table
- Agent role definition stubs in AGENTS.md

## Activity Instructions

1. Instructor presents the 6-agent architecture (15 min).
2. Open the provided Mermaid template and annotate each stage node with: (a) the agent responsible, (b) the artifact it consumes, (c) the artifact it produces, (d) the quality gate it must pass.
3. For Fired Up Pizza: map the "Add menu item" feature end-to-end through all eight stages.
4. Pairs share diagrams; group votes on the clearest handoff contract.

## Evaluation

| Criterion | Weight | Rubric |
|-----------|--------|--------|
| Stage coverage | 25 pts | 0 = < 4 stages · 12 = 4-6 stages · 25 = all 8 stages |
| Handoff contracts | 35 pts | 0 = absent · 17 = present but vague · 35 = typed artifacts named precisely |
| Agent boundary clarity | 25 pts | 0 = overlapping · 12 = mostly distinct · 25 = no overlap, escalation path defined |
| Diagram readability | 15 pts | 0 = illegible · 7 = readable with effort · 15 = self-explanatory |

**Ranking:** Pod diagrams ranked by peer vote (most useful for onboarding a new team member).

**Significance:** Architectural -- errors here propagate into all Day 1 labs and Day 2 deployment.

## Exit Criteria

Wiring diagram committed; handoff contract table has an entry for every stage boundary; AGENTS.md stubs created.
