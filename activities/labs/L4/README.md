# L4 Activity Checkpoint

**Walkthrough:** [`../../../curriculum/labs/L4/README.md`](../../../curriculum/labs/L4/README.md)

L4 switches the active factory pack to `packs/lessons/L4`, then runs one
formula graph through Planner, Architect, Designer, Builder, Reviewer, and
Release Gate.

Factory selection in `my-factory/city.toml`:

```toml
[[rigs]]
name = "<rig>"  # your rig: the basename gc rig add derives (see: gc rig list)
[rigs.imports.factory]
source = "../packs/lessons/L4"
```

Apply the change after editing the city-wide factory selection:

```bash
cd my-factory
gc restart
```

Start the run:

```bash
gc sling <rig>/factory.planner \
  "<a small feature for your project>" \
  --on mol-delivery-review
```

Expected project outputs:

- `docs/plans/<slug>.md`
- `docs/architecture/<slug>.md`
- `docs/designs/<slug>.md`
- one implementation commit with passing tests
- `docs/reviews/<slug>.md`
- `docs/releases/<slug>.md`
