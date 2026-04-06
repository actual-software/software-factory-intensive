# L4 · Deploy Reviewer + DevOps Agents

> Quality and delivery -- the factory's back two stages close the loop

| | |
|---|---|
| **Day** | Day 2 |
| **Time** | 10:30 - 11:45 |
| **Type** | LAB |

## Goal

Instantiate the Reviewer and DevOps agents, producing an automated code review report and a release gate evaluation for the Loyalty Points feature.

## Acceptance Criteria

- Reviewer agent produces a structured review report: style, security, and spec-compliance findings.
- DevOps agent produces a release gate checklist with PASS/FAIL per criterion.
- At least one Reviewer finding is resolved by updating Coder config and re-running (not by manual code edit).

## Prerequisites

- L3 LoyaltyPoints implementation committed
- W3 orchestrator.yaml in repo
- Reviewer + DevOps config scaffolds (provided)

## Inputs

- LoyaltyPoints implementation from L3
- Work package test cases
- Review policy stub (provided)
- Release gate criteria (provided)

## Outputs

- `review-reports/loyalty-points-review.md`
- `release-gates/loyalty-points-gate.md`
- Updated Coder config with review-driven fix

## Activity Instructions

1. Configure Reviewer agent; inputs: LoyaltyPoints code + work package AC + review policy.
2. Run review. Inspect report; identify the highest-severity finding.
3. Update Coder config to address the finding; re-run Coder; re-run Reviewer to verify fix.
4. Configure DevOps agent; inputs: repo state + release gate criteria.
5. Run release gate evaluation. Gate must produce a binary PASS/FAIL per criterion with evidence.
6. Commit all outputs.

## Evaluation

| Criterion | Weight | Rubric |
|-----------|--------|--------|
| Review report completeness | 25 pts | 0 = absent · 12 = style only · 25 = style + security + spec-compliance |
| Finding resolution via config | 30 pts | 0 = manual fix · 15 = config updated but issue persists · 30 = config fix verified by re-run |
| Release gate binary evidence | 25 pts | 0 = opinions only · 12 = evidence for some · 25 = evidence for every criterion |
| Pipeline integrity | 20 pts | 0 = agents run independently · 10 = loosely connected · 20 = orchestrator.yaml drives both agents |

**Ranking:** Ranked by number of gate criteria with passing evidence.

**Significance:** High -- Reviewer + DevOps are the quality backstop before the Capstone.

## Exit Criteria

Review report + gate checklist committed; at least one finding resolved via config; orchestrator drives both agents.
