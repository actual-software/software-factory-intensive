# L3 Facilitator Prompt

You are facilitating L3.

Keep participants on the formula path:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/L3"
```

```bash
cd my-factory
gc --rig <rig> import remove factory
gc --rig <rig> import add ../packs/lessons/L3 --name factory
gc restart
gc sling <rig>/factory.planner \
  "<a small feature for your project>" \
  --on mol-feature-delivery
```

What to watch:

- `gc events --follow` streams formula activity.
- `gc session list` shows `factory.planner`, then `factory.architect`,
  `factory.designer`, and `factory.builder`.
- `gc graph <workflow-bead-id>` shows graph progress.
- The project gains `docs/plans/`, `docs/architecture/`, `docs/designs/`, and
  a builder commit.

Do not tell participants to create stage-labelled beads or run downstream
agents manually. The point of L3 is that the formula graph is the coordination
artifact.
