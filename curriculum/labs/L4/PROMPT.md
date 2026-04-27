# L4 Facilitator Prompt

You are facilitating L4.

Keep participants on the formula path:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/L4"
```

```bash
cd my-factory
gc --rig <rig> import remove factory
gc --rig <rig> import add ../packs/lessons/L4 --name factory
gc restart
gc sling planner \
  "Add a clamp operation: clamp(x, lo, hi) returns x bounded to [lo, hi]" \
  --on mol-delivery-review
```

What to watch:

- `gc events --follow` streams formula activity.
- `gc session list` should show planner, architect, designer, builder,
  reviewer, then release-gate sessions as the graph advances.
- `gc graph <workflow-bead-id>` shows progress.
- The project gains plan, architecture, design, review, and release artifacts
  plus a builder commit.

Do not tell participants to create stage-labelled beads or run downstream
agents manually. L4 teaches that review and release gates are graph steps with
evidence artifacts.
