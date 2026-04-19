# Start Here

## Coding Agent Setup with factory-activity-agent

### For Claude Code

```bash
# Option 1: Symlink into user-level skills (available in all projects)
ln -s "$(pwd)/skills/factory-activity-agent" ~/.claude/skills/factory-activity-agent

# Option 2: Symlink into project-level skills (this project only)
mkdir -p .claude/skills
ln -s "$(pwd)/skills/factory-activity-agent" .claude/skills/factory-activity-agent

# Option 3: Copy into user-level skills
cp -r skills/factory-activity-agent ~/.claude/skills/factory-activity-agent
```

### For Codex

```bash
mkdir -p ~/.codex/skills
cp -r skills/factory-activity-agent ~/.codex/skills/factory-activity-agent
```

## Generate Fired Up Pizza

#### Setup Project W1

In Claude Code session in root of software-factory-intensive

Prompt:
```
/factory-activity-agent install w2
```

#### Uninstall

If needed.

Prompt:
```
/factory-activity-agent delete w2
```

#### Setup Project Manafest

```bash
mkdir -p ~/Projects/factory/workshop_w1/w1-project/docs/
cp ~/Projects/actual-software/software-factory-intensive/activities/workshops/W3/docs/PROJECT_MANIFEST.md ~/Projects/factory/workshop_w1/w1-project/docs/
ls -al ~/Projects/factory/workshop_w1/w1-project/docs/
```

#### Stop and Start Gascity

```bash
cd ~/Projects/factory/workshop_w1/w1-gc-factory
gc stop
gc start
```

#### Send Task to Factory

```bash
gc sling w1-project/planner "Create SPA nextjs for Fired Up Pizza an online pizza ordering application where customers can build custom pizzas, select a pickup or delivery time, and place orders — all within a single-page experience. No payment processing is required; all transactions are handled on-site at pickup/delivery."
```

#### Further Resources

##### Complete Workshop 1 Guide

`~/Projects/factory/workshop_w1/w1-project/WORKSHOP_1_GUIDE.md`

##### Gas City Prompts and Commands

`~/Projects/factory/workshop_w1/w1-project/README.md`
