# Lab L3 · Add Designer + Builder to Software Factory

## Product Driven Factory

### Clone Your Project into Software Factory

```bash
cd ~/Projects/factory/lab_l3
git clone https://github.com/<user>/<project>.git l3-project
```

### Prep Example Project Manifest

```bash
mkdir -p ~/Projects/factory/lab_l3/l3-project/docs/
cp ~/Projects/actual-software/software-factory-intensive/activities/labs/L3/docs/PROJECT_MANIFEST.md ~/Projects/factory/lab_l3/l3-project/docs/
ls -al ~/Projects/factory/lab_l3/l3-project/docs/
```

Author your `PROJECT_MANIFEST.md` for your project. Make example project_manifest.md specific to your project.

* [PROJECT_MANIFEST.md](docs/PROJECT_MANIFEST.md)

#### Stop and Start Gascity

```bash
cd ~/Projects/factory/lab_l3/l3-gc-factory
gc stop
gc start
```

### Send Task to Factory

Create a bead with `needs-plan` label in the rig db. This triggers the `planner-intake`
order gate, which starts the planner automatically.

```bash
cd ~/Projects/factory/lab_l3/l3-gc-factory
gc bd --rig l3-project create \
  --title "" \
  --label needs-plan
```

#### Further Resources

##### Gas City Prompts and Commands

`~/Projects/factory/lab_l3/l3-project/README.md`
