# W3 · Architect Multi-Agent Coordination — Activity

**Walkthrough:** [`../../../curriculum/workshops/W3/README.md`](../../../curriculum/workshops/W3/README.md)

W3 produces a formula graph design note.

## Deliverables

Create:

```text
activities/workshops/W3/formula-design.md
activities/workshops/W3/gates/<gate-name>.md
```

`formula-design.md` should list:

- step IDs
- target agents such as `factory.builder`
- dependency list for each step
- expected inputs
- expected artifact
- close condition
- failure or retry behavior

Gate docs should explain:

- what signal the gate checks
- why a human decision is required
- what PASS means
- what FAIL means
- how the run should continue after the decision

## Reference Examples

- [`../../../packs/lessons/L4/formulas/mol-delivery-review.toml`](../../../packs/lessons/L4/formulas/mol-delivery-review.toml)
- [`../../../packs/lessons/C1/formulas/mol-release-delivery.toml`](../../../packs/lessons/C1/formulas/mol-release-delivery.toml)
- [`../../../reference-project/fired-up-pizza/docs/formula/loyalty-points-graph.yaml`](../../../reference-project/fired-up-pizza/docs/formula/loyalty-points-graph.yaml)

## Exit Criteria

- [ ] `formula-design.md` is present and readable top to bottom.
- [ ] Every step has a target, dependency list, artifact, and close condition.
- [ ] Human gates are justified in `gates/`.
- [ ] The design can be translated directly into a formula `[[steps]]` graph.
- [ ] Decision boundaries are documented in `formula-design.md`.
- [ ] One external trigger is described as an order spec.
