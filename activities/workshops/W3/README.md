# W3 · Architect Multi-Agent Coordination — Activity

**Walkthrough:** [`../../../curriculum/workshops/W3/README.md`](../../../curriculum/workshops/W3/README.md)
**Reference examples:**
* [`../../../reference-project/fired-up-pizza/orchestrator.yaml`](../../../reference-project/fired-up-pizza/orchestrator.yaml)
* [`../../../reference-project/fired-up-pizza/docs/gates/approve_deploy.md`](../../../reference-project/fired-up-pizza/docs/gates/approve_deploy.md)

## Deliverables

Two files in this folder:

* `orchestrator.yaml` — a 6-stage pipeline definition covering Planner → Architect → Designer → Builder → Reviewer → Release-Gate, including any human gates and per-stage `on_reject` behaviour.
* `gates/approve_deploy.md` (or similar) — a short justification doc for each human gate you introduce. Name the gate, the signal it checks, and the escalation path.

The shipped packs use **label-based handoff** (`needs-architecture`, `needs-plan`, `needs-design`, `ready-to-build`, `needs-review`, `ready-to-ship`). Your orchestrator file should either reflect those labels or describe how your customisations override them.

## Workspace wiring

W3 is a design session — no new packs are installed and `../../../my-factory/city.toml` is not changed. L4 is where the Reviewer and Release-Gate packs get wired in, at which point this orchestrator becomes load-bearing.

## Exit criteria

* [ ] `orchestrator.yaml` present, 6 stages, each referencing a specific pack label and a specific artifact path.
* [ ] Every human gate introduced has a corresponding `.md` doc in `gates/` justifying its existence.
* [ ] The orchestrator can be read top-to-bottom without needing to open a pack file — it's self-describing.

## Skipped this session?

L4 and C1 both assume an orchestrator exists. If you skip W3, you can drive the pipeline manually (`gc sling <agent> <bead-id>` for each stage) — note this explicitly in the C1 run report under "Config Discipline".
