# W3 Facilitation Prompt

Use this prompt if you want a local agent to draft the W3 formula design note.

```text
You are helping me design a formula graph for a small software factory.

Read:
- activities/workshops/W2/factory-map.md
- packs/lessons/L4/formulas/mol-delivery-review.toml
- packs/lessons/C1/formulas/mol-release-delivery.toml
- reference-project/fired-up-pizza/docs/formula/loyalty-points-graph.yaml

Create activities/workshops/W3/formula-design.md.

For each step include:
- id
- target such as factory.planner
- needs dependencies
- expected inputs
- expected artifact
- close condition
- failure behavior

Also create any needed activities/workshops/W3/gates/*.md files explaining human gates. Keep the graph as small as possible while still representing real project risk.
```
