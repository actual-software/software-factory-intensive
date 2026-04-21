# Software Factory Intensive - Workshop - W2

https://github.com/actual-software/software-factory-intensive

## Setup

#### Clone Software Factory Intensive

```bash
mkdir -p ~/Projects/actual-software/
pushd -p ~/Projects/actual-software
git clone https://github.com/actual-software/software-factory-intensive.git
```

## Generate Fired Up Pizza

#### Setup Project W1

In Claude Code session in root of software-factory-intensive

Prompt:
```
/factory-activity-agent install w1
```

#### Uninstall

If needed.

Prompt:
```
/factory-activity-agent delete w1
```

#### Setup Project Manifest

```bash
mkdir -p ~/Projects/factory/workshop_w1/w1-project/docs/
cp ~/Projects/actual-software/software-factory-intensive/activities/workshops/W1/docs/PROJECT_MANIFEST.md ~/Projects/factory/workshop_w1/w1-project/docs/
ls -al ~/Projects/factory/workshop_w1/w1-project/docs/
```

#### Stop and Start Gascity

```bash
cd ~/Projects/factory/workshop_w1/w1-gc-factory
gc stop
gc start
```

#### Send Task to Factory

Create a bead with `needs-plan` label in the rig db. This triggers the `planner-intake`
order gate, which starts the planner automatically.

```bash
cd ~/Projects/factory/workshop_w1/w1-gc-factory
gc bd --rig w1-project create \
  --title "Create SPA nextjs for Fired Up Pizza an online pizza ordering application where customers can build custom pizzas, select a pickup or delivery time, and place orders — all within a single-page experience. No payment processing is required; all transactions are handled on-site at pickup/delivery." \
  --label needs-plan
```

#### Further Resources

##### Complete Workshop 1 Guide

`~/Projects/factory/workshop_w1/w1-project/WORKSHOP_1_GUIDE.md`

##### Gas City Prompts and Commands

`~/Projects/factory/workshop_w1/w1-project/README.md`

