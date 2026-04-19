# L2 · Deploy Planner + Architect Agents — Activity

**Walkthrough:** [`../../../curriculum/labs/L2/README.md`](../../../curriculum/labs/L2/README.md)
**Reference examples:**
* [`../../../reference-project/fired-up-pizza/work-packages/loyalty-points-system.md`](../../../reference-project/fired-up-pizza/work-packages/loyalty-points-system.md)
* [`../../../reference-project/fired-up-pizza/docs/adr/0001-loyalty-points-storage.md`](../../../reference-project/fired-up-pizza/docs/adr/0001-loyalty-points-storage.md)

## Deliverables

* One work package file (Planner output) — lands in your project's rig, typically at `<your-project>/work-packages/<slug>.md`
* One ADR file (Architect output) — lands at `<your-project>/docs/adr/NNNN-<slug>.md`
* A short `notes.md` in this folder recording the bead IDs, sling counts, and any pack-prompt edits you made

## Pack wiring

The two packs are already shipped under `../../../packs/planner/` and `../../../packs/architect/`. Two paths forward:

**(a) Use shipped packs as-is** — fastest.

Edit `../../../my-factory/city.toml` and add:

```toml
[workspace]
# ...existing content...
includes = [
    "../packs/planner",
    "../packs/architect",
]
```

Then restart:

```bash
cd ../../../my-factory
gc service restart
gc doctor         # both check-planner and check-architect should pass
```

**(b) Customise** — if the shipped prompts don't match your project's voice.

```bash
mkdir -p packs
cp -r ../../../packs/planner packs/planner
cp -r ../../../packs/architect packs/architect
# edit packs/planner/prompts/planner.md.tmpl and packs/architect/prompts/architect.md.tmpl
```

Then include **your copies** in `../../../my-factory/city.toml`:

```toml
includes = [
    "../activities/labs/L2/packs/planner",
    "../activities/labs/L2/packs/architect",
]
```

## Running the lab

From your project rig:

```bash
bd create --title "Feature: <your feature>" --label needs-plan
gc sling your-project--planner <bead-id>
# ...wait for the Planner to close the bead with label needs-architecture
gc sling your-project--architect <bead-id>
```

## Exit criteria

* [ ] Planner produced a work package file in the rig with at least one user story and acceptance criteria
* [ ] Architect produced an ADR with at least two options considered
* [ ] `../../../my-factory/city.toml` includes the Planner and Architect packs (shipped or customised)
* [ ] Any prompt correction was made by editing the pack file and re-slinging — not by typing a correction into chat

## Skipped this session?

L3 assumes a work package + ADR exist for the feature it implements. If you skip L2, copy the reference work package and ADR into your rig (renamed for your feature) so L3 has inputs to work from.

## Recover from a broken run

* Revert the pack edit: `git checkout activities/labs/L2/packs/`
* Point `../../../my-factory/city.toml` at `../packs/planner` and `../packs/architect` (shipped) instead of your copies
* `gc service restart` — you're back on the known-good shipped packs
