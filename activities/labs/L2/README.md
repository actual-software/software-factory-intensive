# L2 - Planner + Architect Activity

**Walkthrough:** [`../../../curriculum/labs/L2/README.md`](../../../curriculum/labs/L2/README.md)

## Goal

Run the first real lesson factory: a self-contained L2 pack with a Planner and
Architect connected by one formula graph.

## Deliverables

- A planning artifact in your project rig at `docs/plans/<slug>.md`
- An architecture artifact in your project rig at `docs/architecture/<slug>.md`
- `notes.md` in this activity folder with the root bead ID, artifact paths, and
  any prompt/config changes you made

## Select The L2 Factory Pack

In `../../../my-factory/city.toml`, set the active factory import:

```toml
[[rigs]]
name = "<rig>"  # your rig: the basename gc rig add derives (see: gc rig list)
[rigs.imports.factory]
source = "../packs/lessons/L2"
```

The imported agents remain rig-scoped. With the binding named `factory`, the
Planner target is `<rig>/factory.planner`.

If you used the default `city.toml` in L1, the import already points at L2 — you can skip ahead. To switch the active lesson, point `[rigs.imports.factory].source` at the lesson you want, then apply it:

```bash
cd ../../../my-factory
gc restart
```

## Run The Lesson

```bash
cd ../../../my-factory
gc restart
gc doctor
gc sling <rig>/factory.planner "<a small feature for your project>" --on mol-feature-intake
gc events --follow
```

After the formula starts, inspect the graph and artifacts:

```bash
gc graph <root-bead-id>
bd show <root-bead-id>
ls <your-project>/docs/plans
ls <your-project>/docs/architecture
```

## Exit Criteria

- The formula graph has `plan` and `architecture` steps.
- `plan` routes to `factory.planner`.
- `architecture` depends on `plan` and routes to `factory.architect`.
- The plan includes user stories and acceptance criteria.
- The architecture file includes at least two options and a decision.
- Your notes record the root bead ID and generated artifact paths.

## Skipped This Session?

L3 expects planning and architecture context in the same project rig. If you
skip L2, add equivalent files under `docs/plans/` and `docs/architecture/`
before starting L3.
