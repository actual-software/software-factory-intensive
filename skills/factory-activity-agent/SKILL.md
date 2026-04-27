---
name: factory-activity-agent
description: >-
  Install, delete, and operate Gas City factory setups for Software Factory
  Intensive curriculum activities (W1-W4, L1-L4, C1). Wraps
  factory_activity_agent.py for lifecycle management and provides gc CLI
  v0.14.1 operational guidance for status, sling, sessions, formulas,
  dashboard, and troubleshooting. Use when setting up or tearing down
  activity environments, checking factory status, routing work to agents,
  or diagnosing gc issues.
argument-hint: "[install|delete|status|doctor|sling|dashboard|list] [activity]"
---

# factory-activity-agent

Manage Gas City factory environments for the Software Factory Intensive curriculum.

## Commands

| Verb | Purpose | Usage |
|------|---------|-------|
| `install` | Install a factory for an activity | `install W2` or `install L3 --dry-run` |
| `delete` | Remove a factory and all its directories | `delete W2` |
| `status` | Check running factories and agent states | `status` |
| `doctor` | Run gc diagnostics and auto-fix | `doctor` |
| `sling` | Route work to an agent in a factory | `sling W2 architect "Design the API"` |
| `dashboard` | Start the gc web dashboard | `dashboard` |
| `session` | Manage gc agent sessions | `session list` / `session new` |
| `formula` | List, show, or cook formulas | `formula list` |
| `list` | Show available activities and install status | `list` |

### install

Pre-flight checks, then calls the Python installer. **Always run from the SFI repo root:**

```bash
bash skills/factory-activity-agent/scripts/install.sh <activity> [--dry-run]
```

Or directly (must be in the SFI repo root):
```bash
python3 scripts/factory_activity_agent.py install <activity> [--mode dry-run]
```

Activities: `W1`, `W2`, `W3`, `W4`, `L1`, `L2`, `L3`, `L4`, `C1`, `B1`

### delete

Stops the factory, unregisters it, and removes all directories. **Always run from the SFI repo root:**

```bash
bash skills/factory-activity-agent/scripts/delete.sh <activity> [--dry-run]
```

Or directly (must be in the SFI repo root):
```bash
python3 scripts/factory_activity_agent.py delete <activity> [--mode dry-run]
```

### status

Show all registered cities and their agent status:

```bash
bash skills/factory-activity-agent/scripts/status.sh
```

### doctor

Run gc diagnostics with auto-fix:

```bash
bash skills/factory-activity-agent/scripts/doctor.sh
```

### sling

Route work to an agent. Requires being in or specifying a factory directory:

```bash
cd ~/Projects/factory/<slug>/<alias>-project
gc sling <alias>-project/<agent> "<prompt>"
```

Example:
```bash
cd ~/Projects/factory/workshop_w2/w2-project
gc sling w2-project/architect "Create a script that prints hello world"
```

### dashboard

Start the web dashboard (serves on http://localhost:8080):

```bash
gc dashboard serve --city ~/Projects/factory/<slug>/<alias>-gc-factory
```

### list

Show all activities and whether they are currently installed:

```bash
bash skills/factory-activity-agent/scripts/status.sh --list
```

## Installation

### Prerequisites

- **gc** CLI v0.14.1 — `brew install gastownhall/gascity/gascity` or pinned:
  ```bash
  brew tap-new $USER/local
  brew extract --version=0.14.1 gastownhall/gascity/gascity $USER/local
  brew install gascity@0.14.1
  ```
- **Python 3.8+** — `python3 --version`
- **bd** (beads) CLI — installed with gc or standalone
- **software-factory-intensive** repo cloned locally

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

### For Gas City pack integration

Ship inside a pack overlay so agents get the skill automatically:

```bash
cp -r skills/factory-activity-agent packs/<pack>/overlays/default/.claude/skills/factory-activity-agent
```

### Verify

After installing, the skill should appear in Claude Code's skill list. Test with:
```
/factory-activity-agent list
```

## Activity Map

| Activity | Category | Slug | Project Dir | Factory Dir |
|----------|----------|------|-------------|-------------|
| W1 | workshops | `workshop_w1` | `~/Projects/factory/workshop_w1/w1-project` | `~/Projects/factory/workshop_w1/w1-gc-factory` |
| W2 | workshops | `workshop_w2` | `~/Projects/factory/workshop_w2/w2-project` | `~/Projects/factory/workshop_w2/w2-gc-factory` |
| W3 | workshops | `workshop_w3` | `~/Projects/factory/workshop_w3/w3-project` | `~/Projects/factory/workshop_w3/w3-gc-factory` |
| W4 | workshops | `workshop_w4` | `~/Projects/factory/workshop_w4/w4-project` | `~/Projects/factory/workshop_w4/w4-gc-factory` |
| L1 | labs | `lab_l1` | `~/Projects/factory/lab_l1/l1-project` | `~/Projects/factory/lab_l1/l1-gc-factory` |
| L2 | labs | `lab_l2` | `~/Projects/factory/lab_l2/l2-project` | `~/Projects/factory/lab_l2/l2-gc-factory` |
| L3 | labs | `lab_l3` | `~/Projects/factory/lab_l3/l3-project` | `~/Projects/factory/lab_l3/l3-gc-factory` |
| L4 | labs | `lab_l4` | `~/Projects/factory/lab_l4/l4-project` | `~/Projects/factory/lab_l4/l4-gc-factory` |
| C1 | capstone | `capstone_c1` | `~/Projects/factory/capstone_c1/c1-project` | `~/Projects/factory/capstone_c1/c1-gc-factory` |
| B1 | baseline | `baseline_b1` | `~/Projects/factory/baseline_b1/b1-project` | `~/Projects/factory/baseline_b1/b1-gc-factory` |

Pack sources for each activity: `activities/<category>/<activity>/gascity/step_0/packs/`

## Directory Structure

What `install` creates under `~/Projects/factory/`:

```
~/Projects/factory/
└── workshop_w2/                        # slug directory
    ├── w2-project/                     # git-initialized project repo (rig)
    └── w2-gc-factory/                  # Gas City factory workspace
        ├── city.toml                   # Configured: workspace name, rig path, pack includes
        └── packs/actual/              # Synced from activities/workshops/W2/gascity/step_0/packs/
            ├── city.toml              # Template (source)
            ├── planner/
            ├── architect/
            ├── designer/
            ├── builder/
            ├── reviewer/
            ├── release-gate/
            ├── validator/
            ├── improver/
            └── all/                   # Composition pack
```

## Workflow: Install an Activity

1. **Pre-flight** — verify `gc` and `python3` are on PATH
2. **Dry-run** — preview what will happen:
   ```bash
   python3 scripts/factory_activity_agent.py install W2 --mode dry-run
   ```
3. **Confirm** — review the dry-run output with the user
4. **Execute** — run the install:
   ```bash
   python3 scripts/factory_activity_agent.py install W2
   ```
5. **Verify** — check the factory is running and the setup task was slung:
   ```bash
   gc status --city ~/Projects/factory/workshop_w2/w2-gc-factory
   ```
   The install automatically slings a setup task to the architect agent to create `.gitignore` and `README.md`.

Dashboard available at http://localhost:8080 after install.

## Workflow: Delete an Activity

1. **Pre-flight** — confirm with user (this removes all files)
2. **Execute**:
   ```bash
   python3 scripts/factory_activity_agent.py delete W2
   ```
3. **Verify** — confirm directories are removed and factory is unregistered:
   ```bash
   gc cities
   ls ~/Projects/factory/workshop_w2 2>/dev/null || echo "Removed"
   ```

## Workflow: Check Status

```bash
# List all registered factories
gc cities

# Check status of a specific factory
gc status --city ~/Projects/factory/workshop_w2/w2-gc-factory

# Check all factories at once
bash skills/factory-activity-agent/scripts/status.sh
```

## gc CLI Quick Reference (v0.14.1)

### Lifecycle

| Command | Purpose |
|---------|---------|
| `gc init <dir>` | Initialize a new factory workspace |
| `gc register <dir>` | Register factory with the supervisor |
| `gc unregister <dir>` | Unregister a factory |
| `gc start` | Start all agents in the factory |
| `gc stop` | Stop all agents |
| `gc restart` | Restart all agents |
| `gc resume` | Resume a suspended factory |
| `gc suspend` | Suspend the factory |

### Operations

| Command | Purpose |
|---------|---------|
| `gc status` | Show factory and agent status |
| `gc sling <rig/agent> "<prompt>"` | Route work to a specific agent |
| `gc doctor [--fix]` | Diagnose and optionally fix issues |
| `gc dashboard serve` | Start web dashboard (port 8080) |
| `gc rig add <path>` | Add a project as a rig |
| `gc config` | Inspect and validate city configuration |
| `gc cities` | List all registered factories |
| `gc events` | Show the event log |
| `gc prime <agent>` | Output the behavioral prompt for an agent |

### Sessions & Formulas

| Command | Purpose |
|---------|---------|
| `gc session new` | Start a new agent session |
| `gc session attach <id>` | Attach to a running session |
| `gc session list` | List all sessions |
| `gc session suspend` | Suspend a session |
| `gc session nudge <id> "<msg>"` | Send a message to a running session |
| `gc formula list` | List available formulas |
| `gc formula show <name>` | Show formula details |
| `gc formula cook <name>` | Execute a formula |

### Advanced

| Command | Purpose |
|---------|---------|
| `gc order list` | List available orders |
| `gc order check` | Check which orders are due |
| `gc order run <name>` | Execute an order manually |
| `gc convoy` | Manage convoys (graphs of related work) |
| `gc converge create` | Create a convergence loop |
| `gc mail` | Send/receive messages between agents |
| `gc service restart` | Restart the gc supervisor service |
| `gc version` | Print gc version (expect v0.14.1) |

## gc Version Pin

This curriculum is pinned to **gc v0.14.1**. Check your version:

```bash
gc version
```

If your version differs, install the pinned version:
```bash
brew tap-new $USER/local
brew extract --version=0.14.1 gastownhall/gascity/gascity $USER/local
brew install gascity@0.14.1
```

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `gc: command not found` | gc not installed or not on PATH | `brew install gastownhall/gascity/gascity` |
| `Error: Activity X has no gascity packs` | Packs not created for this activity yet | Check `activities/<category>/<activity>/gascity/step_0/packs/` exists |
| `No city.toml template` | Missing template in activity packs | Verify the activity has a `city.toml` in its packs dir |
| `gc doctor` shows failures | Missing dependencies or misconfig | Run `gc doctor --fix` |
| Dashboard won't start | Port 8080 already in use | `lsof -i :8080` to find the process, kill it, retry |
| Factory won't start | city.toml misconfigured | Check `gc config`, verify workspace name and rig path |
| `gc sling` hangs or errors | Agent not authenticated or not running | `gc status` to check agent state, `gc doctor` for auth |
| Delete fails "not registered" | Factory already unregistered | Safe to ignore; directory cleanup still proceeds |
| `gc bd config set` fails | `bd` (beads) not installed | Verify `which bd`; install via gc or standalone |
| Python script fails | Python 3 not available | Install Python 3.8+ |
| Multiple dashboards conflict | Only one can bind port 8080 | Stop other dashboards before starting a new one |

## Diagnostics

Run a full environment check:

```bash
bash skills/factory-activity-agent/scripts/diagnose.sh
```

Checks: gc binary + version, python3, bd, registered cities, factory directories, agent authentication.

## Reference Files

Load these for deeper detail on specific topics:

| File | When to load |
|------|-------------|
| [`references/gc-command-reference.md`](references/gc-command-reference.md) | Need full gc command details with all flags and examples |
| [`references/activity-catalog.md`](references/activity-catalog.md) | Need activity descriptions, curriculum context, or pack contents |
