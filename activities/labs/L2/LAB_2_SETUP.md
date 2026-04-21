# Software Factory Intensive - Lab - L2

## Setup

#### Clone Software Factory Intensive

```bash
mkdir -p ~/Projects/actual-software/
pushd -p ~/Projects/actual-software
git clone https://github.com/actual-software/software-factory-intensive.git
```

## Generate Fired Up Pizza

#### Setup Project

In Claude Code session in root of software-factory-intensive

Prompt:
```
/factory-activity-agent install l2
```

#### Uninstall

If needed.

Prompt:
```
/factory-activity-agent delete l2
```

#### Setup Project Manifest

```bash
mkdir -p ~/Projects/factory/lab_l2/l2-project/docs/
cp ~/Projects/actual-software/software-factory-intensive/activities/lab/L2/docs/PROJECT_MANIFEST.md ~/Projects/factory/lab_l2/l2-project/docs/
ls -al ~/Projects/factory/lab_l2/l2-project/docs/
```

#### Stop and Start Gascity

```bash
cd ~/Projects/factory/lab_l2/l2-gc-factory
gc stop
gc start
```

#### Send Task to Factory

Create a bead with `needs-plan` label in the rig db. This triggers the `planner-intake`
order gate, which starts the planner automatically.

```bash
cd ~/Projects/factory/lab_l2/l2-gc-factory
gc bd --rig l2-project create \
  --title "" \
  --label needs-plan
```

#### Further Resources

##### Gas City Prompts and Commands

`~/Projects/factory/lab_l2/l2-project/README.md`

