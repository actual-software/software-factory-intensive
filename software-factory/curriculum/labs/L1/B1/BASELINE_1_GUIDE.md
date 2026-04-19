# B1 · Baseline Factory Setup — Activity

**Setup:** [`BASELINE_1_SETUP.md`](BASELINE_1_SETUP.md)

## Deliverables

* A running Gas City factory (`base-gc-factory`) with the `all` composition pack installed
* A registered project rig (`base-project`) wired to the factory
* A successful sling verification proving the factory responds to tasks
* The Gas City dashboard accessible at http://localhost:8080

## Pack wiring

The baseline factory uses a single composition pack — `all` — which bundles all 8 Agent Operations. The pack is shipped under `gascity/step_0/packs/all/` in this activity and is copied into the factory during setup.

The `city.toml` shipped here includes only `packs/actual/all`, giving you the full 8-agent pipeline out of the box.

## Running the baseline

Follow the steps in [`BASELINE_1_SETUP.md`](BASELINE_1_SETUP.md), then verify:

```bash
# From the factory directory
pushd ~/Projects/factory/baseline/base-gc-factory
gc status        # Should show factory running
gc doctor --fix  # All checks should pass

# Verify with a test sling
gc sling base-project/architect "Create a script that prints hello world"
```

## Exit criteria

* [ ] Gas City is installed (`gc version` prints a version)
* [ ] Factory initialized at `~/Projects/factory/baseline/base-gc-factory`
* [ ] Project rig initialized at `~/Projects/factory/baseline/base-project`
* [ ] `gc status` shows the factory running
* [ ] `gc doctor` passes all checks
* [ ] Dashboard is accessible at http://localhost:8080
* [ ] Test sling executes successfully

## Recover from a broken setup

1. Stop the factory: `gc stop`
2. Re-copy the city.toml and packs from this activity:
   ```bash
   cp ~/Projects/actual-software/software-factory-intensive/activities/baseline/B1/gascity/step_0/packs/city.toml ~/Projects/factory/baseline/base-gc-factory/
   rsync -av ~/Projects/actual-software/software-factory-intensive/activities/baseline/B1/gascity/step_0/packs/ ~/Projects/factory/baseline/base-gc-factory/packs/actual/
   ```
3. Re-register and restart:
   ```bash
   gc register ~/Projects/factory/baseline/base-gc-factory
   gc service restart
   gc doctor --fix
   ```
