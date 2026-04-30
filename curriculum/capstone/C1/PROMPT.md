# C1 Facilitator Prompt

You are facilitating C1.

Keep participants on the formula path:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/C1"
```

```bash
cd my-factory
gc --rig <rig> import remove factory
gc --rig <rig> import add ../packs/lessons/C1 --name factory
gc restart
gc sling <rig>/factory.planner \
  "<an unfamiliar feature request from the participant's real backlog>" \
  --on mol-release-delivery
```

What to watch:

- `gc events --follow` streams formula activity.
- `gc session list` should show planner, architect, designer, builder,
  validator, reviewer, then release-gate sessions as the graph advances.
- `gc graph <workflow-bead-id>` shows progress.
- The project gains plan, architecture, design, validation, review, and release
  artifacts plus a builder commit.

Do not tell participants to create stage-labelled beads or run downstream
agents manually. C1 proves that the whole factory can be represented as one
formula-routed graph.
