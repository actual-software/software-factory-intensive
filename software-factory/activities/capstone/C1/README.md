# C1 · Run the Software Factory End-to-End — Activity

**Walkthrough:** [`../../../curriculum/capstone/C1/README.md`](../../../curriculum/capstone/C1/README.md)
**Reference examples:**
* [`../../../reference-project/fired-up-pizza/factory-run-report.md`](../../../reference-project/fired-up-pizza/factory-run-report.md)
* [`../../../reference-project/fired-up-pizza/retrospective-card.md`](../../../reference-project/fired-up-pizza/retrospective-card.md)

## Deliverables

Two files in this folder:

* `factory-run-report.md` — structured record of the end-to-end run: feature, pipeline results per stage (sling counts, config changes), timeline, ad-hoc-prompt count (target: zero), feedback-rule triggers, success-criteria check, artifacts produced.
* `retrospective-card.md` — Keep / Change / Question (one short paragraph each) plus a one-line summary for the team.

## Pack wiring

By the start of C1, all six packs should already be included in `../../../my-factory/city.toml` from L2 through L4. Confirm with:

```bash
cd ../../../my-factory
gc doctor
```

All of `check-planner`, `check-architect`, `check-designer`, `check-builder`, `check-reviewer`, and `check-release-gate` should be green.

If any are missing (e.g. you skipped a lab), add the shipped path for that pack before starting the run:

```toml
# my-factory/city.toml — append any missing
includes = [
    "../packs/planner",
    "../packs/architect",
    "../packs/designer",
    "../packs/builder",
    "../packs/reviewer",
    "../packs/release-gate",
]
```

## Running the capstone

1. Pick a new feature from your backlog (not one used during the labs).
2. File the root bead: `bd create --title "Feature: <name>" --label needs-plan`.
3. Sling the Planner and follow the pipeline through to the Release-Gate. Log every sling, every prompt edit, and every ad-hoc chat correction.
4. At the end, draft `factory-run-report.md` using the reference report as the template.
5. Write `retrospective-card.md` — one Keep, one Change, one Question.

## Exit criteria

* [ ] All six pipeline stages produced artifacts in the rig (work package → ADR → design spec → code → review report → release gate)
* [ ] `factory-run-report.md` and `retrospective-card.md` present in this folder
* [ ] Ad-hoc prompt count recorded (target: 0 — every correction via pack-prompt edit)
* [ ] Every prompt edit made during the run is committed alongside the artifact that motivated it

## Skipped sessions upstream?

The run still works — the factory uses whichever packs you wired in, shipped or customised. Call out the skipped sessions explicitly in the run report under "Prior-session deviations" so the retrospective can identify what to revisit.

## Recover from a broken run mid-capstone

* Abandon the feature branch, reset the bead, and re-sling from the stage that failed.
* If a pack edit during the run is the cause, `git checkout` that specific file to its pre-run state and re-sling.
* Record everything in the run report — a capstone that required three resets still teaches more than one that ran cleanly.
