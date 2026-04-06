# L2 · Deploy Planner + Architect Agents

> From diagram to running agent -- the factory's front two stages go live

| | |
|---|---|
| **Day** | Day 1 |
| **Time** | 2:15 - 3:30 |
| **Type** | LAB |

## Goal

Instantiate and run the Planner and Architect agents against a real feature request, producing a work package and an ADR stub.

## Acceptance Criteria

- Planner agent produces a structured work package (goal, stories, acceptance criteria, dependencies).
- Architect agent produces an ADR stub covering: context, options, decision, consequences.
- Both artifacts are in the repo and reference each other by ID.

## Prerequisites

- W2 wiring diagram and AGENTS.md stubs complete
- Claude Code CLI authenticated
- Fired Up Pizza repo cloned

## Inputs

- W2 wiring diagram
- AGENTS.md with Planner + Architect stubs
- Feature request: "Loyalty points system for Fired Up Pizza" (provided)

## Outputs

- `work-packages/loyalty-points.md`
- `docs/adr/0001-loyalty-points-storage.md`
- Updated AGENTS.md with concrete agent configs

## Activity Instructions

1. Configure the Planner agent using the AGENTS.md stub from W2.
2. Run: "Given the feature request [Loyalty Points], produce a work package."
3. Review output; if any AC is missing, update the Planner config (not the prompt) and re-run.
4. Configure the Architect agent and run: "Given the work package, produce an ADR for the storage strategy."
5. The ADR must reference the work package ID.
6. Commit both artifacts. Pod anchor reviews and stamps "LGTM" or leaves one blocker comment.

## Evaluation

| Criterion | Weight | Rubric |
|-----------|--------|--------|
| Work package completeness | 30 pts | 0 = missing fields · 15 = partial · 30 = goal+stories+AC+dependencies present |
| ADR quality | 30 pts | 0 = missing sections · 15 = context only · 30 = all four MADR sections with trade-offs |
| Cross-reference integrity | 20 pts | 0 = no reference · 10 = one-way · 20 = bi-directional IDs |
| Config-not-prompt discipline | 20 pts | 0 = ad-hoc prompting used · 10 = partial · 20 = all iterations via config changes |

**Ranking:** Labs ranked by ADR quality score. Top ADR read aloud at Day 1 wrap-up.

**Significance:** High -- downstream Build and Review agents consume these artifacts directly.

## Exit Criteria

Both files committed; cross-references valid; anchor has reviewed and left a comment.
