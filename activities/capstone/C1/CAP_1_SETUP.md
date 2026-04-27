# Software Factory Intensive - Lab - C1

## Setup

#### Clone Software Factory Intensive

```bash
mkdir -p ~/Projects/actual-software/
pushd -p ~/Projects/actual-software
git clone https://github.com/actual-software/software-factory-intensive.git
```

## Generate 6-Agent Software Factory

#### Setup Project

In Claude Code session in root of software-factory-intensive

Prompt:
```
/factory-activity-agent install c1
```

#### Uninstall

If needed.

Prompt:
```
/factory-activity-agent delete c1
```

#### Setup Project Manifest

```bash
mkdir -p ~/Projects/factory/lab_c1/c1-project/docs/
cp ~/Projects/actual-software/software-factory-intensive/activities/lab/C1/docs/PROJECT_MANIFEST.md ~/Projects/factory/lab_c1/c1-project/docs/
ls -al ~/Projects/factory/lab_c1/c1-project/docs/
```

#### Stop and Start Gascity

```bash
cd ~/Projects/factory/lab_c1/c1-gc-factory
gc stop
gc start
```

#### Send Task to Factory

Create a bead with `needs-plan` label in the rig db. This triggers the `planner-intake`
order gate, which starts the planner automatically.

```bash
cd ~/Projects/factory/lab_c1/c1-gc-factory
gc bd --rig c1-project create \
  --title "" \
  --label needs-plan
```

#### Further Resources

##### Gas City Prompts and Commands

`~/Projects/factory/lab_c1/c1-project/README.md`

