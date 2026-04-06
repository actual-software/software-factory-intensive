# L3 · Deploy Designer + Coder Agents

> From spec to running code -- the factory's creative middle stages live

| | |
|---|---|
| **Day** | Day 1 |
| **Time** | 3:45 - 5:00 |
| **Type** | LAB |

## Goal

Instantiate and run the Designer and Coder agents, producing a UI component specification and a working implementation that passes the test cases from the work package.

## Acceptance Criteria

- Designer agent produces a component spec (layout, state, props, interactions) for the Loyalty Points UI.
- Coder agent produces implementation code that references the component spec.
- At least 2 of the work package test cases pass against the generated code.

## Prerequisites

- L2 work package and ADR committed
- Node.js / React environment configured for Fired Up Pizza

## Inputs

- L2 work-package and ADR
- Designer agent config scaffold (provided)
- Coder agent config scaffold (provided)

## Outputs

- `design/loyalty-points-component-spec.md`
- `src/components/LoyaltyPoints.tsx` (or equivalent)
- Test run report

## Activity Instructions

1. Configure Designer agent from scaffold; inputs: work package + ADR.
2. Run: "Produce a component spec for the Loyalty Points display widget."
3. Inspect spec for completeness; iterate via config if incomplete.
4. Configure Coder agent; inputs: component spec + work package test cases.
5. Run: "Implement the LoyaltyPoints component to spec."
6. Run the test suite. Fix failures by updating Coder config (not manual edits). Commit all outputs.

## Evaluation

| Criterion | Weight | Rubric |
|-----------|--------|--------|
| Component spec completeness | 25 pts | 0 = absent · 12 = layout only · 25 = layout+state+props+interactions |
| Code-spec alignment | 30 pts | 0 = no alignment · 15 = partial · 30 = every spec element implemented |
| Test pass rate | 30 pts | 0 = 0 tests pass · 15 = 1 of 2 · 30 = 2+ of 2 |
| Config discipline | 15 pts | 0 = manual code edits · 7 = one manual edit · 15 = zero manual edits |

**Ranking:** Ranked by test pass rate first, then code-spec alignment.

**Significance:** Medium-High -- validates that the front four stages produce shippable artifacts.

## Exit Criteria

Component spec + implementation committed; test run report attached to work package; >= 2 test cases passing.
