# Lab L2 · Planner + Architecture Agents

## Product Driven Factory

### Prep Example Project Manifest

```bash
mkdir -p ~/Projects/factory/workshop_l1/l1-project/docs/
cp ~/Projects/actual-software/software-factory-intensive/activities/workshops/L1/docs/PROJECT_MANIFEST.md ~/Projects/factory/workshop_l1/l1-project/docs/
ls -al ~/Projects/factory/workshop_l1/l1-project/docs/
```

Author your `PROJECT_MANIFEST.md` for your project. Make example project_manifest.md specific to your project.

* [PROJECT_MANIFEST.md](docs/PROJECT_MANIFEST.md)

### Send Task to Factory

Create a bead with `needs-plan` label in the rig db. This triggers the `planner-intake`
order gate, which starts the planner automatically.

```bash
cd ~/Projects/factory/workshop_l1/l1-gc-factory
gc bd --rig l1-project create \
  --title "" \
  --label needs-plan
```

#### Further Resources

##### Gas City Prompts and Commands

`~/Projects/factory/workshop_l1/l1-project/README.md`
