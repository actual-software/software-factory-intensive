# L3 · Deploy Designer + Coder Agents — Activity

**Walkthrough:** [`../../../curriculum/labs/L3/README.md`](../../../curriculum/labs/L3/README.md)
**Reference example:** [`../../../reference-project/fired-up-pizza/design/loyalty-points-spec.md`](../../../reference-project/fired-up-pizza/design/loyalty-points-spec.md)

## Deliverables

* One design spec (Designer output) — lands in your rig at `<your-project>/design/<slug>-spec.md`
* Implementation commits (Coder output) — new files under your rig's `src/`, on a feature branch
* A `notes.md` in this folder: bead IDs, sling counts, and any prompt edits that moved the Coder from failing → passing

## Pack wiring

Packs live at `../../../packs/designer/` and `../../../packs/coder/`.

**(a) Use shipped packs as-is:**

```toml
# my-factory/city.toml
includes = [
    "../packs/planner",        # from L2
    "../packs/architect",      # from L2
    "../packs/designer",
    "../packs/coder",
]
```

**(b) Customise:**

```bash
mkdir -p packs
cp -r ../../../packs/designer packs/designer
cp -r ../../../packs/coder packs/coder
```

Then include `../activities/labs/L3/packs/designer` and `../activities/labs/L3/packs/coder` in `../../../my-factory/city.toml` in place of (or in addition to) the shipped paths.

Restart:

```bash
cd ../../../my-factory
gc service restart
gc doctor
```

## Running the lab

From your project rig:

```bash
bd create --title "Design: <feature>" --label needs-design --depends-on <L2-architect-bead>
gc sling your-project--designer <bead-id>
# ...wait, then hand off to the coder
bd create --title "Build: <feature>" --label ready-to-build --depends-on <designer-bead>
gc sling your-project--coder <bead-id>
```

## Exit criteria

* [ ] Design spec written with Props / Interactions / Edge Cases / Test Plan sections
* [ ] Coder committed working code to a feature branch; `npm test` (or your test runner) passes
* [ ] Zero manual code edits — every Coder correction was a prompt edit to `packs/coder/prompts/coder.md.tmpl` (shipped or your copy) followed by a re-sling
* [ ] `../../../my-factory/city.toml` now includes Designer + Coder alongside Planner + Architect

## Skipped this session?

L4 (review) runs on committed code from some feature branch. If you skipped L3, either copy the reference project's feature branch verbatim into your rig, or reduce L4 to reviewing a trivial hand-written commit — note the deviation in L5's run report.

## Recover from a broken run

* Revert: `git checkout activities/labs/L3/packs/`
* Swap `../activities/labs/L3/packs/designer` / `coder` in `city.toml` back to `../packs/designer` / `../packs/coder`
* `gc service restart` — the shipped packs always pass their doctor checks
