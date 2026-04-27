# Fired Up Pizza

Reference project for the Software Factory Intensive. It is a small pizza-ordering app with completed example artifacts from the workshop, labs, and capstone.

The reference project is the input project. The capstone factory that operates on it lives in [`../../packs/lessons/C1`](../../packs/lessons/C1).

## Run It With The Capstone Factory

From the repository root:

```bash
cp my-factory/pack.toml.template my-factory/pack.toml
cp my-factory/city.toml.template my-factory/city.toml
```

Set the active factory to C1:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/C1"
```

Register the city and add this project as the rig:

```bash
cd my-factory
gc register .
gc rig add ../reference-project/fired-up-pizza
gc --rig fired-up-pizza import remove factory
gc --rig fired-up-pizza import add ../packs/lessons/C1 --name factory
gc doctor --fix
```

Start an end-to-end run:

```bash
gc sling planner \
  "Add customer order history: customers can view prior orders by phone number" \
  --on mol-release-delivery
```

Watch progress:

```bash
gc events --follow
gc session list
gc session peek fired-up-pizza/factory.planner
```

## Artifact Layout

```text
fired-up-pizza/
  src/                         # app code
  docs/
    PROJECT_OVERVIEW.md
    PROJECT_MANIFEST.md
    factory-wiring.md
    formula/                   # W3 graph design notes
    plans/                     # Planner artifacts
    architecture/              # Architect artifacts
    designs/                   # Designer artifacts
    validation/                # Validator artifacts, when present
    reviews/                   # Reviewer artifacts
    releases/                  # Release-gate artifacts
    feedback/                  # Improvement signals
  feedback-loops/              # W4 rule proposals
  factory-run-report.md        # C1 run record
  retrospective-card.md        # C1 retrospective
  CLAUDE.md
  DECISIONS.md
```

## Reference Deliverables

| Session | Deliverable | Example |
|---|---|---|
| W1 | Workflow card | [`workflow-card.md`](workflow-card.md) |
| L1 | Project instructions and decision log | [`CLAUDE.md`](CLAUDE.md), [`DECISIONS.md`](DECISIONS.md) |
| W2 | Factory map | [`docs/factory-wiring.md`](docs/factory-wiring.md) |
| L2 | Plan and architecture | [`docs/plans/loyalty-points-system.md`](docs/plans/loyalty-points-system.md), [`docs/architecture/loyalty-points-storage.md`](docs/architecture/loyalty-points-storage.md) |
| L3 | Design and implementation | [`docs/designs/loyalty-points-spec.md`](docs/designs/loyalty-points-spec.md), [`src/main.tsx`](src/main.tsx) |
| W3 | Formula design | [`docs/formula/loyalty-points-graph.yaml`](docs/formula/loyalty-points-graph.yaml) |
| L4 | Review and release gate | [`docs/reviews/loyalty-points-review.md`](docs/reviews/loyalty-points-review.md), [`docs/releases/loyalty-points-gate.md`](docs/releases/loyalty-points-gate.md) |
| W4 | Feedback-loop rules | [`feedback-loops/`](feedback-loops/) |
| C1 | Run report and retrospective | [`factory-run-report.md`](factory-run-report.md), [`retrospective-card.md`](retrospective-card.md) |

## Formula Pipeline

The C1 lesson pack routes the capstone run through:

```text
Planner -> Architect -> Designer -> Builder -> Validator -> Reviewer -> Release Gate
```

The formula graph lives at [`../../packs/lessons/C1/formulas/mol-release-delivery.toml`](../../packs/lessons/C1/formulas/mol-release-delivery.toml).
