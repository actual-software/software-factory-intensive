# W4 · Create Continuous Improvement Loops

> The factory learns -- runtime data feeds back into the spec

| | |
|---|---|
| **Day** | Day 2 |
| **Time** | 11:45 - 12:30 |
| **Type** | WORKSHOP |

## Goal

Design a feedback loop that routes runtime signals (test failures, review findings, deployment errors) back into the factory spec, enabling the factory to self-improve without human re-prompting.

## Acceptance Criteria

- Feedback loop diagram maps >= 3 runtime signal types to specific spec update targets.
- At least one automated feedback rule encoded in AGENTS.md.
- Participant can articulate the difference between a feedback rule and a manual correction.

## Prerequisites

- All Day 1 labs complete
- L4 review report and gate checklist committed
- W3 orchestrator.yaml committed

## Inputs

- L4 review report
- L4 gate checklist
- AGENTS.md (current)
- Feedback loop template (provided)

## Outputs

- feedback-loops/factory-feedback.md
- Updated AGENTS.md with >= 1 feedback rule
- Feedback loop diagram (Mermaid)

## Activity Instructions

1. Using the L4 review report and gate checklist, identify three signal types (e.g., test failure rate, average review severity, deploy rollback count).
2. For each signal, document: trigger threshold > spec target > update action.
3. Encode the highest-value rule as a concrete AGENTS.md entry.
4. Group discussion: where would a feedback rule cause harm? (10 min) Document two harm cases with mitigations.
5. Commit all artifacts.

## Evaluation

| Criterion | Weight | Rubric |
|-----------|--------|--------|
| Signal coverage breadth | 20 pts | 0 = 1 signal · 10 = 2 signals · 20 = 3+ signals across different stages |
| Rule precision | 35 pts | 0 = vague ("if bad, fix") · 17 = threshold present · 35 = threshold + target + action all specific |
| Harm identification | 25 pts | 0 = absent · 12 = one harm case · 25 = two+ with mitigations |
| AGENTS.md encoding quality | 20 pts | 0 = not encoded · 10 = encoded but unparseable · 20 = valid, parseable AGENTS.md rule |

**Ranking:** Ranked by rule precision score.

**Significance:** Strategic -- determines factory longevity and self-improvement capacity post-workshop.

## Exit Criteria

feedback-loops/factory-feedback.md committed; at least one rule in AGENTS.md; diagram present.
