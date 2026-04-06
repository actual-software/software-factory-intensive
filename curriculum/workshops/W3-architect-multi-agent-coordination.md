# W3 · Architect Multi-Agent Coordination

> Orchestration patterns -- how agents hand off without losing context

| | |
|---|---|
| **Day** | Day 2 |
| **Time** | 9:30 - 10:15 |
| **Type** | WORKSHOP |

## Goal

Learn and apply the three core coordination patterns (sequential pipeline, parallel fan-out, human-in-the-loop gate) and encode them into an orchestrator config for the Fired Up Pizza factory.

## Acceptance Criteria

- Participant can describe when to use each of the three coordination patterns.
- Orchestrator config encodes at least two patterns.
- A human-in-the-loop gate is placed at a justified stage.

## Prerequisites

- Day 1 factory fully deployed (L1-L3 artifacts committed)
- AGENTS.md with all six agent configs
- Day 1 ADRs and work packages in repo

## Inputs

- Day 1 AGENTS.md
- Orchestration patterns reference card (provided)
- Fired Up Pizza factory diagram from W2

## Outputs

- orchestrator.yaml (or equivalent config)
- Updated factory wiring diagram with coordination annotations
- Human-in-the-loop gate justification doc

## Activity Instructions

1. Instructor presents the three orchestration patterns with live examples (20 min).
2. Annotate the W2 wiring diagram: label each edge with the coordination pattern used.
3. Draft an orchestrator.yaml that: sequences Planner > Architect > Designer > Coder, fans out Reviewer and Tester in parallel after Coder, and inserts a human gate before Deploy.
4. Pairs review each other's gate justification. Gate must cite a specific risk (e.g., "prevents broken auth logic from reaching prod").

## Evaluation

| Criterion | Weight | Rubric |
|-----------|--------|--------|
| Pattern identification accuracy | 25 pts | 0 = misidentified · 12 = 2/3 correct · 25 = all 3 correct |
| Orchestrator config correctness | 35 pts | 0 = non-functional · 17 = runs but skips stages · 35 = all stages + fan-out + gate |
| Gate justification quality | 25 pts | 0 = absent · 12 = generic · 25 = specific risk with falsification condition |
| Diagram annotation completeness | 15 pts | 0 = unannotated · 7 = partial · 15 = every edge labeled |

**Ranking:** Configs run against a test harness; ranked by stages reached before first failure.

**Significance:** Critical -- this config drives the Capstone Lab. Failure here blocks C1.

## Exit Criteria

orchestrator.yaml committed; diagram annotations complete; gate justification doc present.
