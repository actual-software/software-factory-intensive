# L4 Activity Checkpoint

**Walkthrough:** [`../../../curriculum/labs/L4/README.md`](../../../curriculum/labs/L4/README.md)

L4 switches the active factory pack to `packs/lessons/L4`, then runs one
formula graph through Planner, Architect, Designer, Builder, Reviewer, and
Release Gate.

Factory selection in `my-factory/pack.toml`:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/L4"
```

Sync the existing project rig:

```bash
cd my-factory
gc --rig <rig> import remove factory
gc --rig <rig> import add ../packs/lessons/L4 --name factory
gc restart
```

Start the run:

```bash
gc sling planner \
  "Add a clamp operation: clamp(x, lo, hi) returns x bounded to [lo, hi]" \
  --on mol-delivery-review
```

Expected project outputs:

- `docs/plans/<slug>.md`
- `docs/architecture/<slug>.md`
- `docs/designs/<slug>.md`
- one implementation commit with passing tests
- `docs/reviews/<slug>.md`
- `docs/releases/<slug>.md`
