# L3 Activity Checkpoint

**Walkthrough:** [`../../../curriculum/labs/L3/README.md`](../../../curriculum/labs/L3/README.md)

L3 switches the active factory pack to `packs/lessons/L3`, then runs one
formula graph through Planner, Architect, Designer, and Builder.

Factory selection in `my-factory/pack.toml`:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/L3"
```

Sync the existing project rig after changing the city-wide factory selection:

```bash
cd my-factory
gc --rig <rig> import remove factory
gc --rig <rig> import add ../packs/lessons/L3 --name factory
gc restart
```

Start the run:

```bash
gc sling <rig>/factory.planner \
  "<a small feature for your project>" \
  --on mol-feature-delivery
```

Expected project outputs:

- `docs/plans/<slug>.md`
- `docs/architecture/<slug>.md`
- `docs/designs/<slug>.md`
- one implementation commit with passing tests
