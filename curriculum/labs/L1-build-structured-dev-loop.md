# L1 · Build a Structured Development Loop

> Repeatability over brilliance -- encode the loop, not just the prompt

| | |
|---|---|
| **Day** | Day 1 |
| **Time** | 11:30 - 12:30 |
| **Type** | LAB |

## Goal

Translate the personal workflow card into a working, repo-committed development loop: a CLAUDE.md / AGENTS.md spec that drives consistent agent behavior across a feature.

## Acceptance Criteria

- CLAUDE.md or AGENTS.md created with: role definition, iteration rule, quality gate, and decision log pointer.
- Agent successfully generates a passing feature implementation for one Fired Up Pizza story using only the spec.
- No manual prompt corrections required after spec is loaded.

## Prerequisites

- W1 AI Workflow Card complete
- Fired Up Pizza repo cloned
- Claude Code CLI authenticated

## Inputs

- AI Workflow Card from W1
- Fired Up Pizza user story backlog (provided)
- Starter CLAUDE.md template (scaffold, provided)

## Outputs

- CLAUDE.md / AGENTS.md committed to repo
- Feature branch with one completed story
- Decision log entry

## Activity Instructions

1. Using the scaffold CLAUDE.md, encode W1 workflow card rules into the spec file.
2. Pick ONE story from the Fired Up Pizza backlog (e.g., "Show order total in cart") and instruct the agent to implement it using ONLY the spec -- no ad-hoc prompting allowed.
3. If the agent deviates or fails, update the spec (not the prompt) and re-run.
4. Goal: three runs maximum to a passing implementation.
5. The decision log records what changed between runs and why.

## Evaluation

| Criterion | Weight | Rubric |
|-----------|--------|--------|
| Spec completeness | 25 pts | 0 = missing required sections · 12 = partial · 25 = all four sections present |
| Runs-to-passing | 30 pts | 30 = 1 run · 20 = 2 runs · 10 = 3 runs · 0 = >3 or manual intervention |
| Decision log quality | 25 pts | 0 = absent · 12 = what changed · 25 = what + why + what was learned |
| Code quality gate pass | 20 pts | Binary: 20 = passes lint/test · 0 = fails |

**Ranking:** Pods ranked by (30 - runs-to-passing x 10) + spec score. Ties broken by decision log quality.

**Significance:** High -- this loop is the substrate for all agent factory stages.

## Exit Criteria

CLAUDE.md committed; feature branch passes automated quality gate; decision log has >= 1 entry.
