# Workshop W1 · Intro the 6-Agent Software Factory

## Intro To Agents

## Product Driven Factory

* [PROJECT_MANIFEST.md](docs/PROJECT_MANIFEST.md)


## Setup Project Manifest

```bash
mkdir -p ~/Projects/factory/workshop_w1/w1-project/docs/
cp ~/Projects/actual-software/software-factory-intensive/activities/workshops/W1/docs/PROJECT_MANIFEST.md ~/Projects/factory/workshop_w1/w1-project/docs/
ls -al ~/Projects/factory/workshop_w1/w1-project/docs/
```

## Stop and Start Gascity

```bash
cd ~/Projects/factory/workshop_w1/w1-gc-factory
gc stop
gc start
```

## Send Task to Factory

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
