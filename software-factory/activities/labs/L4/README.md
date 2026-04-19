# L4 · Deploy Reviewer + Release-Gate Agents — Activity

**Walkthrough:** [`../../../curriculum/labs/L4/README.md`](../../../curriculum/labs/L4/README.md)
**Reference examples:**
* [`../../../reference-project/fired-up-pizza/review-reports/loyalty-points-review.md`](../../../reference-project/fired-up-pizza/review-reports/loyalty-points-review.md)
* [`../../../reference-project/fired-up-pizza/release-gates/loyalty-points-gate.md`](../../../reference-project/fired-up-pizza/release-gates/loyalty-points-gate.md)

## Deliverables

* One review report (Reviewer output) — lands in your rig at `<your-project>/review-reports/<slug>-review.md`
* One release gate (Release-Gate output) — lands at `<your-project>/release-gates/<slug>-gate.md`
* A `notes.md` in this folder: at least one reviewer finding that you resolved by editing the Builder's pack prompt (not by hand-editing code)

**Naming note:** the curriculum calls this role *Deployer*. The shipped pack is named `release-gate` — same role, same output. Every `packs/deployer` reference in older curriculum material should be read as `packs/release-gate`.

## Pack wiring

Packs live at `../../../packs/reviewer/` and `../../../packs/release-gate/`.

**(a) Use shipped packs as-is:**

```toml
# my-factory/city.toml
includes = [
    "../packs/planner",          # from L2
    "../packs/architect",        # from L2
    "../packs/designer",         # from L3
    "../packs/builder",          # from L3
    "../packs/reviewer",
    "../packs/release-gate",
]
```

**(b) Customise:**

```bash
mkdir -p packs
cp -r ../../../packs/reviewer packs/reviewer
cp -r ../../../packs/release-gate packs/release-gate
```

Replace the shipped paths with `../activities/labs/L4/packs/reviewer` and `../activities/labs/L4/packs/release-gate` in `../../../my-factory/city.toml`.

Restart:

```bash
cd ../../../my-factory
gc service restart
gc doctor      # should be green for all six agents
```

## Running the lab

From your project rig:

```bash
bd create --title "Review: <feature>" --label needs-review --depends-on <L3-builder-bead>
gc sling your-project--reviewer <bead-id>
# ...address findings via Builder prompt edits, then
bd create --title "Ship: <feature>" --label ready-to-ship --depends-on <reviewer-bead>
gc sling your-project--release-gate <bead-id>
```

## Exit criteria

* [ ] Review report produced with findings at Low/Medium/High severity
* [ ] At least one finding was resolved by editing `packs/builder/prompts/builder.md.tmpl` (shipped or your copy) and re-slinging — no hand-edits to code in response to reviewer findings
* [ ] Release gate emitted with a clear PASS / FAIL verdict plus evidence per required check
* [ ] `../../../my-factory/city.toml` has all six packs included

## Skipped this session?

C1 assumes all six agents are running. If you skip L4, add `../packs/reviewer` and `../packs/release-gate` (shipped) to `../../../my-factory/city.toml` directly — the capstone still runs, just without your review-standards customisations.

## Recover from a broken run

* Revert: `git checkout activities/labs/L4/packs/`
* Swap in the shipped paths `../packs/reviewer` and `../packs/release-gate` in `city.toml`
* `gc service restart && gc doctor`
