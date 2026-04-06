# W1 · Optimize the Individual AI Workflow

> Human-AI loop mastery -- how a single engineer works at agent speed

| | |
|---|---|
| **Day** | Day 1 |
| **Time** | 10:30 - 11:30 |
| **Type** | WORKSHOP |

## Goal

Establish a personal, repeatable prompting and iteration discipline that eliminates common friction points (ambiguous specs, runaway context, lost decisions) before scaling to multi-agent systems.

## Acceptance Criteria

- Participant maps their current workflow and identifies >= 3 friction points.
- Participant drafts an AI Workflow Card with: prompt template, context reset rule, iteration loop, and decision checkpoint.
- Peer review confirms the card is actionable without additional explanation.

## Prerequisites

- Laptop with Claude Code or preferred AI coding tool installed
- Personal or reference project (Fired Up Pizza) cloned locally
- Familiarity with basic prompting

## Inputs

- Personal project repo OR Fired Up Pizza reference project
- Personal friction inventory (from orientation)

## Outputs

- AI Workflow Card (markdown artifact)
- Annotated before/after prompt pair
- Personal iteration loop diagram

## Activity Instructions

1. Participants audit one recent AI coding session they found frustrating.
2. Using the provided Workflow Audit Template, they identify three friction sources.
3. Rebuild the failed prompt using the SPEC-CONTEXT-CONSTRAINT-CRITERIA four-part structure and re-run it against Fired Up Pizza (e.g., "Add a menu item with price validation").
4. The improvement is documented on their AI Workflow Card.
5. Final 5 min: pairs swap cards and give one sentence of feedback.

## Evaluation

| Criterion | Weight | Rubric |
|-----------|--------|--------|
| Friction identification | 20 pts | 0 = none identified · 10 = surface only · 20 = systemic root cause |
| Prompt quality (4-part) | 30 pts | 0 = missing structure · 15 = partial · 30 = all four parts, clear and specific |
| Iteration loop clarity | 25 pts | 0 = no loop · 12 = implicit · 25 = explicit steps with trigger conditions |
| Peer readability | 25 pts | 0 = peer cannot act on card · 12 = with questions · 25 = self-contained |

**Ranking:** Pods ranked by average card score. Top card displayed as pod exemplar.

**Significance:** Foundational -- all subsequent labs assume this discipline. Low scores here predict compounding problems in Labs 2+.

## Exit Criteria

AI Workflow Card committed to repo; peer sign-off captured in a one-line comment on the card file.
