# Start Here

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
