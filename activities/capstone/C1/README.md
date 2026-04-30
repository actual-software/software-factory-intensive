# C1 Activity Checkpoint

**Walkthrough:** [`../../../curriculum/capstone/C1/README.md`](../../../curriculum/capstone/C1/README.md)

C1 switches the active factory pack to `packs/lessons/C1`, then runs the full
release-delivery formula graph.

Factory selection in `my-factory/pack.toml`:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/C1"
```

Sync the existing project rig:

```bash
cd my-factory
gc --rig <rig> import remove factory
gc --rig <rig> import add ../packs/lessons/C1 --name factory
gc restart
```

Start the run:

```bash
gc sling <rig>/factory.planner \
  "<an unfamiliar feature request from your real backlog>" \
  --on mol-release-delivery
```

Expected project outputs:

- `docs/plans/<slug>.md`
- `docs/architecture/<slug>.md`
- `docs/designs/<slug>.md`
- one implementation commit with passing tests
- `docs/validation/<slug>.md`
- `docs/reviews/<slug>.md`
- `docs/releases/<slug>.md`
- `activities/capstone/C1/retrospective.md` — factory run retrospective with W4 criteria evaluation

## Exit Criteria

- [ ] The run started with one `gc sling` on `mol-release-delivery`.
- [ ] The formula routed all seven roles.
- [ ] The release gate includes an explicit verdict backed by validation and review evidence.
- [ ] Retrospective exists with at least one W4 criterion evaluated.
- [ ] At least one config change is documented with file and reason.
