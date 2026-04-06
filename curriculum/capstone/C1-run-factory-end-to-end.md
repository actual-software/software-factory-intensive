# C1 · Run the Software Factory End-to-End

> Full factory run -- from idea to deployed feature without ad-hoc human intervention

| | |
|---|---|
| **Day** | Day 2 |
| **Time** | 1:30 - 3:00 |
| **Type** | CAPSTONE |

## Goal

Execute a complete factory run for a new feature request, driven entirely by orchestrator.yaml and AGENTS.md configs built across Days 1-2, producing a deployed (or deployment-ready) artifact.

## Acceptance Criteria

- All eight factory stages execute without ad-hoc prompting.
- A new feature (not Loyalty Points) is planned, designed, coded, reviewed, and gate-checked.
- Factory Run Report captures: stages reached, artifacts produced, quality gate outcome, and one feedback rule triggered.

## Prerequisites

- All Day 1 + Day 2 labs complete
- orchestrator.yaml, AGENTS.md, CLAUDE.md finalized
- Full Fired Up Pizza factory pipeline green

## Inputs

- All prior artifacts (AGENTS.md, orchestrator.yaml, CLAUDE.md, ADRs)
- New feature request: "Order history page for Fired Up Pizza" (issued at session start)
- Factory Run Report template (provided)

## Outputs

- Full feature branch: plan + ADR + component spec + code + review + gate
- Factory Run Report
- Retrospective card (one keep, one change, one question)

## Activity Instructions

1. Facilitator issues the new feature request at session start -- no preview given beforehand.
2. Participants run the orchestrator end-to-end: no stage may be manually re-prompted.
3. If a stage fails, the fix must be a config update committed before re-running.
4. Participants complete the Factory Run Report in parallel with the run (live updates).
5. At 2:45, all participants commit their Factory Run Report regardless of factory state.
6. Pod anchors score completeness using the rubric below.

## Evaluation

| Criterion | Weight | Rubric |
|-----------|--------|--------|
| Stages reached | 30 pts | 0 = <= 2 stages · 10 = 3-5 stages · 20 = 6-7 stages · 30 = all 8 |
| No ad-hoc prompting | 25 pts | 0 = > 2 manual prompts · 12 = 1-2 manual prompts · 25 = zero |
| Factory Run Report quality | 25 pts | 0 = absent/incomplete · 12 = stages + artifacts · 25 = stages + artifacts + gate + feedback rule |
| Retrospective insight depth | 20 pts | 0 = generic · 10 = project-specific · 20 = actionable change with rationale |

**Ranking:** Pods ranked by (stages reached) x (no-ad-hoc-prompting multiplier). Winner presents their factory run to the full cohort.

**Significance:** Summative -- demonstrates end-to-end factory competency. This is the primary assessment for the workshop.

## Exit Criteria

Factory Run Report committed; feature branch present (any stage); retrospective card submitted to pod anchor.
